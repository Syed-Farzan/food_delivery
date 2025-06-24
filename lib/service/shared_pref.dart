import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefrenceHelper {
  static String userIdKey = 'USERKEY';
  static String userName = "USERNAMEKEY";
  static String userPhoneKey = 'USEREPHONEKEY';
  static String userWalletKey = 'USEREWALLETKEY';
  static String userPincode = 'USERPINCODE';
  static String userAdress = 'USERADRESS';

  Future<bool> saveUserID(String getUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdKey, getUserId);
  }

  Future<bool> saveUserName(String getUserName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userName, getUserName);
  }

  Future<bool> savePhoneKey(String getPhoneKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userPhoneKey, getPhoneKey);
  }

  Future<bool> savepincode(String getPincode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userPincode, getPincode);
  }

  Future<bool> saveadress(String getadress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userAdress, getadress);
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  Future<String?> getPincodea() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userPincode);
  }

  Future<String?> getadress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userAdress);
  }

  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userName);
  }

  Future<String?> getPhoneKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userPhoneKey);
  }
}
