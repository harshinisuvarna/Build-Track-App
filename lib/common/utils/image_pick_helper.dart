import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

/// Works on both mobile (File path) and web (bytes + blob URL).
class PickedAttachment {
  /// Native file — available on mobile, null on web.
  final File? nativeFile;

  /// Raw bytes — available on web, null on mobile.
  final Uint8List? bytes;

  /// On web images picked via image_picker, this is a blob URL usable
  /// in Image.network().  On mobile it's null.
  final String? webPath;

  final String name;
  final bool isImage;

  const PickedAttachment({
    required this.name,
    required this.isImage,
    this.nativeFile,
    this.bytes,
    this.webPath,
  });

  bool get isPdf => name.toLowerCase().endsWith('.pdf');
  bool get isDoc =>
      name.toLowerCase().endsWith('.doc') ||
      name.toLowerCase().endsWith('.docx');

  IconData get icon {
    if (isImage) return Icons.image_outlined;
    if (isPdf) return Icons.picture_as_pdf_outlined;
    if (isDoc) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color get iconColor {
    if (isImage) return const Color(0xFF4A6CF7);
    if (isPdf) return const Color(0xFFE53935);
    if (isDoc) return const Color(0xFF1565C0);
    return const Color(0xFF546E7A);
  }

  Color get iconBg {
    if (isImage) return const Color(0xFFEEF0FF);
    if (isPdf) return const Color(0xFFFFEBEE);
    if (isDoc) return const Color(0xFFE3F2FD);
    return const Color(0xFFECEFF1);
  }

  /// Returns an [ImageProvider] suitable for both web and mobile.
  ImageProvider? get imageProvider {
    if (!isImage) return null;
    if (kIsWeb && webPath != null) return NetworkImage(webPath!);
    if (kIsWeb && bytes != null) return MemoryImage(bytes!);
    if (nativeFile != null) return FileImage(nativeFile!);
    return null;
  }
}

// ─── Main entry: one tap opens system picker ─────────────────────────────────

Future<PickedAttachment?> pickAttachmentDirect(BuildContext context) async {
  if (kIsWeb) {
    return _pickOnWeb(context);
  } else {
    return _pickOnMobile(context);
  }
}

// ─── Mobile picker ───────────────────────────────────────────────────────────

Future<PickedAttachment?> _pickOnMobile(BuildContext context) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return null;
    final pf = result.files.first;
    if (pf.path == null) return null;

    final name = pf.name;
    final ext = name.split('.').last.toLowerCase();
    const imageExts = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif'};
    final isImage = imageExts.contains(ext);

    return PickedAttachment(
      nativeFile: File(pf.path!),
      name: name,
      isImage: isImage,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file picker: $e')),
      );
    }
    return null;
  }
}

// ─── Web picker ──────────────────────────────────────────────────────────────

Future<PickedAttachment?> _pickOnWeb(BuildContext context) async {
  try {
    // On web, use FilePicker with bytes (path is unavailable on web).
    // withData:true is required — bytes is the only way to access the file.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;
    final pf = result.files.first;
    final name = pf.name;
    final ext = name.split('.').last.toLowerCase();
    const imageExts = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'};
    final isImage = imageExts.contains(ext);

    // Use the bytes directly — no second picker call needed.
    return PickedAttachment(
      bytes: pf.bytes,
      name: name,
      isImage: isImage,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file picker: $e')),
      );
    }
    return null;
  }
}

// ─── Legacy compat ───────────────────────────────────────────────────────────

Future<File?> pickImageFromGallery(BuildContext context) async {
  final result = await pickAttachmentDirect(context);
  return result?.nativeFile;
}
