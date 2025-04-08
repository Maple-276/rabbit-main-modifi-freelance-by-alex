import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/product_model.dart';
import 'package:flutter_restaurant/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/footer_widget.dart';
import 'package:flutter_restaurant/common/widgets/no_data_widget.dart';
import 'package:flutter_restaurant/features/cart/providers/cart_provider.dart';
import 'package:flutter_restaurant/features/cart/widgets/item_view_widget.dart';
import 'package:flutter_restaurant/features/cart/widgets/add_more_item_button_widget.dart';
import 'package:flutter_restaurant/features/cart/widgets/cart_list_widget.dart';
import 'package:flutter_restaurant/features/cart/widgets/checkout_button_widget.dart';
import 'package:flutter_restaurant/features/cart/widgets/coupon_add_widget.dart';
import 'package:flutter_restaurant/features/cart/widgets/cutlery_widget.dart';
import 'package:flutter_restaurant/features/cart/widgets/delivery_time_estimation_widget.dart';
import 'package:flutter_restaurant/features/cart/widgets/frequently_bought_widget.dart';
import 'package:flutter_restaurant/features/checkout/providers/checkout_provider.dart';
import 'package:flutter_restaurant/features/coupon/providers/coupon_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/helper/checkout_helper.dart';
import 'package:flutter_restaurant/helper/date_converter_helper.dart';
import 'package:flutter_restaurant/helper/price_converter_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/color_resources.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../common/models/config_model.dart';
import '../../../helper/custom_snackbar_helper.dart';
import '../../../main.dart';
import '../../address/providers/location_provider.dart';
import '../../branch/providers/branch_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  final ScrollController _frequentlyBoughtScrollController = ScrollController();
  bool inCoverage = true;
  @override
  void initState() {
    super.initState();
    Provider.of<CouponProvider>(context, listen: false).removeCouponData(false);
    _checkCoverage(context);
  }


  Future<void> _checkCoverage(BuildContext context) async {
    // try {
    final BranchProvider branchProvider = Provider.of<BranchProvider>(Get.context!, listen: false);
    // await Geolocator.requestPermission();
    // bool inRange = false;


    // branchProvider.updateTabIndex(0, isUpdate: false);
    ///if need to previous selection


    if(branchProvider.branchValueList == null ){
      await branchProvider.getBranchValueList(context);
    }

    // Get the nearest branch values sorted by distance
    List<BranchValue>? branchValues = branchProvider.branchValueList;

    if (branchValues!.isNotEmpty) {
      // Get the nearest branch details
      BranchValue? nearestBranch = branchValues.first;

      double? branchLatitude = double.tryParse(nearestBranch.branches!.latitude!);
      double? branchLongitude = double.tryParse(nearestBranch.branches!.longitude!);
      double? branchCoverage = nearestBranch.branches!.coverage!;

      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      LatLng? userLocation = await locationProvider.getCurrentLatLong();

      if (branchLatitude != null && branchLongitude != null && userLocation != null) {
        double distance = Geolocator.distanceBetween(
          branchLatitude,
          branchLongitude,
          userLocation.latitude,
          userLocation.longitude,
        ) / 1000; // Convert meters to kilometers


        print(distance);
        print(branchCoverage);

        if (distance > branchCoverage) {
          print("out of coverage");

          if (mounted) {
            setState(() {
              inCoverage = false;
            });
          }

          // Show dialog if distance exceeds coverage
          // _showOutOfCoverageDialog();
        } else {
          print("in coverage");

          if (mounted) {
            setState(() {
              inCoverage = true;
            });
          }
          // Automatically set the nearest branch
          // await branchProvider.setBranch(nearestBranch.id!, splashProvider);

          // Notify listeners if necessary
          // branchProvider.notifyListeners();
        }
      }
    }
    // } catch (e) {
    //   debugPrint("Error setting nearest branch: $e");
    // }

    // return inRange;
  }


  @override
  void dispose() {
    _frequentlyBoughtScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);

    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: CustomAppBarWidget(context: context, title: getTranslated('cart', context), isBackButtonExist: !ResponsiveHelper.isMobile()),
      body: Consumer<CheckoutProvider>(
        builder: (context, checkoutProvider, child) {
          return Consumer<CartProvider>(
            builder: (context, cart, child) {

              List<List<AddOns>> addOnsList = [];
              List<bool> availableList = [];
              double itemPrice = 0;
              double discount = 0;
              double tax = 0;
              double addOns = 0;
              double addOnsTax = 0;

              for (var cartModel in cart.cartList) {
                List<AddOns> addOnList = [];

                for (var addOnId in cartModel!.addOnIds!) {
                  for(AddOns addOns in cartModel.product!.addOns!) {
                    if(addOns.id == addOnId.id) {
                      addOnList.add(addOns);
                      break;
                    }
                  }
                }
                addOnsList.add(addOnList);


                availableList.add(DateConverterHelper.isAvailable(cartModel.product!.availableTimeStarts!, cartModel.product!.availableTimeEnds!));

                for(int index=0; index<addOnList.length; index++) {
                  addOns = addOns + (addOnList[index].price! * cartModel.addOnIds![index].quantity!);
                  addOnsTax = addOnsTax + ((PriceConverterHelper.addonTaxCalculation(addOnList[index].tax, addOnsTax, addOnList[index].price, 'percent')) * (cartModel.addOnIds?[index].quantity ?? 1));
                }


                itemPrice = itemPrice + (cartModel.price! * cartModel.quantity!);
                discount = discount + (cartModel.discountAmount! * cartModel.quantity!);

                tax = tax + (cartModel.taxAmount! * cartModel.quantity!) + addOnsTax;
              }

              double subTotal = itemPrice + tax  + addOns;
              double total = subTotal - discount - Provider.of<CouponProvider>(context).discount!;
              double totalWithoutDeliveryFee = subTotal - discount - Provider.of<CouponProvider>(context).discount!;

              double orderAmount = itemPrice + addOns;

              bool kmWiseCharge = CheckOutHelper.isKmWiseCharge(deliveryInfoModel: splashProvider.deliveryInfoModel);

              return cart.cartList.isNotEmpty ? Column(children: [

                Expanded(child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(children: [
                    Center(child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: !ResponsiveHelper.isDesktop(context) && height < 600 ? height : height - 400),
                      child: SizedBox(width: Dimensions.webScreenWidth, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        if(ResponsiveHelper.isDesktop(context)) Expanded(flex: 3, child: Container(
                          padding:  const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: Dimensions.radiusSmall)],
                              ),
                              padding:  const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeLarge),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                /// for web Delivery time Estimation
                                const DeliveryTimeEstimationWidget(),
                                const SizedBox(height: Dimensions.paddingSizeLarge),

                                /// for web car item list
                                CartListWidget(cart: cart,addOns: addOnsList, availableList: availableList),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                /// for web Add more item button
                                const AddMoreItemButtonWidget(),
                              ]),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),

                            /// for web Frequently bought section
                            FrequentlyBoughtWidget(scrollController: _frequentlyBoughtScrollController),
                            const SizedBox(height: Dimensions.paddingSizeSmall),

                          ]),

                        )),
                        if(ResponsiveHelper.isDesktop(context))  const SizedBox(width: Dimensions.paddingSizeDefault),

                        Expanded(flex: 2, child: Container(
                          decoration:ResponsiveHelper.isDesktop(context) ? BoxDecoration(
                            color: Theme.of(context).canvasColor,
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 10)],
                          ) : const BoxDecoration(),
                          margin: ResponsiveHelper.isDesktop(context)
                              ? const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeLarge)
                              : const EdgeInsets.all(0),
                          padding: ResponsiveHelper.isDesktop(context) ? const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall)
                              : const EdgeInsets.all(0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if(!ResponsiveHelper.isDesktop(context)) ... [
                                  /// Delivery time Estimation
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  const DeliveryTimeEstimationWidget(),
                                  const SizedBox(height: Dimensions.paddingSizeLarge),

                                  /// Product
                                  CartListWidget(cart: cart,addOns: addOnsList, availableList: availableList),

                                  /// for Add more item button
                                  const AddMoreItemButtonWidget(),
                                  const SizedBox(height: Dimensions.paddingSizeLarge),
                                ],
                              ]),
                            ),

                            /// for Frequently bought section
                            if(!ResponsiveHelper.isDesktop(context))
                              FrequentlyBoughtWidget(scrollController: _frequentlyBoughtScrollController),
                            const SizedBox(height: Dimensions.paddingSizeSmall),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                Material(
                                  color: Theme.of(context).cardColor,
                                  clipBehavior: Clip.hardEdge,
                                  shadowColor: Theme.of(context).shadowColor,
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                  child: InkWell(
                                    onTap: () {
                                      ResponsiveHelper.showDialogOrBottomSheet(context, CouponAddWidget(
                                        couponController: _couponController, total: total,
                                      ));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                        // boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: Dimensions.radiusSmall)],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault,
                                      ),
                                      child: Row(children: [
                                        const CustomAssetImageWidget(
                                          Images.applyPromo, width: Dimensions.paddingSizeLarge, height: Dimensions.paddingSizeLarge,
                                        ),
                                        const SizedBox(width: Dimensions.paddingSizeSmall),

                                        Text(getTranslated('apply_promo', context)!, style: rubikSemiBold),
                                        const Spacer(),

                                        Consumer<CouponProvider>(
                                          builder: (context, couponProvider, _) {
                                            return couponProvider.coupon != null ? InkWell(
                                              onTap: (){
                                                _couponController.clear();
                                                couponProvider.removeCouponData(true);
                                                showCustomSnackBarHelper(getTranslated('coupon_removed_successfully', context),isError: false);
                                              },
                                              child: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error),
                                            ) : Text(getTranslated( couponProvider.coupon != null ? 'edit' : 'add', context)!, style: rubikBold.copyWith(
                                              color: ColorResources.getSecondaryColor(context), fontSize: Dimensions.fontSizeSmall,
                                            ));
                                          }
                                        ),
                                      ]),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Dimensions.paddingSizeLarge),

                                /// Total
                                ItemViewWidget(
                                  title: getTranslated('items_price', context)!,
                                  subTitle: PriceConverterHelper.convertPrice(itemPrice),
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                ItemViewWidget(
                                  title: getTranslated('tax', context)!,
                                  subTitle: '(+) ${PriceConverterHelper.convertPrice(tax)}',
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                ItemViewWidget(
                                  title: getTranslated('addons', context)!,
                                  subTitle: '(+) ${PriceConverterHelper.convertPrice(addOns)}',
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                ItemViewWidget(
                                  title: getTranslated('discount', context)!,
                                  subTitle: '(-) ${PriceConverterHelper.convertPrice(discount)}',
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                ItemViewWidget(
                                  title: getTranslated('coupon_discount', context)!,
                                  subTitle: '(-) ${PriceConverterHelper.convertPrice(Provider.of<CouponProvider>(context).discount)}',
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                Divider(color: Theme.of(context).hintColor.withOpacity(0.5)),

                                ItemViewWidget(
                                  title: getTranslated(kmWiseCharge ? 'total' : 'total_amount', context)!,
                                  subTitle: PriceConverterHelper.convertPrice(total),
                                  subTitleStyle: rubikSemiBold,
                                ),
                                const SizedBox(height: Dimensions.paddingSizeLarge),

                                const CutleryWidget(),

                                if(ResponsiveHelper.isDesktop(context)) const SizedBox(height: Dimensions.paddingSizeDefault),

                                if(ResponsiveHelper.isDesktop(context))
                                  CheckOutButtonWidget(orderAmount: orderAmount, totalWithoutDeliveryFee: totalWithoutDeliveryFee,inCoverage: inCoverage,),

                              ]),
                            ),

                          ]),
                        )),

                      ])),
                    )),

                    if(ResponsiveHelper.isDesktop(context))  const FooterWidget(),
                  ]),
                )),

               if(!ResponsiveHelper.isDesktop(context))
                 CheckOutButtonWidget(orderAmount: orderAmount, totalWithoutDeliveryFee: totalWithoutDeliveryFee, inCoverage: inCoverage,),

              ])
                  :  ResponsiveHelper.isDesktop(context) ? const NoDataWidget(
                isCart: true,
              ) : const Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NoDataWidget(isCart: true),
                ],
              );
            },
          );
        },
      ),
    );
  }


}





