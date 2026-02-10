String toEasternArabicDigits(int value) {
  final normalized = value.abs().toString();
  final buffer = StringBuffer();

  for (final codeUnit in normalized.codeUnits) {
    if (codeUnit >= 0x30 && codeUnit <= 0x39) {
      buffer.writeCharCode(0x0660 + (codeUnit - 0x30));
      continue;
    }
    buffer.writeCharCode(codeUnit);
  }

  return buffer.toString();
}

String formatAyahEndingMarker(int ayahNumber) {
  if (ayahNumber <= 0) {
    return '';
  }
  return '\u06DD${toEasternArabicDigits(ayahNumber)}';
}
