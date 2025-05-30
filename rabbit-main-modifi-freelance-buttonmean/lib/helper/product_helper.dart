import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/cart_model.dart';
import 'package:flutter_restaurant/common/models/product_model.dart';
import 'package:flutter_restaurant/features/home/widgets/cart_bottom_sheet_widget.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/helper/date_converter_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/main.dart';

class ProductHelper{
  static bool isProductAvailable({required Product product})=>
      product.availableTimeStarts != null && product.availableTimeEnds != null
          ? DateConverterHelper.isAvailable(product.availableTimeStarts!, product.availableTimeEnds!) : false;

   static void addToCart({required int cartIndex, required Product product}) {
     // Parameter validation
     if (product.id == null) {
       debugPrint('Error: product without ID cannot be added to cart');
       return;
     }
     
     // Verify that the context is available and mounted
     final context = Get.context;
     if (context == null) {
       debugPrint('Error: addToCart could not get a valid context');
       return;
     }
     
     try {
       // Show dialog or bottom sheet
       Future.microtask(() {
         try {
           ResponsiveHelper.showDialogOrBottomSheet(context, CartBottomSheetWidget(
             product: product,
             fromSetMenu: true,
             callback: (CartModel cartModel) {
               // Verify context and show notification in a Future to avoid unmounted widget issues
               Future.microtask(() {
                 try {
                   final notificationContext = Get.context;
                   if (notificationContext != null) {
                     showCustomSnackBarHelper(
                       getTranslated('added_to_cart', notificationContext), 
                       isError: false, 
                       type: SnackBarType.cart, 
                       showProgressBar: true
                     );
                   }
                 } catch(e) {
                   debugPrint('Error showing cart notification: $e');
                 }
               });
             },
           ));
         } catch (dialogError) {
           debugPrint('Error showing cart dialog: $dialogError');
         }
       });
     } catch (e) {
       debugPrint('Critical error in addToCart: $e');
     }
  }

  static ({List<Variation>? variatins, double? price}) getBranchProductVariationWithPrice(Product? product){

    List<Variation>? variationList;
    double? price;

    if(product?.branchProduct != null && (product?.branchProduct?.isAvailable ?? false)) {
      variationList = product?.branchProduct?.variations;
      price = product?.branchProduct?.price;

    }else{
      variationList = product?.variations;
      price = product?.price;
    }

    return (variatins: variationList, price: price);
  }


}