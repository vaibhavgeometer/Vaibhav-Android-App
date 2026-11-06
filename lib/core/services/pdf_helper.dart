import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class PdfHelper {
  static Future<bool> openAssetPdf(String assetPath, String outputFileName) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$outputFileName');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      final result = await OpenFilex.open(file.path);
      return result.type == ResultType.done;
    } catch (e) {
      return false;
    }
  }
}

