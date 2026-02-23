import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

Future<void> main() async {
  final webDir = Directory('web');
  if (!webDir.existsSync()) {
    print('Error: web directory not found.');
    return;
  }

  // 1. Download sqlite3.wasm
  const wasmUrl =
      'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.1.2/sqlite3.wasm';
  final wasmFile = File(p.join('web', 'sqlite3.wasm'));

  print('Downloading sqlite3.wasm from $wasmUrl...');
  try {
    final response = await http.get(Uri.parse(wasmUrl));
    if (response.statusCode == 200) {
      await wasmFile.writeAsBytes(response.bodyBytes);
      print('Saved sqlite3.wasm');
    } else {
      print('Failed to download sqlite3.wasm: ${response.statusCode}');
    }
  } catch (e) {
    print('Error downloading sqlite3.wasm: $e');
  }

  // 2. We need sqflite_sw.js
  // Since we can't easily compile it, we'll suggest the user to run the command
  // or we can try to find where it might be.
  // Actually, some versions of the package provide it in the build folder if it was ever built.

  print(
      '\nTo fix the web worker error, please try running this command in your terminal:');
  print('dart run sqflite_common_ffi_web:setup');
  print('\nIf that fails due to spaces in the path, try:');
  print('subst Z: "."');
  print('Z:');
  print('dart run sqflite_common_ffi_web:setup');
}
