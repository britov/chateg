import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefUtil {
  static const _myServer = 'SERVER';
  static const _myName = 'NAME';
  SharedPreferences _sharedPreferences;
  init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  String getMyServer() {
    return _sharedPreferences.get(_myServer);
  }

  Future<bool> setMyServer(String phone) {
    return _sharedPreferences.setString(_myServer, phone);
  }

  String getMyName() {
    return _sharedPreferences.get(_myName);
  }

  Future<bool> setMyName(String name) {
    return _sharedPreferences.setString(_myName, name);
  }
}
