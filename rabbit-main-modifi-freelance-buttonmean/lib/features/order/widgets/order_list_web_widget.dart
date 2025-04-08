import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/no_data_widget.dart';
import 'package:flutter_restaurant/features/order/domain/models/order_model.dart';
import 'package:flutter_restaurant/features/order/providers/order_provider.dart';
import 'package:flutter_restaurant/features/order/widgets/order_item_web_widget.dart';
import 'package:flutter_restaurant/features/order/widgets/order_shimmer_widget.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';

class OrderListWebWidget extends StatelessWidget {
  final bool isRunning;
  const OrderListWebWidget({super.key, required this.isRunning});

  @override
  Widget build(BuildContext context) {

    // final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: Consumer<OrderProvider>(
        builder: (context, order, index) {
          List<OrderModel>? orderList;
          if(order.runningOrderList != null) {
            orderList = isRunning ? order.runningOrderList : order.historyOrderList;
          }

          return orderList != null ? orderList.isNotEmpty ? RefreshIndicator(
            onRefresh: () async {
              await Provider.of<OrderProvider>(context, listen: false).getOrderList(context);
            },
            backgroundColor: Theme.of(context).primaryColor,
            color: Theme.of(context).secondaryHeaderColor,
            child: Column(children: [

              Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).indicatorColor.withOpacity(0.05),
                  border: Border.all(color: Theme.of(context).indicatorColor.withOpacity(0.1)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.radiusDefault),
                    topRight: Radius.circular(Dimensions.radiusDefault),
                  ),
                ),
                child: Row(children: [
                  Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(getTranslated('order_details', context)!, style: rubikSemiBold),
                      const SizedBox(width: 50),
                    ]),
                  ])),

                  Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(getTranslated('quantity', context)!, style: rubikSemiBold),
                  ])),

                  Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(getTranslated('estimated_arrival', context)!, style: rubikSemiBold),
                  ])),

                  Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(getTranslated('total', context)!, style: rubikSemiBold),
                  ])),

                  Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(getTranslated('action', context)!, style: rubikSemiBold),
                  ])),
                ]),
              ),

              SizedBox(height: 400, child: ListView.builder(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                itemCount: orderList.length,
                itemBuilder: (context, index) => SizedBox(height: 100, child: OrderItemWebWidget(
                  orderProvider: order, isRunning: isRunning, orderItem: orderList![index],
                )),
              )),

            ]),
          ) : const Center(child: NoDataWidget(isOrder: true)) : const OrderShimmerWidget();
        },
      ),
    );
  }
}
