import 'package:budget_tracker/features/smart_recording/models/receipt_scan_result.dart';
import 'package:budget_tracker/features/smart_recording/providers/smart_recording_provider.dart';
import 'package:budget_tracker/features/smart_recording/services/image_picker_wrapper.dart';
import 'package:budget_tracker/features/smart_recording/services/receipt_ocr_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockImagePickerWrapper extends Mock implements ImagePickerWrapper {}

class MockReceiptOcrService extends Mock implements ReceiptOcrService {}

void main() {
  late MockImagePickerWrapper mockPicker;
  late MockReceiptOcrService mockOcrService;

  setUp(() {
    mockPicker = MockImagePickerWrapper();
    mockOcrService = MockReceiptOcrService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        imagePickerWrapperProvider.overrideWithValue(mockPicker),
        receiptOcrServiceProvider.overrideWithValue(mockOcrService),
      ],
    );
    return container;
  }

  group('ReceiptScannerNotifier', () {
    test('initial state is ReceiptScannerIdle', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(receiptScannerProvider);
      expect(state, isA<ReceiptScannerIdle>());
    });

    test('successful scan from camera sets ReceiptScannerSuccess and updates latestScanResultProvider', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      const testPath = '/data/user/0/cache/camera_receipt.jpg';
      final testResult = ReceiptScanResult(
        imagePath: testPath,
        rawText: 'INDOMARET\nTOTAL: Rp 50.000',
        lines: const ['INDOMARET', 'TOTAL: Rp 50.000'],
        timestamp: DateTime.utc(2026, 11, 1),
      );

      when(() => mockPicker.pickImage(source: ReceiptImageSource.camera))
          .thenAnswer((_) async => testPath);
      when(() => mockOcrService.processImage(testPath))
          .thenAnswer((_) async => testResult);

      final result = await container
          .read(receiptScannerProvider.notifier)
          .scanFromSource(ReceiptImageSource.camera);

      expect(result, equals(testResult));
      final state = container.read(receiptScannerProvider);
      expect(state, isA<ReceiptScannerSuccess>());
      expect((state as ReceiptScannerSuccess).result, equals(testResult));
      expect(container.read(latestScanResultProvider), equals(testResult));

      verify(() => mockPicker.pickImage(source: ReceiptImageSource.camera)).called(1);
      verify(() => mockOcrService.processImage(testPath)).called(1);
    });

    test('successful scan from gallery sets ReceiptScannerSuccess', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      const testPath = '/data/user/0/cache/gallery_receipt.png';
      final testResult = ReceiptScanResult(
        imagePath: testPath,
        rawText: 'ALFAMART\nTOTAL Rp 24.500',
        lines: const ['ALFAMART', 'TOTAL Rp 24.500'],
        timestamp: DateTime.utc(2026, 11, 1),
      );

      when(() => mockPicker.pickImage(source: ReceiptImageSource.gallery))
          .thenAnswer((_) async => testPath);
      when(() => mockOcrService.processImage(testPath))
          .thenAnswer((_) async => testResult);

      final result = await container
          .read(receiptScannerProvider.notifier)
          .scanFromSource(ReceiptImageSource.gallery);

      expect(result, equals(testResult));
      final state = container.read(receiptScannerProvider);
      expect(state, isA<ReceiptScannerSuccess>());
    });

    test('cancelled picker sets ReceiptScannerCancelled and does not run OCR', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(() => mockPicker.pickImage(source: ReceiptImageSource.camera))
          .thenAnswer((_) async => null);

      final result = await container
          .read(receiptScannerProvider.notifier)
          .scanFromSource(ReceiptImageSource.camera);

      expect(result, isNull);
      final state = container.read(receiptScannerProvider);
      expect(state, isA<ReceiptScannerCancelled>());
      verifyNever(() => mockOcrService.processImage(any()));
    });

    test('ocr error sets ReceiptScannerError state', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      const testPath = '/path/damaged.jpg';
      when(() => mockPicker.pickImage(source: ReceiptImageSource.gallery))
          .thenAnswer((_) async => testPath);
      when(() => mockOcrService.processImage(testPath))
          .thenThrow(Exception('Failed to process image file.'));

      final result = await container
          .read(receiptScannerProvider.notifier)
          .scanFromSource(ReceiptImageSource.gallery);

      expect(result, isNull);
      final state = container.read(receiptScannerProvider);
      expect(state, isA<ReceiptScannerError>());
      expect((state as ReceiptScannerError).message, contains('Failed to process image file'));
    });

    test('reset reverts state to ReceiptScannerIdle', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(() => mockPicker.pickImage(source: ReceiptImageSource.camera))
          .thenAnswer((_) async => null);

      await container
          .read(receiptScannerProvider.notifier)
          .scanFromSource(ReceiptImageSource.camera);
      expect(container.read(receiptScannerProvider), isA<ReceiptScannerCancelled>());

      container.read(receiptScannerProvider.notifier).reset();
      expect(container.read(receiptScannerProvider), isA<ReceiptScannerIdle>());
    });
  });
}
