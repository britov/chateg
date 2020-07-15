import 'dart:async';
import 'dart:convert';

import 'package:chateg/sharad_pref.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

class UserModel with ChangeNotifier {

  final _sharedPrefUtil = SharedPrefUtil();

  String _name;
  String _serverName;

  String get name => _name;
  set name(String name) {
    _name = name.trim();
    _sharedPrefUtil.setMyName(_name);
    notifyListeners();
  }

  String get serverName => _serverName;
  set serverName(String serverName) {
    _serverName = serverName;
    _name = null;
    _sharedPrefUtil.setMyServer(serverName);
    notifyListeners();
  }



  Future<UserModel> init() async {
    await _sharedPrefUtil.init();
    _name = _sharedPrefUtil.getMyName();
    _serverName = _sharedPrefUtil.getMyServer();
    return this;
  }
}

class MessagesModel with ChangeNotifier {

  static Future<bool> tryInitConnection(String serverName) async {
    final channel = IOWebSocketChannel.connect("ws://$serverName/ws?name=test123");
    await channel.stream.first.timeout(Duration(seconds: 10));
    channel.sink.close(status.goingAway);
    return true;
  }

  int wsConnectionErrorAttempt = 0;

  MessagesModel({
    @required this.name,
    @required this.serverName
  }) {

    _connectivitySubscription = Connectivity().onConnectivityChanged.skip(1).distinct().listen((ConnectivityResult result) {
      _createChannel();
    });
    _createChannel();
  }

  void _createChannel() async {
    try {
      _closeChannel();

      _channel = IOWebSocketChannel.connect(
          "ws://$serverName/ws?name=${Uri.encodeQueryComponent(name)}",
          pingInterval: Duration(seconds: 20)
      );
      _streamSubscription = _channel.stream
          .map((event) => jsonDecode(event))
          .listen(
              (event) => _messages.add((_messages.value ?? [])..add(event)),
      onError: (e) {
                print('_channel.stream Error: $e');
                wsConnectionErrorAttempt++;
                if (wsConnectionErrorAttempt < 3) {
                  Future.microtask(() => _createChannel());
                } else {
                  wsConnectionErrorAttempt = 0;
                  Future.delayed(Duration(seconds: 20), () => _createChannel());
                }
      },
      cancelOnError: true,
        onDone: () {
          _closeChannel();
          _channel = null;
        }
      );
      send('Всем чмоки в этом чате!');
    } catch (e) {
      print('MessagesModel connect error - $e');
    }
  }

  void _closeChannel() {
    _streamSubscription?.cancel()?.catchError((e) {
      print('ChannelSubscription cancel error $e');
      return null;
    });
    _channel?.sink?.close(status.goingAway)?.catchError((e) {
      print('ChannelSink close error $e');
      return null;
    });
  }

  final String name;
  final String serverName;
  final _messages = BehaviorSubject<List>();

  IOWebSocketChannel _channel;
  StreamSubscription _streamSubscription;
  StreamSubscription _connectivitySubscription;

  bool get connected => _channel != null;
  Stream<List> get messages => _messages.stream;
  bool send(String message) {
    if (_channel != null && _channel.closeCode == null) {
      try {
        _channel.sink.add(jsonEncode({'text': message}));
        return true;
      } catch (e) {
        print('_channel.sink error - $e');
      }
    }
    return false;
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _messages.close();
    _channel?.sink?.close(status.goingAway);
  }
}

