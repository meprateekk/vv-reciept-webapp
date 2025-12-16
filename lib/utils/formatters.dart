import 'package:flutter/services.dart';

class CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Har word ka first letter Capital karo
    String newText = newValue.text.split(' ').map((str) {
      if (str.isNotEmpty) {
        return str[0].toUpperCase() + str.substring(1);
      }
      return '';
    }).join(' ');

    return TextEditingValue(
      text: newText,
      selection: newValue.selection,
    );
  }
}