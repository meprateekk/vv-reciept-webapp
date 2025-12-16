import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;

class DownloadHelper {
  static Future<void> saveAndLaunchFile(List<int> bytes, String fileName) async {
    // --------------------------------------------------
    // 1. AGAR APP WEB (BROWSER) PAR HAI
    // --------------------------------------------------
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download = fileName; // Laptop k liye ye file name suggest karega

      // Mobile Web Detection Logic (Simple Check)
      final userAgent = html.window.navigator.userAgent.toString().toLowerCase();
      final isMobileWeb = userAgent.contains('iphone') || userAgent.contains('android');

      if (isMobileWeb) {
        // Mobile par New Tab me kholo taaki App band na ho
        anchor.target = '_blank';
      }

      html.document.body?.children.add(anchor);
      anchor.click();

      // Cleanup
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      return;
    }

    // --------------------------------------------------
    // 2. AGAR APP MOBILE (APK/IOS APP) PAR HAI
    // --------------------------------------------------
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);
    } catch (e) {
      print("Error saving file: $e");
    }
  }
}