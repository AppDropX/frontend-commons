import 'dart:io';

/// Confirms the radio is not a captive / dead network (Wi-Fi with no internet).
Future<bool> verifyInternetReachable() async {
  try {
    final result = await InternetAddress.lookup('example.com')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  } on OSError {
    return false;
  } catch (_) {
    return false;
  }
}
