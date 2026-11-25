import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Where a document comes from.
enum DocumentSource {
  files('Choose a file', 'PDF, Word or image from your phone'),
  camera('Take a photo', 'Use the camera, e.g. for an ID card'),
  gallery('Choose from photos', 'Pick an image from your photo library');

  const DocumentSource(this.label, this.hint);

  final String label;
  final String hint;
}

/// A file chosen by the user, ready to upload.
class PickedDocument {
  const PickedDocument({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final int sizeBytes;
}

/// Thrown when the chosen file can't be used; [message] is shown as-is.
class DocumentPickException implements Exception {
  const DocumentPickException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Wraps the platform file and image pickers so tests can replace them.
class DocumentPicker {
  const DocumentPicker();

  static const int maxSizeBytes = 10 * 1024 * 1024;
  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> documentExtensions = [
    'pdf',
    'doc',
    'docx',
    ...imageExtensions,
  ];

  /// Returns `null` if the user cancels.
  Future<PickedDocument?> pick({
    required DocumentSource source,
    bool imagesOnly = false,
  }) async {
    final allowed = imagesOnly ? imageExtensions : documentExtensions;
    final PickedDocument picked;

    switch (source) {
      case DocumentSource.files:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: allowed,
        );
        if (result == null || result.files.isEmpty) return null;
        final file = result.files.single;
        final path = file.path;
        if (path == null) {
          throw const DocumentPickException('That file could not be opened.');
        }
        picked = PickedDocument(path: path, name: file.name, sizeBytes: file.size);

      case DocumentSource.camera:
      case DocumentSource.gallery:
        // Compressed to keep uploads small; JPEG output on both platforms.
        final image = await ImagePicker().pickImage(
          source: source == DocumentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 2400,
          maxHeight: 2400,
        );
        if (image == null) return null;
        picked = PickedDocument(
          path: image.path,
          name: image.name,
          sizeBytes: await image.length(),
        );
    }

    validate(picked, allowed);
    return picked;
  }

  /// Checks type and size; throws [DocumentPickException] with a message.
  static void validate(PickedDocument file, List<String> allowedExtensions) {
    final dot = file.name.lastIndexOf('.');
    final extension = dot == -1 ? '' : file.name.substring(dot + 1).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw DocumentPickException(
        allowedExtensions == imageExtensions
            ? 'Use a JPG or PNG image.'
            : 'Use a PDF, Word document or image (JPG, PNG).',
      );
    }
    if (file.sizeBytes > maxSizeBytes) {
      throw const DocumentPickException('The file must be 10 MB or smaller.');
    }
    if (file.sizeBytes == 0) {
      throw const DocumentPickException('That file is empty.');
    }
  }
}

final documentPickerProvider = Provider<DocumentPicker>(
  (ref) => const DocumentPicker(),
);
