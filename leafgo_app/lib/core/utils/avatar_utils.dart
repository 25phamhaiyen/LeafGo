import 'package:flutter/material.dart';
import 'package:leafgo_app/core/constants/api_constants.dart';

/// Normalize avatar path returned from the API into a full URL.
///
/// Handles both relative paths and absolute paths with different IP/hosts
/// by dynamically replacing the host with the configured ApiConstants.baseUrl.
String? normalizeAvatarUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  // If it's a relative path, prepend base URL
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    final baseUrl = ApiConstants.baseUrl;
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '$baseUrl$cleanPath';
  }

  // If it's a full URL, check if it points to backend uploads or local hosts
  try {
    final uri = Uri.parse(url);
    final isLocalHost =
        uri.host == '127.0.0.1' ||
        uri.host == 'localhost' ||
        uri.host == '10.0.2.2';
    final isUploads = uri.path.contains('/uploads/');

    if (isLocalHost || isUploads) {
      final baseUrl = ApiConstants.baseUrl;
      final path = uri.path;
      final cleanPath = path.startsWith('/') ? path : '/$path';
      return '$baseUrl$cleanPath';
    }
  } catch (e) {
    // Fallback if URL parsing fails
  }

  return url;
}

/// Builds a circle avatar image widget with fallback support.
Widget buildAvatarCircle(
  String? avatarUrl, {
  double radius = 20,
  Color backgroundColor = const Color(0xFFE6F7F0),
  IconData placeholderIcon = Icons.person,
  Color placeholderIconColor = const Color(0xFF10B981),
}) {
  final normalizedUrl = normalizeAvatarUrl(avatarUrl);

  return Container(
    width: radius * 2,
    height: radius * 2,
    decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
    clipBehavior: Clip.hardEdge,
    child: normalizedUrl == null
        ? Center(
            child: Icon(
              placeholderIcon,
              size: radius,
              color: placeholderIconColor,
            ),
          )
        : Image.network(
            normalizedUrl,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: radius,
                  height: radius,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  placeholderIcon,
                  size: radius,
                  color: placeholderIconColor,
                ),
              );
            },
          ),
  );
}
