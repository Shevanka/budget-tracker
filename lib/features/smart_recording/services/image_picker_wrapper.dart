import 'package:image_picker/image_picker.dart';

/// Supported image sources for receipt scanning.
enum ReceiptImageSource {
  camera,
  gallery,
}

/// Abstract wrapper around [ImagePicker] enabling clean unit testing and mockability.
abstract class ImagePickerWrapper {
  const ImagePickerWrapper();

  /// Captures or selects an image from [source].
  ///
  /// Returns the local file path string if an image was picked, or `null` if cancelled.
  Future<String?> pickImage({
    required ReceiptImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  });
}

/// Production implementation delegating to `package:image_picker`.
class DefaultImagePickerWrapper implements ImagePickerWrapper {
  final ImagePicker _picker;

  DefaultImagePickerWrapper([ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  @override
  Future<String?> pickImage({
    required ReceiptImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final imageSource = source == ReceiptImageSource.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    final xFile = await _picker.pickImage(
      source: imageSource,
      maxWidth: maxWidth ?? 1920,
      maxHeight: maxHeight ?? 1920,
      imageQuality: imageQuality ?? 85,
    );

    return xFile?.path;
  }
}
