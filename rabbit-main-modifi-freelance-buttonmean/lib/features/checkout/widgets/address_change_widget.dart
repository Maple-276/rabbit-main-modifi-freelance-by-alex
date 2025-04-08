import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/config_model.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_bottom_sheet_header.dart';
import 'package:flutter_restaurant/common/widgets/custom_dialog_shape_widget.dart';
import 'package:flutter_restaurant/features/address/domain/models/address_model.dart';
import 'package:flutter_restaurant/features/address/providers/location_provider.dart';
import 'package:flutter_restaurant/features/checkout/providers/checkout_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/helper/checkout_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class AddressChangeWidget extends StatelessWidget {
  const AddressChangeWidget({
    super.key, required this.currentBranch, required this.kmWiseCharge, required this.amount,
  });

  final Branches? currentBranch;
  final bool kmWiseCharge;
  final double? amount;

  @override
  Widget build(BuildContext context) {
    final CheckoutProvider checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    final double height = MediaQuery.sizeOf(context).height;

    return Consumer<LocationProvider>(builder: (context, locationProvider, _) {
      return CustomDialogShapeWidget(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge, vertical: Dimensions.paddingSizeLarge),
        maxHeight: height * 0.6, child: Column(children: [

        locationProvider.addressList == null ? _AddressShimmerWidget(
          enabled: locationProvider.addressList == null,
        ) : (locationProvider.addressList?.isNotEmpty ?? false) ? Expanded(child: Column(children: [

          CustomBottomSheetHeader(title: getTranslated('delivery_address', context)!),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Expanded(child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: locationProvider.addressList!.length,
            itemBuilder: (context, index) {
              bool isAvailable = splashProvider.deliveryInfoModel?.deliveryChargeSetup?.deliveryChargeType == 'distance' ? CheckOutHelper.isAddressInCoverage(
                  currentBranch, locationProvider.addressList![index]) : true;

              return Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                child: Material(
                  color: index == checkoutProvider.addressIndex ? Theme.of(context).cardColor : Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    side: index == checkoutProvider.addressIndex ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: isAvailable ? (){
                      Navigator.of(context).pop();
                      print('---------------------$index');
                      CheckOutHelper.selectDeliveryAddress(
                        splashProvider: splashProvider,
                        isAvailable: isAvailable, index: index, configModel: splashProvider.configModel!,
                        locationProvider: locationProvider, checkoutProvider: checkoutProvider,
                        fromAddressList: true,
                      );

                    } : null,
                    child: Stack(children: [
                      Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall), child: Row(children: [
                        Padding(
                          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                          child: Icon(
                            locationProvider.addressList![index].addressType == 'Home' ? Icons.home_outlined
                                : locationProvider.addressList![index].addressType == 'Workplace' ? Icons.work_outline : Icons.list_alt_outlined,
                            color: index == checkoutProvider.addressIndex ? Theme.of(context).primaryColor
                                : Theme.of(context).textTheme.bodyLarge!.color,
                            size: Dimensions.paddingSizeLarge,
                          ),
                        ),

                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(locationProvider.addressList![index].addressType!, style: rubikSemiBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                            )),
                            const SizedBox(height: Dimensions.paddingSizeSmall),

                            Text(locationProvider.addressList![index].address!, style: rubikRegular, /*maxLines: 1, overflow: TextOverflow.ellipsis*/),
                          ]),
                        ),

                        index == checkoutProvider.addressIndex ? Align(
                          alignment: Alignment.topRight,
                          child: Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                        ) : const SizedBox(),
                      ])),

                      !isAvailable ? Positioned(
                        top: 0, left: 0, bottom: 0, right: 0,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black.withOpacity(0.6)),
                          child: Text(
                            getTranslated('out_of_coverage_for_this_branch', context)!,
                            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: rubikRegular.copyWith(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ) : const SizedBox(),
                    ]),
                  ),
                ),
              );
            },
          )),


          if(locationProvider.addressList?.isNotEmpty ?? false) TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              RouterHelper.getAddAddressRoute('checkout', 'add', AddressModel());
              await locationProvider.initAddressList();

              CheckOutHelper.selectDeliveryAddressAuto(
                isLoggedIn: true,
                orderType: checkoutProvider.orderType,
                lastAddress: null,
              );

              await locationProvider.updateAddressIndex(0, true);

            },
            icon: Icon(Icons.add_circle_outline_sharp, color: Theme.of(context).primaryColor),
            label: Text(getTranslated('add_new_address', context)!, style: rubikSemiBold.copyWith()),
          )])) : Expanded(child: SingleChildScrollView(child: Column( children: [

            Text(getTranslated("select_address", context)!, style: rubikSemiBold.copyWith(
                fontSize : Dimensions.fontSizeLarge
            )),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            const CustomAssetImageWidget(Images.selectAddressBottomSheetIcon,
                height: 180, width: 220, fit: BoxFit.contain
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge, width: Dimensions.webScreenWidth),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.fontSizeExtraSmall),
              child: Text(
                getTranslated('you_dont_have_any_saved_address_yet', context)!,
                style: rubikRegular.copyWith(color: Theme.of(context).hintColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            TextButton.icon(
              onPressed: () {
                context.pop();
                RouterHelper.getAddAddressRoute('address', 'add', AddressModel());
              },
              icon: Icon(Icons.add_circle_outline_sharp, color: Theme.of(context).primaryColor),
              label: Text(getTranslated('add_new_address', context)!, style: rubikSemiBold.copyWith(
                color: Theme.of(context).primaryColor,
              )),
            ),

          ]),
        )),
      ]),
      );
    });
  }
}

class _AddressShimmerWidget extends StatelessWidget {
  const _AddressShimmerWidget({
    required this.enabled,
  });

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer(enabled: enabled, child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).hintColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
        child: Row(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall), child: Container(
            width: Dimensions.paddingSizeLarge, height: Dimensions.paddingSizeLarge,
            color: Theme.of(context).hintColor.withOpacity(0.3),
          )),

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 200, height: Dimensions.paddingSizeLarge,
                color: Theme.of(context).hintColor.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              ),

              Container(
                width: 150, height: Dimensions.paddingSizeLarge,
                color: Theme.of(context).hintColor.withOpacity(0.3),
              ),
            ]),
          ),
        ]),
      )),
    );
  }
}