import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/config_model.dart';
import 'package:flutter_restaurant/features/checkout/providers/checkout_provider.dart';
import 'package:flutter_restaurant/helper/price_converter_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/utill/color_resources.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:flutter_restaurant/common/widgets/custom_image_widget.dart';
import 'package:provider/provider.dart';
import 'payment_method_bottom_sheet_widget.dart';

class PaymentDetailsWidget extends StatelessWidget {
  final double total;
  const PaymentDetailsWidget({super.key,  required this.total});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutProvider>(builder: (context, checkoutProvider, _) {
      bool showPayment = checkoutProvider.selectedPaymentMethod != null || (checkoutProvider.selectedOfflineValue != null && checkoutProvider.isOfflineSelected);
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.5), blurRadius: Dimensions.radiusDefault)],
        ),
        padding:  const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(getTranslated('payment_method', context)!, style: rubikBold.copyWith(
              fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefault,
              fontWeight: ResponsiveHelper.isDesktop(context) ? FontWeight.w700 : FontWeight.w600,
            )),

            TextButton(
              onPressed: ()=> ResponsiveHelper.showDialogOrBottomSheet(context, PaymentMethodBottomSheetWidget(totalPrice: total)),
              child: Text(getTranslated('change', context)!, style: rubikBold.copyWith(
                color: ColorResources.getSecondaryColor(context),
                fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeDefault : Dimensions.fontSizeSmall,
              )),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          const Divider(thickness: 0.5),

           if(checkoutProvider.partialAmount != null || !showPayment ) Padding(
             padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
             child: InkWell(
               onTap: ()=> ResponsiveHelper.showDialogOrBottomSheet(context, PaymentMethodBottomSheetWidget(totalPrice: total)),
               child: Row(children: [
                 const Icon(Icons.add_circle_outline, size: Dimensions.paddingSizeLarge),
                 const SizedBox(width: Dimensions.paddingSizeDefault),

                 Text(
                   getTranslated('add_payment_method', context)!,
                   style: rubikSemiBold.copyWith(fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeDefault : Dimensions.fontSizeSmall),
                 ),
               ]),
             ),
           ),

           if(showPayment) SelectedPaymentView(total: checkoutProvider.partialAmount ??  total),

          ]),
      );
    });
  }
}

class SelectedPaymentView extends StatelessWidget {
  const SelectedPaymentView({
    super.key,
    required this.total,
  });

  final double total;

  @override
  Widget build(BuildContext context) {
    final ConfigModel configModel = Provider.of<SplashProvider>(context, listen: false).configModel!;
    final CheckoutProvider checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);

    return  Container(
       decoration: ResponsiveHelper.isDesktop(context) ? BoxDecoration(
         borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
         color: Theme.of(context).cardColor,
         border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.3), width: 1),
       ) : const BoxDecoration(),
       padding: EdgeInsets.symmetric(
         vertical: Dimensions.paddingSizeSmall,
         horizontal: ResponsiveHelper.isDesktop(context) ? Dimensions.radiusDefault : 0,
       ),

       child: Column(children: [
         Row(children: [
             checkoutProvider.selectedOfflineMethod != null ? Image.asset(
               Images.offlinePayment,
               width: 20, height: 20,
             ) : checkoutProvider.selectedPaymentMethod?.type == 'online'? CustomImageWidget(
               height: Dimensions.paddingSizeLarge,
               image: '${configModel.baseUrls?.getWayImageUrl}/${checkoutProvider.paymentMethod?.getWayImage}',
             ) : Image.asset(
               checkoutProvider.selectedPaymentMethod?.type == 'cash_on_delivery' ? Images.cashOnDelivery : Images.walletPayment,
               width: 20, height: 20, color: Theme.of(context).secondaryHeaderColor,
             ),

             const SizedBox(width: Dimensions.paddingSizeSmall),

             Expanded(child: Text(checkoutProvider.selectedOfflineMethod != null ? '${
                 getTranslated('pay_offline', context)}   (${checkoutProvider.selectedOfflineMethod?.methodName})' : checkoutProvider.selectedPaymentMethod!.getWayTitle ?? '',
               style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
             )),

             Text(
               PriceConverterHelper.convertPrice(total), textDirection: TextDirection.ltr,
               style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
             )

           ]),

        if(checkoutProvider.selectedOfflineValue != null) Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeExtraLarge),
          child: Column(children: checkoutProvider.selectedOfflineValue!.map((method) => Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
            child: Row(children: [
               Flexible(child: Text(method.keys.single, style: rubikRegular, maxLines: 1, overflow: TextOverflow.ellipsis)),
               const SizedBox(width: Dimensions.paddingSizeSmall),

               Flexible(child: Text(' :  ${method.values.single}', style: rubikRegular, maxLines: 1, overflow: TextOverflow.ellipsis)),
             ]),
          )).toList()),
        ),
       ]),
    );
  }
}
