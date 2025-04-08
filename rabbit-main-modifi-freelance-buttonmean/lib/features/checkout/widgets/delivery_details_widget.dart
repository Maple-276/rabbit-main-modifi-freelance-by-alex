import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/config_model.dart';
import 'package:flutter_restaurant/features/address/domain/models/address_model.dart';
import 'package:flutter_restaurant/features/address/providers/location_provider.dart';
import 'package:flutter_restaurant/features/cart/widgets/delivery_option_widget.dart';
import 'package:flutter_restaurant/features/checkout/domain/enum/delivery_type_enum.dart';
import 'package:flutter_restaurant/features/checkout/providers/checkout_provider.dart';
import 'package:flutter_restaurant/features/checkout/widgets/address_change_widget.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/helper/checkout_helper.dart';
import 'package:flutter_restaurant/helper/price_converter_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/color_resources.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';

import '../../../common/models/delivery_info_model.dart';

class DeliveryDetailsWidget extends StatelessWidget {
  const DeliveryDetailsWidget({
    super.key,
    required this.currentBranch,
    required this.kmWiseCharge,
    required this.deliveryCharge, this.amount,
    required this.dropdownKey,
  });

  final Branches? currentBranch;
  final bool kmWiseCharge;
  final double? deliveryCharge;
  final double? amount;
  final GlobalKey dropdownKey;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final ConfigModel? configModel = Provider.of<SplashProvider>(context, listen: false).configModel;
    final TextEditingController searchController = TextEditingController();

