import 'dart:io';

import 'package:aura_ai/core/services/attachment_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AttachmentService service;

  setUp(() {
    service = AttachmentService();
  });

  group('AttachmentService Unit Tests', () {
    test('isSupported validates extensions correctly', () {
      expect(service.isSupported('jpg'), isTrue);
      expect(service.isSupported('png'), isTrue);
      expect(service.isSupported('pdf'), isTrue);
      expect(service.isSupported('docx'), isTrue);
      expect(service.isSupported('csv'), isTrue);

      expect(service.isSupported('exe'), isFalse);
      expect(service.isSupported('zip'), isFalse);
      expect(service.isSupported('sh'), isFalse);
    });

    test('isImageExtension identifies images correctly', () {
      expect(service.isImageExtension('jpg'), isTrue);
      expect(service.isImageExtension('png'), isTrue);
      expect(service.isImageExtension('webp'), isTrue);
      expect(service.isImageExtension('pdf'), isFalse);
      expect(service.isImageExtension('txt'), isFalse);
    });

    test(
      'extractDocumentText reads and truncates long text files safely',
      () async {
        final tempDir = Directory.systemTemp.createTempSync('aura_test');
        final testFile = File('${tempDir.path}/sample.txt');

        final longText = 'Aura AI ' * 2000; // ~16,000 chars
        await testFile.writeAsString(longText);

        final extracted = await service.extractDocumentText(testFile, 'txt');

        expect(
          extracted,
          contains('[Document content truncated for context limits]'),
        );
        expect(extracted.length, lessThan(longText.length));

        tempDir.deleteSync(recursive: true);
      },
    );
  });
}
