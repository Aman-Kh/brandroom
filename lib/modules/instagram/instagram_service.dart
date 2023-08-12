import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/constants.dart';
import '../../services/dependency_injection.dart';
import 'classes/metadata.dart';

//// only call new api per hour because limit request
class InstagramService {
  static Future<Metadata> getMetadata(String path) async {
    try {
      var key = LocalStorageKey.instagramLocalKey + path;

      var localData = injector<SharedPreferences>().getString(key);

      if (localData != null) {
        var data = jsonDecode(localData);
        var time = data['time'];

        /// load from local if time change < 60s
        if (time != null &&
            DateTime.fromMillisecondsSinceEpoch(time).isAfter(
              DateTime.now()
                  .subtract(const Duration(seconds: Duration.secondsPerHour)),
            )) {
          printLog('⬇️ Load Instagram data from local');
          return Metadata.fromJson(data);
        }
      }
      printLog('⬇️ Load Instagram data from server');
      final endpoint = 'www.instagram.com/$path/?__a=1'.replaceAll('//', '/');
      var response = await httpGet(
        Uri.parse('https://$endpoint'),
      );
      var body = response.body;
      var data = jsonDecode(body);
      data['time'] = DateTime.now().millisecondsSinceEpoch;
      await injector<SharedPreferences>().setString(key, jsonEncode(data));
      return Metadata.fromJson(data);
    } catch (e, trace) {
      printLog(e.toString());
      printLog(trace.toString());
      return Metadata(loadFail: true);
    }
  }
}
