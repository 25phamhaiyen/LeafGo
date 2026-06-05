import 'package:url_launcher/url_launcher.dart';

/// Launches the phone's default dialer application with the provided phone number.
/// Removes any whitespace from the phone number before launching.
Future<bool> launchPhoneCall(String phoneNumber) async {
  try {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );
    if (await canLaunchUrl(launchUri)) {
      return await launchUrl(launchUri);
    }
  } catch (_) {}
  return false;
}
