import 'dart:html' as html;
import 'dart:typed_data';

const String _databaseName = 'cookoo_video_recordings';
const String _recordingsObjectStoreName = 'saved_recordings';

class VideoRecordingIndexedDbStore {
  const VideoRecordingIndexedDbStore();

  bool get isSupported => html.window.indexedDB != null;

  Future<void> saveBytes(String key, Uint8List bytes) async {
    final dynamic database = await _openDatabase();

    try {
      final dynamic transaction = database.transaction(
        _recordingsObjectStoreName,
        'readwrite',
      );
      final dynamic objectStore = transaction.objectStore(
        _recordingsObjectStoreName,
      );

      await objectStore.put(bytes, key);
      await transaction.completed;
    } finally {
      database.close();
    }
  }

  Future<Uint8List?> loadBytes(String key) async {
    final dynamic database = await _openDatabase();

    try {
      final dynamic transaction = database.transaction(
        _recordingsObjectStoreName,
        'readonly',
      );
      final dynamic objectStore = transaction.objectStore(
        _recordingsObjectStoreName,
      );
      final Object? storedValue = await objectStore.getObject(key);
      await transaction.completed;

      return _coerceBytes(storedValue);
    } finally {
      database.close();
    }
  }

  Future<void> deleteBytes(String key) async {
    if (!isSupported) {
      return;
    }

    final dynamic database = await _openDatabase();

    try {
      final dynamic transaction = database.transaction(
        _recordingsObjectStoreName,
        'readwrite',
      );
      final dynamic objectStore = transaction.objectStore(
        _recordingsObjectStoreName,
      );

      await objectStore.delete(key);
      await transaction.completed;
    } finally {
      database.close();
    }
  }

  Future<dynamic> _openDatabase() async {
    final dynamic indexedDbFactory = html.window.indexedDB;
    if (indexedDbFactory == null) {
      throw StateError('IndexedDB is not available in this browser.');
    }

    return indexedDbFactory.open(
      _databaseName,
      version: 1,
      onUpgradeNeeded: (dynamic event) {
        final dynamic request = event.target;
        final dynamic database = request.result;
        final List<String> objectStoreNames = List<String>.from(
          database.objectStoreNames ?? const <String>[],
        );

        if (!objectStoreNames.contains(_recordingsObjectStoreName)) {
          database.createObjectStore(_recordingsObjectStoreName);
        }
      },
    );
  }

  Uint8List? _coerceBytes(Object? storedValue) {
    if (storedValue == null) {
      return null;
    }
    if (storedValue is Uint8List) {
      return storedValue;
    }
    if (storedValue is ByteBuffer) {
      return Uint8List.view(storedValue);
    }
    if (storedValue is List<int>) {
      return Uint8List.fromList(storedValue);
    }

    throw StateError('Unsupported recording payload in IndexedDB.');
  }
}
