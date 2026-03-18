import 'dart:typed_data';

void downloadBytes(String fileName, Uint8List bytes) {
  // Try file picker for desktop
  throw UnsupportedError('Platform does not support web-based download');
}
