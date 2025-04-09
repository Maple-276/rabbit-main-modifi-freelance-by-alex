import 'package:flutter/material.dart';
import 'package:flutter_restaurant/features/cart/providers/cart_provider.dart';
import 'package:flutter_restaurant/features/cart/widgets/item_view_widget.dart';
import 'package:flutter_restaurant/features/checkout/domain/enum/delivery_type_enum.dart';
import 'package:flutter_restaurant/features/checkout/providers/checkout_provider.dart';
import 'package:flutter_restaurant/features/coupon/providers/coupon_provider.dart';
import 'package:flutter_restaurant/helper/price_converter_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';

// Convert to StatefulWidget to manage the tax visibility state
class CostSummeryWidget extends StatefulWidget {
  const CostSummeryWidget({
    super.key,
  });

  @override
  State<CostSummeryWidget> createState() => _CostSummeryWidgetState();
}

class _CostSummeryWidgetState extends State<CostSummeryWidget> {
  // State variable to track visibility of optional details (delivery fee, tax)
  bool _showOptionalDetails = false;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Consumer3<CheckoutProvider, CartProvider, CouponProvider>(
      builder: (context, checkoutProvider, cartProvider, couponProvider, _) {
        bool isTakeAway = checkoutProvider.orderType == OrderType.takeAway;

        double itemsPrice = 0;
        double itemDiscount = 0;
        double tax = 0;
        double addOns = 0;
        for (var cartModel in cartProvider.cartList) {
          if (cartModel != null) {
            itemsPrice += (cartModel.price ?? 0) * (cartModel.quantity ?? 0);
            itemDiscount += (cartModel.discountAmount ?? 0) * (cartModel.quantity ?? 0);
            tax += (cartModel.taxAmount ?? 0) * (cartModel.quantity ?? 0);
            if (cartModel.addOnIds != null) {
               for(int index=0; index < cartModel.addOnIds!.length; index++) {
               }
            }
          }
        }
        double couponDiscount = couponProvider.discount ?? 0;
        double deliveryCharge = checkoutProvider.deliveryCharge ?? 0;

        double totalDiscount = itemDiscount + couponDiscount;
        double subTotal = itemsPrice + addOns + tax;
        double total = subTotal - totalDiscount + (isTakeAway ? 0 : deliveryCharge);

        // Determine if there are any optional details to potentially show
        bool hasOptionalDetailsToShow = !isTakeAway || tax >= 0; // Tax always exists (can be 0), delivery fee depends on !isTakeAway

        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Align(alignment: Alignment.center,
                child: Text(getTranslated('cost_summery', context)!, style: rubikBold.copyWith(
                  fontSize: isDesktop ? Dimensions.fontSizeExtraLarge : Dimensions.fontSizeDefault,
                  fontWeight: isDesktop ? FontWeight.w700 : FontWeight.w600,
                )),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              const Divider(thickness: 0.08, color: Colors.black),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              if (totalDiscount > 0) ...[
                ItemViewWidget(
                  title: getTranslated('discount', context)!,
                  subTitle: '(-) ${PriceConverterHelper.convertPrice(totalDiscount)}',
                  titleStyle: rubikMedium,
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
              ],

              if (!isTakeAway && _showOptionalDetails) ...[
                ItemViewWidget(
                  title: getTranslated('delivery_fee', context)!,
                  subTitle: '(+) ${PriceConverterHelper.convertPrice(deliveryCharge)}',
                  titleStyle: rubikMedium,
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
              ],

              if (_showOptionalDetails) ...[
                ItemViewWidget(
                  title: getTranslated('tax', context)!,
                  subTitle: '(+) ${PriceConverterHelper.convertPrice(tax)}',
                  titleStyle: rubikMedium,
                ),
                 const SizedBox(height: Dimensions.paddingSizeSmall),
              ],

              if (hasOptionalDetailsToShow) ...[
                 Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showOptionalDetails = !_showOptionalDetails;
                      });
                    },
                    child: Text(
                      _showOptionalDetails
                          ? getTranslated('hide_details', context)!
                          : getTranslated('show_details', context)!,
                      style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              ],

              const Divider(thickness: 0.08, color: Colors.black),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              ItemViewWidget(
                title: getTranslated('total_amount', context)!,
                subTitle: PriceConverterHelper.convertPrice(total),
                titleStyle: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                subTitleStyle: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
              ),
             const SizedBox(height: Dimensions.paddingSizeDefault),

            ]),
          ),

        ]);
      }
    );
  }
}
