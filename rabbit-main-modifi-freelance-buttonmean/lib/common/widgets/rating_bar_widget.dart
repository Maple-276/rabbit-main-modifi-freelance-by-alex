import 'package:flutter/material.dart';
import 'package:flutter_restaurant/utill/color_resources.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/styles.dart';

class RatingBarWidget extends StatelessWidget {
  final double rating;
  final double size;

  const RatingBarWidget({super.key, required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {

    return rating > 0 ? Row(mainAxisSize: MainAxisSize.min, children: [

      Text(rating.toStringAsFixed(1), style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
      const SizedBox(width: Dimensions.paddingSizeExtraSmall),

      Icon(Icons.star, color: ColorResources.getSecondaryColor(context), size: size),

    ]) : const SizedBox();
  }
}

