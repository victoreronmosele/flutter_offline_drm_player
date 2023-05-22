import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesUtil {
  static const String licenseKeySharedPreferencesKey = "user_name";

  SharedPreferencesUtil._(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  static SharedPreferencesUtil? _sharedPreferencesUtil;

  /// Initializes and returns the shared preference util instance
  ///
  /// Use this instance to set and get values from shared preferences
  static Future<SharedPreferencesUtil> initialize() async {
    if (_sharedPreferencesUtil != null) {
      return _sharedPreferencesUtil!;
    }

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    _sharedPreferencesUtil = SharedPreferencesUtil._(sharedPreferences);

    return _sharedPreferencesUtil!;
  }

  Future<bool> setLicenseKey(String licenceKey) {
    return _sharedPreferences.setString(
        licenseKeySharedPreferencesKey, licenceKey);
  }

  String? getLicenseKey() {
    return _sharedPreferences.getString(licenseKeySharedPreferencesKey);
  }
}
