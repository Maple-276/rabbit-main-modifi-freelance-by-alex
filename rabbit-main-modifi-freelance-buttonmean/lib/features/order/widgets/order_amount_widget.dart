import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/custom_divider_widget.dart';
import 'package:flutter_restaurant/features/order/domain/models/order_model.dart';
import 'package:flutter_restaurant/features/order/providers/order_provider.dart';
import 'package:flutter_restaurant/features/order/widgets/button_widget.dart';
import 'package:flutter_restaurant/features/order/widgets/item_view_widget.dart';
import 'package:flutter_restaurant/helper/price_converter_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';

class OrderAmountWidget extends StatefulWidget {
  final double itemsPrice;
  final  double tax;
  final double addOns;
  final double subTotal;
  final double discount;
  final double extraDiscount;
  final  double? deliveryCharge;
  final double total;
  final String? phoneNumber;

  const OrderAmountWidget({
    super.key, required this.itemsPrice, required this.tax,
    required this.addOns, required this.discount, required this.extraDiscount,
    this.deliveryCharge, required this.total, required this.subTotal, required this.phoneNumber,
  });

  @override
  State<OrderAmountWidget> createState() => _OrderAmountWidgetState();
}

class _OrderAmountWidgetState extends State<OrderAmountWidget> {
  List<OrderPartialPayment> paymentList = [];

  @override
  void initState() {
    final OrderProvider orderProvider = Provider.of<OrderProvider>(context, listen: false);
    if(orderProvider.trackModel?.orderPartialPayments != null && orderProvider.trackModel!.orderPartialPayments!.isNotEmpty){
      paymentList = [];
      paymentList.addAll(orderProvider.trackModel!.orderPartialPayments!);

      if(orderProvider.trackModel!.paymentStatus == 'partial_paid'){
        paymentList.add(OrderPartialPayment(
          paidAmount: 0, paidWith: orderProvider.trackModel?.paymentMethod,
          dueAmount: orderProvider.trackModel!.orderPartialPayments!.first.dueAmount,
        ));
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final OrderProvider orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Column(children: [

      if(ResponsiveHelper.isDesktop(context))
        Text(getTranslated('cost_summery', context)!, style: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge)),

      // Container(
      //   decoration: BoxDecoration(
      //     color: Theme.of(context).cardColor,
      //     borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      //     boxShadow: ResponsiveHelper.isDesktop(context) ? null
      //         : [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.5), blurRadius: 5, spreadRadius: 1, offset: const Offset(2, 2))],
      //   ),
      //   padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault),
      //   margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      //   child: Column(mainAxisSize: MainAxisSize.min, children: [
      //
      //
      //
      //     // const Padding(
      //     //   padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      //     //   child: CustomDividerWidget(),
      //     // ),
      //
      //     // ItemViewWidget(
      //     //   title: getTranslated('subtotal', context)!,
      //     //   subTitle: PriceConverterHelper.convertPrice(widget.subTotal),
      //     //   style: rubikMedium,
      //     // ),
      //
      //   ]),
      // ),

      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: ResponsiveHelper.isDesktop(context) ? null
              : [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.5), blurRadius: 5, spreadRadius: 1, offset: const Offset(2, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault),
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
        child: Column(children: [

          ItemViewWidget(
            title: getTranslated('items_price', context)!,
            subTitle: PriceConverterHelper.convertPrice(widget.itemsPrice),
          ),


          ItemViewWidget(
            title: getTranslated('addons', context)!,
            subTitle: '(+) ${PriceConverterHelper.convertPrice(widget.addOns)}',
          ),

          ItemViewWidget(
            title: getTranslated('discount', context)!,
            subTitle: '(-) ${PriceConverterHelper.convertPrice(widget.discount)}',
          ),


          ItemViewWidget(
            title: getTranslated('tax', context)!,
            subTitle: '(+) ${PriceConverterHelper.convertPrice(widget.tax)}',
          ),

          ///....Extra discount..
          if(widget.extraDiscount > 0) Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ItemViewWidget(
              title: getTranslated('extra_discount', context)!,
              subTitle: '(-) ${PriceConverterHelper.convertPrice(widget.extraDiscount)}',
              style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
          ),

          ItemViewWidget(
            title: getTranslated('coupon_discount', context)!,
            subTitle: '(-) ${PriceConverterHelper.convertPrice(orderProvider.trackModel?.couponDiscountAmount ?? 0)}',
          ),

          ItemViewWidget(
            title: getTranslated('delivery_fee', context)!,
            subTitle: '(+) ${PriceConverterHelper.convertPrice(widget.deliveryCharge)}',
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            child: CustomDividerWidget(),
          ),

          ItemViewWidget(
            title: getTranslated('total_amount', context)!,
            subTitle: PriceConverterHelper.convertPrice(widget.total),
            style: rubikSemiBold.copyWith(color: Theme.of(context).primaryColor),
            subtitleStyle: rubikSemiBold.copyWith(color: Theme.of(context).primaryColor),
          ),

          orderProvider.trackModel != null
          && orderProvider.trackModel!.orderPartialPayments != null
          && orderProvider.trackModel!.orderPartialPayments!.isNotEmpty
          ?  Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            child: DottedBorder(
              dashPattern: const [8, 4],
              strokeWidth: 1.1,
              borderType: BorderType.RRect,
              color: Theme.of(context).primaryColor,
              radius: const Radius.circular(Dimensions.radiusDefault),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.02),
                ),
                padding: const EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeSmall, vertical: 1),
                child: Column(children: paymentList.map((payment) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                    Text(
                      "${getTranslated(payment.paidAmount! > 0
                          ? 'paid_amount' : 'due_amount', context)} (${getTranslated('${payment.paidWith}', context)})",
                      style: rubikRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                      overflow: TextOverflow.ellipsis,
                    ),

                    Text(
                      PriceConverterHelper.convertPrice(payment.paidAmount! > 0 ? payment.paidAmount : payment.dueAmount),
                      style: rubikRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                    ),

                  ]),
                )).toList()),
              ),
            ),
          ) : const SizedBox(),

        ]),
      ),

      if(ResponsiveHelper.isDesktop(context))  ButtonWidget(phoneNumber: widget.phoneNumber),

    ]);
  }
}