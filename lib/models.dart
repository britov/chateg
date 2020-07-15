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
    _name = name;
    _sharedPrefUtil.setMyName(name);
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
      _streamSubscription?.cancel();
      await _channel?.sink?.close(status.goingAway);

      _channel = IOWebSocketChannel.connect("ws://$serverName/ws?name=$name");
      _streamSubscription = _channel.stream
          .map((event) => jsonDecode(event))
          .listen(
              (event) => _messages.add((_messages.value ?? [])..add(event)),
      onError: (e) {
                print('_channel.stream Error: $e');
                Future.microtask(() => _createChannel());
      });
      send('Всем чмоки в этом чате!');
    } catch (e) {
      print('MessagesModel connect error - $e');
    }
  }

  final String name;
  final String serverName;
  final _messages = BehaviorSubject<List>();

  IOWebSocketChannel _channel;
  StreamSubscription _streamSubscription;
  StreamSubscription _connectivitySubscription;

  bool get connected => _channel != null;
  Stream<List> get messages => _messages.stream;
  send(String message) {
    _channel?.sink?.add(jsonEncode({'text': message}));
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

