// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> saveAndShareCsv({
  required String csvContent,
  required String filename,
  required String shareText,
}) async {
  final blob = html.Blob([csvContent], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
