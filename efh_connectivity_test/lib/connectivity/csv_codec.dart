/// A minimal RFC 4180 CSV codec, compatible with the fields used by the
/// connectivity tool: comma separators, double-quoted fields and `""` escapes.
library;

/// Parses CSV [content] into rows of fields.
///
/// A trailing newline does not produce an extra empty row, matching the Go
/// `encoding/csv` reader.
List<List<String>> parseCsv(String content) {
  var text = content;
  if (text.startsWith('\uFEFF')) {
    text = text.substring(1);
  }

  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;

  while (i < text.length) {
    final char = text[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field.write(char);
      i++;
      continue;
    }
    if (char == '"') {
      inQuotes = true;
      i++;
      continue;
    }
    if (char == ',') {
      row.add(field.toString());
      field.clear();
      i++;
      continue;
    }
    if (char == '\r' || char == '\n') {
      if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
        i++;
      }
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
      i++;
      continue;
    }
    field.write(char);
    i++;
  }

  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

/// Encodes a single CSV row, terminated by `\n`.
String encodeCsvRow(List<String> fields) {
  final buffer = StringBuffer();
  for (var i = 0; i < fields.length; i++) {
    if (i > 0) {
      buffer.write(',');
    }
    buffer.write(_encodeField(fields[i]));
  }
  buffer.write('\n');
  return buffer.toString();
}

String _encodeField(String field) {
  final needsQuotes =
      field.contains(',') ||
      field.contains('"') ||
      field.contains('\r') ||
      field.contains('\n') ||
      field.startsWith(' ');
  if (!needsQuotes) {
    return field;
  }
  return '"${field.replaceAll('"', '""')}"';
}
