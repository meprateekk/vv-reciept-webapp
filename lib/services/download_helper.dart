import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';

class DownloadHelper {
  static Future<void> saveAndLaunchFile(List<int> bytes, String fileName) async {
    // --------------------------------------------------
    // 1. AGAR APP WEB (LAPTOP) PAR HAI
    // --------------------------------------------------
    if (kIsWeb) {
      // Web ke liye HTML anchor tag use karenge
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download = fileName;

      html.document.body?.children.add(anchor);
      anchor.click();

      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      return;
    }

    // --------------------------------------------------
    // 2. AGAR APP MOBILE (ANDROID/IOS) PAR HAI
    // --------------------------------------------------
    try {
      // Document directory dhundo
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      // File save karo
      await file.writeAsBytes(bytes, flush: true);

      // File ko open karo (User ko dikhane ke liye)
      await OpenFilex.open(file.path);

    } catch (e) {
      print("Error saving file: $e");
    }
  }
}