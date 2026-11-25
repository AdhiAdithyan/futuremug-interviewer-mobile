import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/core/files/document_picker.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_app_theme.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';
import 'package:futuremug_interviewer/features/profile/presentation/widgets/documents_section.dart';

import '../../helpers/test_app.dart';

void main() {
  const resume = ProfileDocument(
    documentId: 'D1',
    documentName: 'cv.pdf',
    type: DocumentType.resume,
    fileSizeBytes: 2048,
  );
  const picked = PickedDocument(
    path: '/tmp/letter.pdf',
    name: 'letter.pdf',
    sizeBytes: 1000,
  );

  late FakeDocumentPicker picker;
  late List<(PickedDocument, DocumentType)> uploads;
  late List<ProfileDocument> removed;

  Future<void> pumpSection(
    WidgetTester tester, {
    List<ProfileDocument> documents = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [documentPickerProvider.overrideWithValue(picker)],
        child: MaterialApp(
          theme: FuturemugAppTheme.whiteTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentsSection(
                documents: documents,
                onUpload: (file, type, onProgress) async {
                  onProgress(1);
                  uploads.add((file, type));
                },
                onRemove: (doc) async => removed.add(doc),
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    picker = FakeDocumentPicker(picked);
    uploads = [];
    removed = [];
  });

  testWidgets('without a resume, an "Upload resume" button is shown',
      (tester) async {
    await pumpSection(tester);
    expect(find.text('Upload resume'), findsOneWidget);
    expect(find.text('No documents yet.'), findsOneWidget);
  });

  testWidgets('with a resume, the button is hidden and the file is listed',
      (tester) async {
    await pumpSection(tester, documents: const [resume]);
    expect(find.text('Upload resume'), findsNothing);
    expect(find.text('cv.pdf'), findsOneWidget);
    expect(find.text('Resume / CV · 2 KB'), findsOneWidget);
  });

  testWidgets('add a document: choose the type, then the source',
      (tester) async {
    await pumpSection(tester, documents: const [resume]);

    await tester.tap(find.text('Add a document'));
    await tester.pumpAndSettle();
    expect(find.text('What are you uploading?'), findsOneWidget);
    for (final type in DocumentType.values) {
      expect(find.text(type.label), findsWidgets);
    }

    await tester.tap(find.text('Experience letter'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from photos'), findsOneWidget);

    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();

    expect(picker.lastSource, DocumentSource.files);
    expect(picker.lastImagesOnly, isFalse);
    expect(uploads.single.$2, DocumentType.experienceLetter);
    expect(find.text('Experience letter uploaded.'), findsOneWidget);
  });

  testWidgets('profile photo offers only camera and photo library',
      (tester) async {
    await pumpSection(tester, documents: const [resume]);

    await tester.tap(find.text('Add a document'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Profile photo'));
    await tester.tap(find.text('Profile photo'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a file'), findsNothing);
    expect(find.text('Take a photo'), findsOneWidget);

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(picker.lastSource, DocumentSource.camera);
    expect(picker.lastImagesOnly, isTrue);
  });

  testWidgets('cancelling the picker uploads nothing', (tester) async {
    picker.result = null;
    await pumpSection(tester);

    await tester.tap(find.text('Upload resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();

    expect(uploads, isEmpty);
  });

  testWidgets('the only resume cannot be removed', (tester) async {
    await pumpSection(tester, documents: const [resume]);

    await tester.tap(find.byTooltip('Options for cv.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(removed, isEmpty);
    expect(find.textContaining('Use "Replace"'), findsOneWidget);
  });

  testWidgets('other documents can be removed after confirming',
      (tester) async {
    const letter = ProfileDocument(
      documentId: 'D2',
      documentName: 'letter.pdf',
      type: DocumentType.experienceLetter,
    );
    await pumpSection(tester, documents: const [resume, letter]);

    await tester.tap(find.byTooltip('Options for letter.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(removed.single.documentId, 'D2');
  });

  group('DocumentPicker.validate', () {
    PickedDocument doc(String name, int size) =>
        PickedDocument(path: '/x/$name', name: name, sizeBytes: size);

    test('accepts allowed types within the size limit', () {
      DocumentPicker.validate(
        doc('cv.PDF', 1000),
        DocumentPicker.documentExtensions,
      );
      DocumentPicker.validate(
        doc('id.jpg', 1000),
        DocumentPicker.imageExtensions,
      );
    });

    test('rejects wrong types, empty and oversized files', () {
      expect(
        () => DocumentPicker.validate(
          doc('cv.exe', 1000),
          DocumentPicker.documentExtensions,
        ),
        throwsA(isA<DocumentPickException>()),
      );
      expect(
        () => DocumentPicker.validate(
          doc('photo.pdf', 1000),
          DocumentPicker.imageExtensions,
        ),
        throwsA(isA<DocumentPickException>()),
      );
      expect(
        () => DocumentPicker.validate(
          doc('big.pdf', DocumentPicker.maxSizeBytes + 1),
          DocumentPicker.documentExtensions,
        ),
        throwsA(isA<DocumentPickException>()),
      );
      expect(
        () => DocumentPicker.validate(
          doc('empty.pdf', 0),
          DocumentPicker.documentExtensions,
        ),
        throwsA(isA<DocumentPickException>()),
      );
    });
  });

  test('unknown document types from the server become "Other"', () {
    expect(DocumentType.fromApi('SOMETHING_NEW'), DocumentType.other);
    expect(DocumentType.fromApi('RESUME_CV'), DocumentType.resume);
    final apiValues = DocumentType.values.map((t) => t.apiValue).toSet();
    expect(apiValues, hasLength(DocumentType.values.length));
  });
}
