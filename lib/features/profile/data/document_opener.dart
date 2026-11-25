import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:futuremug_interviewer/core/network/api_client.dart';
import 'package:futuremug_interviewer/features/profile/domain/interviewer_profile.dart';

/// Thrown when a document can't be shown; [message] is shown as-is.
class DocumentOpenException implements Exception {
  const DocumentOpenException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Opens a profile document in the phone's viewer (PDF viewer, photos,
/// Word…), from where the user can also save or share it.
///
/// Uses the copy on this device when there is one; otherwise downloads it
/// from `GET /evaluator/profile/documents/{id}/download` (API gap G2) into the
/// app's cache first.
class DocumentOpener {
  DocumentOpener(this._api);

  final ApiClient _api;

  Future<void> open(
    ProfileDocument document, {
    void Function(double progress)? onProgress,
  }) async {
    final path = await _localCopy(document, onProgress: onProgress);
    final result = await OpenFilex.open(path);
    if (result.type == ResultType.done) return;
    throw DocumentOpenException(
      result.type == ResultType.noAppToOpen
          ? 'No app on this phone can open this type of file.'
          : 'The file could not be opened.',
    );
  }

  Future<String> _localCopy(
    ProfileDocument document, {
    void Function(double progress)? onProgress,
  }) async {
    final local = document.localPath;
    if (local != null && File(local).existsSync()) return local;

    if (document.documentId.isEmpty) {
      throw const DocumentOpenException('This document is not available yet.');
    }
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'documents'),
    );
    await dir.create(recursive: true);
    final safeName = document.documentName.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    final target = p.join(dir.path, '${document.documentId}_$safeName');
    if (!File(target).existsSync()) {
      final partial = '$target.part';
      await _api.download(
        '/evaluator/profile/documents/${document.documentId}/download',
        partial,
        onProgress: onProgress,
      );
      await File(partial).rename(target);
    }
    return target;
  }
}

final documentOpenerProvider = Provider<DocumentOpener>(
  (ref) => DocumentOpener(ref.watch(apiClientProvider)),
);