    return Consumer<LocationProvider>(
        builder: (context, locationProvider, _) {
          final CheckoutProvider checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
          final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

          AddressModel? deliveryAddress = CheckOutHelper.getDeliveryAddress(
            addressList: locationProvider.addressList,
            selectedAddress: checkoutProvider.addressIndex == -1 ? null : locationProvider.addressList?[checkoutProvider.addressIndex],
            lastOrderAddress: null,
          );
          print('------------------index---${checkoutProvider.addressIndex == -1 ? null : locationProvider.addressList?[checkoutProvider.addressIndex]}');


          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.5), blurRadius: Dimensions.radiusDefault)],
            ),
            padding:  const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if(checkoutProvider.orderType == OrderType.delivery)...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(getTranslated('deliver_to', context)!, style: rubikBold.copyWith(
                    fontSize: isDesktop ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefault,
                    fontWeight: isDesktop ? FontWeight.w700 : FontWeight.w600,
                  )),

                  TextButton(
                    onPressed: () => ResponsiveHelper.showDialogOrBottomSheet(context,
                      AddressChangeWidget(
                        amount: amount,
                        currentBranch: currentBranch,
                        kmWiseCharge: kmWiseCharge,
                      ),
                    ),
                    child: Text(deliveryAddress == null ? getTranslated('add_address', context)! : getTranslated('change', context)!, style: rubikBold.copyWith(
                      color: ColorResources.getSecondaryColor(context),
                    )),
                  ),
                ]),
                SizedBox(height: isDesktop ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall),

                deliveryAddress == null ? Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Text(getTranslated('no_contact_info_added', context)!, style: rubikRegular.copyWith(color: Theme.of(context).colorScheme.error)),
                  ]),
                ) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  _ContactItemWidget(
                    icon: deliveryAddress.addressType == 'Home'
                        ? Icons.home_outlined : deliveryAddress.addressType == 'Workplace'
                        ? Icons.work_outline
                        : Icons.list_alt_outlined,
                    title: getTranslated(deliveryAddress.addressType ?? '', context),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  _ContactItemWidget(icon: Icons.person, title: deliveryAddress.contactPersonName ?? ''),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  _ContactItemWidget(icon: Icons.call, title: deliveryAddress.contactPersonNumber ?? ''),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  const Divider(height: Dimensions.paddingSizeDefault, thickness: 0.5),

                  Text(deliveryAddress.address ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: rubikRegular),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Row(mainAxisAlignment: MainAxisAlignment.start,children: [
                    if(deliveryAddress.houseNumber != null) Flexible(
                      child: Text(
                        '${getTranslated('house', context)} - ${deliveryAddress.houseNumber}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: rubikRegular,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    if(deliveryAddress.floorNumber != null) Flexible(
                      child: Text(
                        '${getTranslated('floor', context)} - ${deliveryAddress.floorNumber}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: rubikRegular,
                      ),
                    ),
                  ]),
                ]),
                const SizedBox(height: Dimensions.paddingSizeLarge),
              ],

              if(checkoutProvider.orderType != OrderType.takeAway && splashProvider.deliveryInfoModel != null && (splashProvider.deliveryInfoModel!.deliveryChargeByArea?.isNotEmpty ?? false) && splashProvider.deliveryInfoModel?.deliveryChargeSetup?.deliveryChargeType == 'area')...[

                Text(
                  getTranslated('zip_area', context)!,
                  style: rubikSemiBold.copyWith(fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefault),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),


                Consumer<SplashProvider>(
                  builder: (context, splashProvider, child) {


                    return Row(children: [

                      Expanded(child: DropdownButtonHideUnderline(child: DropdownButton2<String>(

                        key: dropdownKey,
                        iconStyleData: IconStyleData(icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).hintColor)),
                        isExpanded: true,
                        hint: Text(
                          getTranslated('search_or_select_zip_code_area', context)!,
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                        ),
                        selectedItemBuilder: (BuildContext context) {
                          return splashProvider.deliveryInfoModel!.deliveryChargeByArea!
                              .map((DeliveryChargeByArea item) {
                            return Row(
                              children: [
                                Text(
                                  item.areaName ?? "",
                                  style: rubikRegular.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                Text(
                                  " (${PriceConverterHelper.convertPrice(item.deliveryCharge?.toDouble() ?? 0)})",
                                  style: rubikRegular.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },

                        items: splashProvider.deliveryInfoModel!.deliveryChargeByArea!.map((DeliveryChargeByArea item) => DropdownMenuItem<String>(
                          value: item.id.toString(),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                            Text(item.areaName ?? "", style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            )),

                            Text(" (${PriceConverterHelper.convertPrice(item.deliveryCharge?.toDouble() ?? 0)})",
                              style: rubikRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).hintColor,
                              ),
                            ),

                          ]),
                        )).toList(),

                        value: locationProvider.selectedAreaID == -1 ? null
                            : splashProvider.deliveryInfoModel!.deliveryChargeByArea!.firstWhere((area) => area.id == locationProvider.selectedAreaID).id.toString(),

                        onChanged: (String? value) {
                          locationProvider.setAreaID(areaID: int.parse(value!));
                          double deliveryCharge;
                          deliveryCharge = CheckOutHelper.getDeliveryCharge(
                            splashProvider : splashProvider,
                            googleMapStatus: configModel!.googleMapStatus!,
                            distance: checkoutProvider.distance,
                            minimumDistanceForFreeDelivery: splashProvider.deliveryInfoModel?.deliveryChargeSetup?.minimumDistanceForFreeDelivery?.toDouble() ?? 0,
                            shippingPerKm: splashProvider.deliveryInfoModel?.deliveryChargeSetup?.deliveryChargePerKilometer?.toDouble() ?? 0,
                            minShippingCharge: splashProvider.deliveryInfoModel?.deliveryChargeSetup?.minimumDeliveryCharge?.toDouble() ?? 0,
                            defaultDeliveryCharge: splashProvider.deliveryInfoModel?.deliveryChargeSetup?.fixedDeliveryCharge?.toDouble() ?? 0,
                            isTakeAway: checkoutProvider.orderType == OrderType.takeAway,
                            areaID : int.parse(value),
                          );
                          checkoutProvider.setDeliveryCharge(deliveryCharge: deliveryCharge);
                        },

                        dropdownSearchData: DropdownSearchData(
                          searchController: searchController,
                          searchInnerWidgetHeight: 50,
                          searchInnerWidget: Container(
                            height: 50,
                            padding: const EdgeInsets.only(
                              top: Dimensions.paddingSizeSmall,
                              left: Dimensions.paddingSizeSmall,
                              right: Dimensions.paddingSizeSmall,
                            ),
                            child: TextFormField(
                              controller: searchController,
                              expands: true,
                              maxLines: null,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                hintText: getTranslated('search_zip_area_name', context)!,
                                hintStyle: const TextStyle(fontSize: Dimensions.fontSizeSmall),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                ),
                              ),
                            ),
                          ),
                          searchMatchFn: (item, searchValue) {
                            DeliveryChargeByArea areaItem = splashProvider.deliveryInfoModel!.deliveryChargeByArea!
                                .firstWhere((element) => element.id.toString() == item.value);
                            return areaItem.areaName?.toLowerCase().contains(searchValue.toLowerCase()) ?? false;
                          },
                        ),
                        buttonStyleData: ButtonStyleData(
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).hintColor),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),),
                          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                        ),

                      ))),


                    ]);
                  }
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
              ],



              Text(getTranslated('delivery_type', context)!, style: rubikBold.copyWith(
                fontSize: isDesktop ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefault,
                fontWeight: isDesktop ? FontWeight.w700 : FontWeight.w600,
              )),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Consumer<CheckoutProvider>(
                  builder: (context, checkoutProvider, _) {
                    if (isDesktop) {
                      return Row(children: [
                        Expanded(
                          child: (splashProvider.configModel?.homeDelivery ?? false) ? DeliveryOptionWidget(
                            value: OrderType.delivery,
                            title: getTranslated('delivery', context)!,
                            deliveryCharge: checkoutProvider.deliveryCharge,
                          ) : Padding(
                            padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall,top: Dimensions.paddingSizeLarge),
                            child: Row(children: [
                              Icon(Icons.remove_circle_outline_sharp,color: Theme.of(context).hintColor,),
                              const SizedBox(width: Dimensions.paddingSizeExtraLarge),

                              Text(getTranslated('home_delivery_not_available', context)!,style: TextStyle(fontSize: Dimensions.fontSizeDefault,color: Theme.of(context).primaryColor)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        if(splashProvider.configModel?.selfPickup ?? false) Expanded(
                          child: DeliveryOptionWidget(
                            value: OrderType.takeAway,
                            title: getTranslated('take_away', context)!,
                            deliveryCharge: checkoutProvider.deliveryCharge,
                          ),
                        ),
                      ]);
                    } else {
                      return Column( children: [
                        (splashProvider.configModel?.homeDelivery ?? false) ? DeliveryOptionWidget(
                          value: OrderType.delivery,
                          title: getTranslated('delivery', context)!,
                          deliveryCharge: checkoutProvider.deliveryCharge,
                        ) : Padding(
                          padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall,top: Dimensions.paddingSizeLarge),
                          child: Row(children: [
                            Icon(Icons.remove_circle_outline_sharp,color: Theme.of(context).hintColor,),
                            const SizedBox(width: Dimensions.paddingSizeExtraLarge),

                            Text(getTranslated('home_delivery_not_available', context)!,style: TextStyle(fontSize: Dimensions.fontSizeDefault,color: Theme.of(context).primaryColor)),
                          ]),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        if(splashProvider.configModel?.selfPickup ?? false) DeliveryOptionWidget(
                          value: OrderType.takeAway,
                          title: getTranslated('take_away', context)!,
                          deliveryCharge: checkoutProvider.deliveryCharge,
                        ),

                      ]);
                    }
                  }
              ),

            ]),
          );
        }
    );
  }
}

class _ContactItemWidget extends StatelessWidget {
  final IconData icon;
  final String? title;
  const _ContactItemWidget({
    required this.icon, this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: Theme.of(context).primaryColor),
      const SizedBox(width: Dimensions.paddingSizeSmall),

      Flexible(child: Text(
        title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: rubikRegular,
      )),
    ]);
  }
}

