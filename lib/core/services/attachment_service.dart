import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PickedAttachment {
  final File file;
  final String fileName;
  final String extension;
  final int size;
  final bool isImage;

  const PickedAttachment({
    required this.file,
    required this.fileName,
    required this.extension,
    required this.size,
    required this.isImage,
  });
}

class AttachmentService {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxTextExtractLength = 12000;

  static const List<String> supportedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'pdf',
    'txt',
    'docx',
    'csv',
  ];

  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  bool isSupported(String extension) {
    return supportedExtensions.contains(
      extension.toLowerCase().replaceAll('.', ''),
    );
  }

  bool isImageExtension(String extension) {
    return imageExtensions.contains(
      extension.toLowerCase().replaceAll('.', ''),
    );
  }

  Future<PickedAttachment?> pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );

    if (result == null || result.files.isEmpty) return null;

    final pickedFile = result.files.single;
    final path = pickedFile.path;
    if (path == null) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    final fileName = pickedFile.name;
    final extension = p.extension(fileName).replaceAll('.', '').toLowerCase();
    final size = await file.length();

    if (!isSupported(extension)) {
      throw FormatException(
        'Unsupported file format ($extension). Supported formats: JPG, PNG, WebP, PDF, TXT, DOCX, CSV.',
      );
    }

    if (size > maxFileSizeBytes) {
      throw FormatException(
        'File size (${(size / (1024 * 1024)).toStringAsFixed(1)}MB) exceeds maximum allowed limit of 10MB.',
      );
    }

    return PickedAttachment(
      file: file,
      fileName: fileName,
      extension: extension,
      size: size,
      isImage: isImageExtension(extension),
    );
  }

  Future<String> saveAttachmentToAppStorage(
    File sourceFile,
    String fileName,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final targetPath = p.join(attachmentsDir.path, uniqueName);
    final savedFile = await sourceFile.copy(targetPath);
    return savedFile.path;
  }

  Future<String> extractDocumentText(File file, String extension) async {
    final ext = extension.toLowerCase().replaceAll('.', '');

    try {
      String extractedText = '';

      if (ext == 'txt' || ext == 'csv') {
        extractedText = await file.readAsString(encoding: utf8);
      } else if (ext == 'pdf') {
        final bytes = await file.readAsBytes();
        final document = PdfDocument(inputBytes: bytes);
        extractedText = PdfTextExtractor(document).extractText();
        document.dispose();
      } else if (ext == 'docx') {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final zipFile in archive) {
          if (zipFile.name == 'word/document.xml') {
            final content = utf8.decode(zipFile.content as List<int>);
            // Remove XML tags to extract raw paragraph text
            extractedText = content.replaceAll(RegExp(r'<[^>]*>'), ' ');
            break;
          }
        }
      }

      // Trim whitespace
      extractedText = extractedText.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (extractedText.length > maxTextExtractLength) {
        return '${extractedText.substring(0, maxTextExtractLength)}\n\n[Document content truncated for context limits]';
      }

      return extractedText;
    } catch (e) {
      return '[Could not extract document text: $e]';
    }
  }

  Future<void> deleteLocalAttachment(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Safe deletion ignore
    }
  }
}
