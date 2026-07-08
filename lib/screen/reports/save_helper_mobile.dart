import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareCsv({
  required String csvContent,
  required String filename,
  required String shareText,
}) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$filename');
  await file.writeAsString(csvContent);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      text: shareText,
    ),
  );
}
