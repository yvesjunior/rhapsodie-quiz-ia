import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/core/constants/assets_constants.dart';

class QImage extends StatelessWidget {
  const QImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.color,
    super.key,
    this.cacheHeight,
    this.cacheWidth,
    this.radius,
  });

  const QImage.circular({
    required this.imageUrl,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.color,
    super.key,
    this.cacheHeight,
    this.cacheWidth,
  }) : radius = 9999;

  final String imageUrl;

  final Alignment alignment;
  final BoxFit fit;
  final Color? color;
  final double? height;
  final double? width;
  final double? cacheHeight;
  final double? cacheWidth;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    const errorImg = Assets.placeholder;
    var image = imageUrl.isEmpty ? errorImg : imageUrl;

    // Handle avatar filenames stored in DB (e.g., "1.svg", "2.svg", "1", "2")
    // or any local file that doesn't have a proper path
    // These need to be converted to full asset path
    final isLocalFile = !image.startsWith('http') && 
                        !image.startsWith('assets/') &&
                        !image.startsWith('/');
    
    if (isLocalFile) {
      // Check if it's a numeric avatar filename
      final isAvatarFile = RegExp(r'^\d+\.svg$').hasMatch(image) || 
                           RegExp(r'^\d+$').hasMatch(image);
      if (isAvatarFile) {
        final fileName = image.endsWith('.svg') ? image : '$image.svg';
        image = Assets.profile(fileName);
      } else if (image.endsWith('.svg') || image.endsWith('.png') || image.endsWith('.jpg')) {
        // For other local filenames, try profile path
        image = Assets.profile(image);
      }
    }

    final isNetworked = image.startsWith('http');
    final isSvg = image.endsWith('.svg');

    final colorFilter = color != null
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null;

    final errorWidget = Image.asset(
      errorImg,
      width: width,
      height: height,
      fit: fit,
    );

    final child = switch ((isNetworked, isSvg)) {
      //
      (false, false) => Image.asset(
        image,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, o, s) => errorWidget,
      ),
      //
      (false, true) => SvgPicture.asset(
        image,
        width: width,
        height: height,
        colorFilter: colorFilter,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, o, s) => errorWidget,
      ),
      //
      (true, false) => CachedNetworkImage(
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        imageUrl: image,
        errorWidget: (_, s, o) => errorWidget,
      ),
      //
      (true, true) => SvgPicture.network(
        image,
        width: width,
        height: height,
        colorFilter: colorFilter,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, o, s) => errorWidget,
      ),
    };

    return SizedBox(
      width: width,
      height: height,
      child: radius != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius!),
              child: child,
            )
          : child,
    );
  }
}
