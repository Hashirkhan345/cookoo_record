import 'dart:io';

Future<void> deleteRecordedFile(String path) async {
  final File file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}
