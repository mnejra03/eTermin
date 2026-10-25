import 'package:flutter/material.dart';

import '../services/api_service.dart';

class SalonImageView extends StatelessWidget {
  const SalonImageView({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final imageUri = ApiService.salonImageUri(imageUrl);
    if (imageUri == null) return _placeholder();

    return Image.network(
      imageUri.toString(),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: const Color(0xFFF1ECF8),
    child: const Center(
      child: Icon(Icons.storefront_rounded, color: Color(0xFF9C27B0), size: 40),
    ),
  );
}
