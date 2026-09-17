/// The accepted input CSV column names, in priority order.
const domainColumns = ['domain', 'host', 'hostname', 'url', 'website'];

/// Returns the index of the first recognized domain column, or -1.
int findDomainColumn(List<String> header) {
  for (var i = 0; i < header.length; i++) {
    final name = header[i].trim().toLowerCase();
    if (domainColumns.contains(name)) {
      return i;
    }
  }
  return -1;
}

/// Lowercases a value and strips its scheme, path and trailing dot.
///
/// Returns an empty string when the value has no usable hostname.
String normalizeHost(String value) {
  var v = value.trim();
  if (v.isEmpty) {
    return '';
  }
  if (!v.contains('://')) {
    v = 'https://$v';
  }
  Uri uri;
  try {
    uri = Uri.parse(v);
  } on FormatException {
    return '';
  }
  final host = uri.host.toLowerCase();
  if (host.isEmpty) {
    return '';
  }
  return host.endsWith('.') ? host.substring(0, host.length - 1) : host;
}
