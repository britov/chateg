import 'dart:convert';

import 'package:chateg/drawer.dart';
import 'package:chateg/models.dart';
import 'package:chateg/routes.dart';
import 'package:crclib/crclib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final userModel = UserModel();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    Future.wait([userModel.init(), Future.delayed(Duration(seconds: 3))]).then((value) {
      if (userModel.serverName?.isEmpty != false) {
        _navigatorKey.currentState.pushNamedAndRemoveUntil(Routes.server, (_) => false);
      } else if (userModel.name?.isEmpty != false) {
        _navigatorKey.currentState.pushNamedAndRemoveUntil(Routes.username, (_) => false);
      } else {
        _navigatorKey.currentState.pushNamedAndRemoveUntil(Routes.chat, (_) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => userModel,
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        navigatorKey: _navigatorKey,
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          // This makes the visual density adapt to the platform that you run
          // the app on. For desktop platforms, the controls will be smaller and
          // closer together (more dense) than on mobile platforms.
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {
          Routes.splash: (context) => Center(
                child: Text(
                  'чатег',
                  style: Theme.of(context).textTheme.headline1,
                ),
              ),
          Routes.server: (context) => ServerInputPage(),
          Routes.username: (context) => UsernameInputPage(),
          Routes.chat: (context) => ChangeNotifierProvider(
                create: (_) => MessagesModel(name: userModel.name, serverName: userModel.serverName),
                lazy: false,
                child: MyHomePage(),
              ),
        },
      ),
    );
  }
}

class UsernameInputPage extends StatefulWidget {
  @override
  _UsernameInputPageState createState() => _UsernameInputPageState();
}

class _UsernameInputPageState extends State<UsernameInputPage> {
  final _key = GlobalKey<FormFieldState<String>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Theme.of(context).scaffoldBackgroundColor,),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Представьтесь',
              style: Theme.of(context).textTheme.headline4.copyWith(color: Colors.white),
              textAlign: TextAlign.center,),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              key: _key,
              autofocus: true,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  suffix: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      _submit(context);
                    },
                  )),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _submit(context),
              validator: (name) {
                if (name.length <= 1) {
                  return 'Короткое имя';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (_key.currentState.validate()) {
      context.read<UserModel>().name = _key.currentState.value;
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.chat, (_) => false);
    }
  }
}

class ServerInputPage extends StatefulWidget {
  @override
  _ServerInputPageState createState() => _ServerInputPageState();
}

class _ServerInputPageState extends State<ServerInputPage> {
  final _key = GlobalKey<FormFieldState<String>>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Выберите или введите адрес сервера',
              style: Theme.of(context).textTheme.headline4.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 40,
            ),
            TextFormField(
              key: _key,
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  suffix: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.send),
                    onPressed: () {
                      _submit(context);
                    },
                  )),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _submit(context),
              validator: (url) {
                if (url.isEmpty) {
                  return 'Обязательное поле';
                }
                return null;
              },
            ),
            for (var name in ['pm.tada.team', 'google.tada.team'])
              ActionChip(
                label: Text(name),
                onPressed: () => _controller.text = name,
              ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) async {
    if (_key.currentState.validate()) {
      var serverName = _key.currentState.value;
      var connected = await MessagesModel.tryInitConnection(serverName).catchError((e) {
        print('tryInitConnection. Error $e');
        return false;
      });
      if (connected) {
        context.read<UserModel>().serverName = serverName;
        Navigator.of(context).pushNamed(Routes.username);
      } else {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Не удалось подключиться к $serverName'),
        ));
      }
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _controller = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(),
      drawer: HomeDrawer(),
      body: Consumer<MessagesModel>(
          builder: (context, model, child) => Column(
                children: <Widget>[
                  Expanded(
                    child: StreamBuilder<List>(
                      stream: model.messages,
                      builder: (context, state) {
                        if (state.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!state.hasData) {
                          return Center(child: Text('Все молчат, напиши первым'));
                        }
                        var length2 = state.data.length;
                        return ListView.builder(
                            reverse: true,
                            itemCount: length2,
                            itemBuilder: (context, i) => Message(
                                  name: state.data[length2 - i - 1]['name'],
                                  text: state.data[length2 - i - 1]['text'],
                                  isYour: state.data[length2 - i - 1]['name'] == model.name,
                                ));
                      },
                    ),
                  ),
                  Material(
                    elevation: 1,
                    color: Colors.black12,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextFormField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.send,
                        onFieldSubmitted: (_) => _sendMessage(context),
                        decoration: InputDecoration(
                            hintText: 'Сообщение',
                            suffix: IconButton(
                              icon: Icon(Icons.send),
                              onPressed: () {
                                _sendMessage(context);
                              },
                            )),
                      ),
                    ),
                  )
                ],
              )),
    );
  }

  void _sendMessage(BuildContext context) {
    var message = _controller.text.trim();
    if (message.isNotEmpty) {
      context.read<MessagesModel>().send(message);
      _controller.clear();
    }
  }
}

class Message extends StatelessWidget {
  const Message({Key key, this.isYour, this.name, this.text}) : super(key: key);

  final bool isYour;
  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    var crossAxisAlignment2;
    var alignment;
    var black12;
    if (isYour) {
      crossAxisAlignment2 = CrossAxisAlignment.end;
      alignment = Alignment.centerRight;
      black12 = Colors.blue.withOpacity(0.4);
    } else if (name?.isNotEmpty == true) {
      crossAxisAlignment2 = CrossAxisAlignment.start;
      alignment = Alignment.centerLeft;
      black12 = Colors.black12;
    } else {
      crossAxisAlignment2 = CrossAxisAlignment.center;
      alignment = Alignment.center;
      black12 = null;
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: alignment,
        child: Container(
          decoration: BoxDecoration(color: black12, borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: crossAxisAlignment2,
              children: <Widget>[
                if (!isYour)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      name ?? '',
                      style: Theme.of(context).textTheme.bodyText1.copyWith(color: WidgetUtils.getRandomColor(name)),
                    ),
                  ),
                SelectableText(
                  text ?? '',
                  style: Theme.of(context).textTheme.bodyText2,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WidgetUtils {
  /// Generate persistent random color for channel.
  static Color getRandomColor(String title) {
    if (title == null || title.isEmpty) {
      return null;
    }
    int color = Crc32Zlib().convert(utf8.encode(title));

    color &= 0x00FFFFFF;
    color |= 0xA0000000;
    return Color(color);
  }
}
