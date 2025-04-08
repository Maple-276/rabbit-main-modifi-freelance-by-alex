import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/product_model.dart';
import 'package:flutter_restaurant/features/profile/providers/profile_provider.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/wishlist/providers/wishlist_provider.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:provider/provider.dart';

import '../../helper/custom_snackbar_helper.dart';

class WishButtonWidget extends StatelessWidget {
  final Product? product;
  final EdgeInsetsGeometry edgeInset;
  const WishButtonWidget({super.key, required this.product, this.edgeInset = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {

    return Consumer<WishListProvider>(builder: (context, wishList, child) {
      return Padding(padding: edgeInset, child: Material(
        color: Theme.of(context).primaryColor.withOpacity(wishList.wishIdList.contains(product!.id) ? 1 : 0.2),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: ()=> _onTapWishButton(context),
          child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: const Icon(Icons.favorite, color: Colors.white, size: Dimensions.paddingSizeDefault),
          ),
        ),
      ));
    });
  }

  void _onTapWishButton(BuildContext context, ){
    final ProfileProvider profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final WishListProvider wishListProvider = Provider.of<WishListProvider>(context, listen: false);

    if(Provider.of<AuthProvider>(context, listen: false).isLoggedIn()) {
      List<int?> productIdList =[];
      productIdList.add(product!.id);

      if(wishListProvider.wishIdList.contains(product?.id)) {
        wishListProvider.removeFromWishList(product!, context, (){
          profileProvider.getUserInfo(true);
        });
      }else {
        wishListProvider.addToWishList(product!,context, (){
          profileProvider.getUserInfo(true);
        });
      }
    }else{
      showCustomSnackBarHelper(getTranslated('now_you_are_in_guest_mode', context), type: SnackBarType.info);
    }

  }
}
