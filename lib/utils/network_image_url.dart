/// Guards [Image.network] / [NetworkImage]: rejects empty strings, whitespace-only,
/// and URIs without a usable http(s) host (avoids `NetworkImage("")` and `https://` alone).
String? sanitizedNetworkImageUrl(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  final normalized = (t.startsWith('http://') || t.startsWith('https://'))
      ? t
      : 'https://$t';
  final uri = Uri.tryParse(normalized);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (!uri.hasAuthority || uri.host.isEmpty) return null;
  return normalized;
}
