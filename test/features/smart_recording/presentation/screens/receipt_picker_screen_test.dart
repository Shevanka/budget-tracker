import 'package:budget_tracker/features/smart_recording/models/receipt_scan_result.dart';
import 'package:budget_tracker/features/smart_recording/presentation/screens/receipt_picker_screen.dart';
import 'package:budget_tracker/features/smart_recording/providers/smart_recording_provider.dart';
import 'package:budget_tracker/features/smart_recording/services/image_picker_wrapper.dart';
import 'package:budget_tracker/features/smart_recording/services/receipt_ocr_service.dart';
import 'package:flutter/material.dart';
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

  Widget buildTestWidget({
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        imagePickerWrapperProvider.overrideWithValue(mockPicker),
        receiptOcrServiceProvider.overrideWithValue(mockOcrService),
        ...overrides,
      ],
      child: const MaterialApp(
        home: ReceiptPickerScreen(),
      ),
    );
  }

  group('ReceiptPickerScreen Widget Tests', () {
    testWidgets('renders header, scanning guidelines, and action buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Scan Receipt'), findsOneWidget);
      expect(find.text('Receipt Scanner'), findsOneWidget);
      expect(find.text('Tips Pemindaian Struk'), findsOneWidget);
      expect(find.text('Ambil Foto Kamera'), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
    });

    testWidgets('tapping Ambil Foto Kamera triggers camera picker and displays success card',
        (tester) async {
      const testPath = '/path/to/camera.jpg';
      final testResult = ReceiptScanResult(
        imagePath: testPath,
        rawText: 'INDOMARET\nTOTAL Rp 54.000',
        lines: const ['INDOMARET', 'TOTAL Rp 54.000'],
        timestamp: DateTime.utc(2026, 11, 1),
      );

      when(() => mockPicker.pickImage(source: ReceiptImageSource.camera))
          .thenAnswer((_) async => testPath);
      when(() => mockOcrService.processImage(testPath))
          .thenAnswer((_) async => testResult);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ambil Foto Kamera'));
      await tester.pumpAndSettle();

      verify(() => mockPicker.pickImage(source: ReceiptImageSource.camera)).called(1);
      verify(() => mockOcrService.processImage(testPath)).called(1);

      expect(find.text('Teks Berhasil Dikenali (2 baris)'), findsOneWidget);
      expect(find.text('Toko / Merchant:'), findsOneWidget);
      expect(find.text('INDOMARET'), findsWidgets);
      expect(find.text('TOTAL Rp 54.000'), findsOneWidget);
      expect(find.text('Gunakan Data Struk'), findsOneWidget);
    });

    testWidgets('tapping Pilih dari Galeri triggers gallery picker', (tester) async {
      const testPath = '/path/to/gallery.jpg';
      final testResult = ReceiptScanResult(
        imagePath: testPath,
        rawText: 'ALFAMART\nTOTAL Rp 32.000',
        lines: const ['ALFAMART', 'TOTAL Rp 32.000'],
        timestamp: DateTime.utc(2026, 11, 1),
      );

      when(() => mockPicker.pickImage(source: ReceiptImageSource.gallery))
          .thenAnswer((_) async => testPath);
      when(() => mockOcrService.processImage(testPath))
          .thenAnswer((_) async => testResult);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pilih dari Galeri'));
      await tester.pumpAndSettle();

      verify(() => mockPicker.pickImage(source: ReceiptImageSource.gallery)).called(1);
      verify(() => mockOcrService.processImage(testPath)).called(1);

      expect(find.text('Teks Berhasil Dikenali (2 baris)'), findsOneWidget);
      expect(find.text('Toko / Merchant:'), findsOneWidget);
      expect(find.text('ALFAMART'), findsWidgets);
    });

    testWidgets('cancelling picker shows cancellation snackbar', (tester) async {
      when(() => mockPicker.pickImage(source: ReceiptImageSource.camera))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ambil Foto Kamera'));
      await tester.pumpAndSettle();

      expect(find.text('Pengambilan gambar dibatalkan.'), findsOneWidget);
    });

    testWidgets('empty text OCR scan displays warning card and Coba Lagi button', (tester) async {
      const testPath = '/path/to/blurry.jpg';
      final emptyResult = ReceiptScanResult(
        imagePath: testPath,
        rawText: '',
        lines: const [],
        timestamp: DateTime.utc(2026, 11, 1),
      );

      when(() => mockPicker.pickImage(source: ReceiptImageSource.camera))
          .thenAnswer((_) async => testPath);
      when(() => mockOcrService.processImage(testPath))
          .thenAnswer((_) async => emptyResult);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ambil Foto Kamera'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Ada Teks Terdeteksi'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Tap Coba Lagi to reset
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Ambil Foto Kamera'), findsOneWidget);
    });

    testWidgets('OCR error displays error snackbar', (tester) async {
      const testPath = '/path/corrupted.jpg';
      when(() => mockPicker.pickImage(source: ReceiptImageSource.gallery))
          .thenAnswer((_) async => testPath);
      when(() => mockOcrService.processImage(testPath))
          .thenThrow(Exception('Corrupted file.'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pilih dari Galeri'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gagal memproses struk'), findsOneWidget);
    });
  });
}
