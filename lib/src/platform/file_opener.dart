import 'package:open_file/open_file.dart';

/// Platform-agnostic file opener abstraction used by the UI/ViewModel.
abstract class FileOpener {
  /// Opens the file at [path]. Returns true on success, false on failure.
  Future<bool> open(String path);
}

class FileOpenerImpl implements FileOpener {
  @override
  Future<bool> open(String path) async {
    try {
      final OpenResult result = await OpenFile.open(path);
      // OpenFileResult has a type and message; treat non-success as failure.
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }
}
