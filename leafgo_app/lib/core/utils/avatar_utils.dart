import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:leafgo_app/core/constants/api_constants.dart';

/// Normalize avatar path returned from the API into a full URL.
///
/// The backend stores relative URLs like `/uploads/avatars/xxx.jpg`.
/// This helper converts them into a full network address for Flutter.
String? normalizeAvatarUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;

  final baseUrl = ApiConstants.baseUrl;

  return '$baseUrl${url.startsWith('/') ? url : '/$url'}';
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
