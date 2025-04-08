import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_restaurant/utill/images.dart';

class CustomImageWidget extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final bool isNotification;
  final String placeholder;

  const CustomImageWidget({
    super.key,
    required this.image,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.isNotification = false,
    this.placeholder = '',
  });

  @override
  Widget build(BuildContext context) {
   return Image(
      image: NetworkImage(
        image,
        scale: 1.0,
      ),
      height: height,
      width: width,
      fit: fit,
      frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child; // If the image was loaded synchronously, just display it
        } else {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: frame == null
                ? Image.asset(
              placeholder.isNotEmpty ? placeholder : Images.placeholderImage,
              height: height,
              width: width,
              fit: fit,
            )
                : child,
          );
        }
      },
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        // If there's an error loading the image, show a placeholder
        return Image.asset(
          placeholder.isNotEmpty ? placeholder : Images.placeholderImage,
          height: height,
          width: width,
          fit: fit,
        );
      },
    );

  }
}
