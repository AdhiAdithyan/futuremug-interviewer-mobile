import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/core/files/document_picker.dart';
import 'package:futuremug_interviewer/core/network/api_exception.dart';
import 'package:futuremug_interviewer/features/profile/data/document_opener.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';
import 'package:futuremug_interviewer/shared/widgets/app_snackbar.dart';
import 'package:futuremug_interviewer/shared/widgets/async_submit.dart';

typedef UploadDocument = Future<void> Function(
  PickedDocument file,
  DocumentType type,
  void Function(double progress) onProgress,
);

/// The interviewer's documents, with upload (file, camera or photo library),
/// open/download, replace and remove. Used by profile setup (step 4) and
/// the Profile tab. Each file is uploaded as soon as it is picked.
class DocumentsSection extends ConsumerStatefulWidget {
  const DocumentsSection({
    super.key,
    required this.documents,
    required this.onUpload,
    this.onRemove,
  });

  final List<ProfileDocument> documents;
  final UploadDocument onUpload;

  /// `null` hides the remove action.
  final Future<void> Function(ProfileDocument document)? onRemove;

  @override
  ConsumerState<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends ConsumerState<DocumentsSection> {
  DocumentType? _uploadingType;
  double? _uploadProgress;
  String? _busyDocumentId;

  bool get _busy => _uploadingType != null || _busyDocumentId != null;

  bool get _hasResume =>
      widget.documents.any((d) => d.type == DocumentType.resume);

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------

  Future<void> _startUpload({DocumentType? type}) async {
    final chosenType = type ?? await _chooseType();
    if (chosenType == null || !mounted) return;
    final source = await _chooseSource(chosenType);
    if (source == null || !mounted) return;

    await runWithErrorSnackbar(context, () async {
      final file = await ref
          .read(documentPickerProvider)
          .pick(source: source, imagesOnly: chosenType.imagesOnly);
      if (file == null || !mounted) return;
      setState(() {
        _uploadingType = chosenType;
        _uploadProgress = null;
      });
      try {
        await widget.onUpload(file, chosenType, (p) {
          if (mounted) setState(() => _uploadProgress = p);
        });
        if (mounted) {
          AppSnackbar.showInfo(context, '${chosenType.label} uploaded.');
        }
      } finally {
        if (mounted) {
          setState(() {
            _uploadingType = null;
            _uploadProgress = null;
          });
        }
      }
    });
  }

  Future<DocumentType?> _chooseType() {
    return showModalBottomSheet<DocumentType>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'What are you uploading?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              for (final type in DocumentType.values)
                ListTile(
                  leading: Icon(documentTypeIcon(type)),
                  title: Text(type.label),
                  subtitle: Text(
                    type.singleOnly &&
                            widget.documents.any((d) => d.type == type)
                        ? 'Replaces your current one'
                        : type.hint,
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(type),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<DocumentSource?> _chooseSource(DocumentType type) {
    final sources = type.imagesOnly
        ? const [DocumentSource.camera, DocumentSource.gallery]
        : DocumentSource.values;
    return showModalBottomSheet<DocumentSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                type.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final source in sources)
              ListTile(
                leading: Icon(_sourceIcon(source)),
                title: Text(source.label),
                subtitle: Text(source.hint),
                onTap: () => Navigator.of(sheetContext).pop(source),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Open / remove
  // ---------------------------------------------------------------------------

  Future<void> _open(ProfileDocument document) async {
    if (_busy) return;
    setState(() => _busyDocumentId = document.documentId);
    try {
      await ref.read(documentOpenerProvider).open(document);
    } on DocumentOpenException catch (e) {
      if (mounted) AppSnackbar.showError(context, e.message);
    } on ApiException catch (e) {
      if (mounted) AppSnackbar.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busyDocumentId = null);
    }
  }

  Future<void> _remove(ProfileDocument document) async {
    final onRemove = widget.onRemove;
    if (onRemove == null) return;

    final isOnlyResume = document.type == DocumentType.resume &&
        widget.documents.where((d) => d.type == DocumentType.resume).length ==
            1;
    if (isOnlyResume) {
      AppSnackbar.showError(
        context,
        'A resume is required. Use "Replace" to upload a newer one.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove document?'),
        content: Text('“${document.documentName}” will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;
    setState(() => _busyDocumentId = document.documentId);
    await runWithErrorSnackbar(context, () => onRemove(document));
    if (mounted) setState(() => _busyDocumentId = null);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Resume first, then the order of the type list.
    final sorted = [...widget.documents]
      ..sort((a, b) => a.type.index.compareTo(b.type.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PDF, Word or images up to 10 MB. You can also take a photo. '
          'A resume is required.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              'No documents yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final doc in sorted) _buildTile(doc, theme),
        if (_uploadingType != null) ...[
          const SizedBox(height: 8),
          Text(
            'Uploading ${_uploadingType!.label.toLowerCase()}…',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: _uploadProgress),
        ],
        const SizedBox(height: 12),
        if (!_hasResume) ...[
          ElevatedButton.icon(
            onPressed: _busy
                ? null
                : () => _startUpload(type: DocumentType.resume),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload resume'),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _startUpload(),
          icon: const Icon(Icons.add),
          label: const Text('Add a document'),
        ),
      ],
    );
  }

  Widget _buildTile(ProfileDocument doc, ThemeData theme) {
    final isBusy = _busyDocumentId == doc.documentId;
    return Card(
      child: ListTile(
        leading: Icon(
          documentTypeIcon(doc.type),
          color: theme.colorScheme.secondary,
        ),
        title: Text(
          doc.documentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            doc.type.label,
            if (doc.fileSizeBytes != null) formatFileSize(doc.fileSizeBytes!),
          ].join(' · '),
        ),
        onTap: _busy ? null : () => _open(doc),
        trailing: isBusy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<_DocAction>(
                tooltip: 'Options for ${doc.documentName}',
                enabled: !_busy,
                onSelected: (action) => switch (action) {
                  _DocAction.open => _open(doc),
                  _DocAction.replace => _startUpload(type: doc.type),
                  _DocAction.remove => _remove(doc),
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _DocAction.open,
                    child: ListTile(
                      leading: Icon(Icons.open_in_new),
                      title: Text('Open / download'),
                    ),
                  ),
                  if (doc.type.singleOnly)
                    const PopupMenuItem(
                      value: _DocAction.replace,
                      child: ListTile(
                        leading: Icon(Icons.swap_horiz),
                        title: Text('Replace'),
                      ),
                    ),
                  if (widget.onRemove != null)
                    const PopupMenuItem(
                      value: _DocAction.remove,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Remove'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  static IconData _sourceIcon(DocumentSource source) => switch (source) {
        DocumentSource.files => Icons.folder_open_outlined,
        DocumentSource.camera => Icons.photo_camera_outlined,
        DocumentSource.gallery => Icons.photo_library_outlined,
      };
}

enum _DocAction { open, replace, remove }

IconData documentTypeIcon(DocumentType type) => switch (type) {
      DocumentType.resume => Icons.description_outlined,
      DocumentType.degreeCertificate => Icons.school_outlined,
      DocumentType.experienceLetter => Icons.work_history_outlined,
      DocumentType.certification => Icons.workspace_premium_outlined,
      DocumentType.identityProof => Icons.badge_outlined,
      DocumentType.profilePhoto => Icons.account_circle_outlined,
      DocumentType.other => Icons.insert_drive_file_outlined,
    };

String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).ceil()} KB';
}
