import 'package:flutter/services.dart';

class IpInputFormatter extends TextInputFormatter {
  final RegExp _ipRegExp = RegExp(r'^\d{0,3}(\.\d{0,3}){0,3}$');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (_ipRegExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}