import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/no_data_widget.dart';
import 'package:flutter_restaurant/features/order/domain/models/order_model.dart';
import 'package:flutter_restaurant/features/order/providers/order_provider.dart';
import 'package:flutter_restaurant/features/order/widgets/order_item_widget.dart';
import 'package:flutter_restaurant/features/order/widgets/order_shimmer_widget.dart';
import 'package:flutter_restaurant/helper/date_converter_helper.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:provider/provider.dart';

class OrderListWidget extends StatelessWidget {
  final bool isRunning;
  const OrderListWidget({super.key, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, order, index) {
        List<OrderModel>? orderList;
        List<DateTime> dateTimeList = [];

        if(order.runningOrderList != null) {
          orderList = isRunning ? order.runningOrderList : order.historyOrderList;
        }

        return orderList != null ? orderList.isNotEmpty ? RefreshIndicator(
          onRefresh: () async {
            await Provider.of<OrderProvider>(context, listen: false).getOrderList(context);
          },
          backgroundColor: Theme.of(context).primaryColor,
          color: Theme.of(context).secondaryHeaderColor,
          child: SingleChildScrollView(
            child: Column(children: [
            
              Center(
                child: SizedBox(
                  width: Dimensions.webScreenWidth,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    itemCount: orderList.length,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {

                      DateTime originalDateTime = DateConverterHelper.getDateOnly(orderList![index].deliveryDate!);
                      DateTime convertedDate = DateTime(originalDateTime.year, originalDateTime.month, originalDateTime.day);
                      bool addTitle = false;

                      if(!dateTimeList.contains(convertedDate)) {
                        addTitle = true;
                        dateTimeList.add(convertedDate);
                      }
                      return OrderItemWidget(orderProvider: order, isRunning: isRunning, orderItem: orderList[index], isAddDate: addTitle);
                    },
                  ),
                ),
              ),

            ]),
          ),
        ) : const Center(child: NoDataWidget(isOrder: true)) : const OrderShimmerWidget();
      },
    );
  }
}
