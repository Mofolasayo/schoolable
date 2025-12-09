import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:schoolable/ui/common/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String fallbackInitials;
  final Color? backgroundColor;

  const AppAvatar({
    Key? key,
    this.imageUrl,
    this.radius = 20,
    this.fallbackInitials = 'U',
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    // Check if SVG
    if (imageUrl!.endsWith('.svg') || imageUrl!.contains('/svg')) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: backgroundColor ?? kcPrimaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: SvgPicture.network(
            imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => _buildFallback(),
          ),
        ),
      );
    }

    // Cached Network Image
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      placeholder: (context, url) => Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: backgroundColor ?? kcPrimaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
      ),
      errorWidget: (context, url, error) => _buildFallback(),
      fadeInDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: backgroundColor ?? kcPrimaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          fallbackInitials.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: kcTextColor,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
          ),
        ),
      ),
    );
  }
}
