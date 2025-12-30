import 'dart:io';
import 'dart:typed_data'; // <--- YE IMPORT JARURI HAI (Uint8List ke liye)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;
import 'package:printing/printing.dart';

class DownloadHelper {
  // Yaha List<int> aa raha hai
  static Future<void> saveAndLaunchFile(List<int> bytes, String fileName) async {

    // --------------------------------------------------
    // 1. AGAR APP WEB PAR HAI
    // --------------------------------------------------
    if (kIsWeb) {
      final userAgent = html.window.navigator.userAgent.toString().toLowerCase();
      final isMobileWeb = userAgent.contains('iphone') || userAgent.contains('android');

      if (isMobileWeb) {
        // MOBILE WEB: Printing Package use karenge
        await Printing.layoutPdf(
          // ERROR FIX: Yaha humne convert kar diya Uint8List me
          onLayout: (_) => Uint8List.fromList(bytes),
          name: fileName,
        );
      } else {
        // LAPTOP: Direct Download
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
      }
      return;
    }

    // --------------------------------------------------
    // 2. AGAR APP MOBILE APP (APK) HAI
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