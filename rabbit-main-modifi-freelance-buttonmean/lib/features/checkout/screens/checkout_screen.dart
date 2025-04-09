import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaurant/common/models/cart_model.dart';
import 'package:flutter_restaurant/common/models/config_model.dart';
import 'package:flutter_restaurant/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:flutter_restaurant/common/widgets/footer_widget.dart';
import 'package:flutter_restaurant/common/widgets/not_logged_in_widget.dart';
import 'package:flutter_restaurant/common/widgets/web_app_bar_widget.dart';
import 'package:flutter_restaurant/features/address/domain/models/address_model.dart';
import 'package:flutter_restaurant/features/address/providers/location_provider.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/branch/providers/branch_provider.dart';
import 'package:flutter_restaurant/features/cart/providers/cart_provider.dart';
import 'package:flutter_restaurant/features/cart/widgets/item_view_widget.dart';
import 'package:flutter_restaurant/features/checkout/domain/enum/delivery_type_enum.dart';
import 'package:flutter_restaurant/features/checkout/domain/models/check_out_model.dart';
import 'package:flutter_restaurant/features/checkout/providers/checkout_provider.dart';
import 'package:flutter_restaurant/features/checkout/widgets/confirm_button_widget.dart';
import 'package:flutter_restaurant/features/checkout/widgets/cost_summery_widget.dart';
import 'package:flutter_restaurant/features/checkout/widgets/delivery_details_widget.dart';
import 'package:flutter_restaurant/features/checkout/widgets/partial_pay_widget.dart';
import 'package:flutter_restaurant/features/checkout/widgets/payment_details_widget.dart';
import 'package:flutter_restaurant/features/checkout/widgets/slot_widget.dart';
import 'package:flutter_restaurant/features/checkout/widgets/upside_expansion_widget.dart';
import 'package:flutter_restaurant/features/language/providers/localization_provider.dart';
import 'package:flutter_restaurant/features/order/providers/order_provider.dart';
import 'package:flutter_restaurant/features/profile/providers/profile_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/helper/checkout_helper.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/helper/date_converter_helper.dart';
import 'package:flutter_restaurant/helper/price_converter_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/app_localization.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final double? amount;
  final List<CartModel>? cartList;
  final bool fromCart;
  final bool isCutlery;
  final String? couponCode;
  const CheckoutScreen({super.key,  required this.amount, required this.fromCart,
    required this.cartList, required this.couponCode, required this.isCutlery});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ScrollController scrollController = ScrollController();
  final GlobalKey dropdownKey = GlobalKey();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _noteController = TextEditingController();
  late bool _isLoggedIn;
  late List<CartModel?> _cartList;
  final List<PaymentMethod> _paymentList = [];
  final List<Color> _paymentColor = [];
  Branches? currentBranch;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isLoggedIn();
    _onInitLoad();
  }

  @override
  Widget build(BuildContext context) {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final LocalizationProvider localizationProvider = Provider.of<LocalizationProvider>(context, listen: false);
    final CheckoutProvider checkoutProvider = Provider.of<CheckoutProvider>(context, listen: true);
    final LocationProvider locationProvider = Provider.of<LocationProvider>(context, listen: true);

    bool kmWiseCharge = CheckOutHelper.isKmWiseCharge(deliveryInfoModel: splashProvider.deliveryInfoModel!);
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    if (splashProvider.configModel == null || checkoutProvider.getCheckOutData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      appBar: (isDesktop ? const PreferredSize(preferredSize: Size.fromHeight(100), child: WebAppBarWidget()) : CustomAppBarWidget(
        context: context, title: getTranslated('checkout', context), centerTitle: false,
        leading: InkWell(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).primaryColor),
        ),
      )) as PreferredSizeWidget?,
      body: (_isLoggedIn || splashProvider.configModel!.isGuestCheckout!) ? SafeArea(
        child: Column(children: [
          Expanded(child: CustomScrollView(controller: scrollController, slivers: [
            if (isDesktop) SliverToBoxAdapter(child: Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
              child: Text(getTranslated('checkout', context)!, style: rubikBold.copyWith(fontSize: Dimensions.fontSizeOverLarge)),
            ))),

            SliverToBoxAdapter(child: Center(child: Container(
              alignment: Alignment.topCenter,
              width: Dimensions.webScreenWidth,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 6, child: Container(
                  margin: EdgeInsets.only(
                    left: isDesktop ? (localizationProvider.isLtr ? 0 : Dimensions.paddingSizeDefault) : Dimensions.paddingSizeDefault,
                    right: Dimensions.paddingSizeDefault,
                    top: isDesktop ? 0 : Dimensions.paddingSizeDefault,
                    bottom: isDesktop ? 0 : Dimensions.paddingSizeDefault,
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _DeliverySection(
                      currentBranch: currentBranch,
                      kmWiseCharge: kmWiseCharge,
                      amount: widget.amount,
                      dropdownKey: dropdownKey,
                      checkoutProvider: checkoutProvider,
                      locationProvider: locationProvider,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    _TimeSection(
                        checkoutProvider: checkoutProvider,
                        isDesktop: isDesktop
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    _PaymentSection(total: (widget.amount ?? 0) + checkoutProvider.deliveryCharge),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    if (!isDesktop) _PartialPaySection(totalPrice: (widget.amount ?? 0) + checkoutProvider.deliveryCharge),
                    if (!isDesktop) const SizedBox(height: Dimensions.paddingSizeDefault),

                    _NoteSection(noteController: _noteController, isDesktop: isDesktop),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                  ]),
                )),

                if (isDesktop) Expanded(flex: 4, child: Container(
                  margin: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _PartialPaySection(totalPrice: (widget.amount ?? 0) + checkoutProvider.deliveryCharge),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    _buildSectionContainer(context, children: [
                      CostSummeryWidget(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      ConfirmButtonWidget(
                        noteController: _noteController,
                        callBack: _callback,
                        cartList: _cartList,
                        kmWiseCharge: kmWiseCharge,
                        orderType: checkoutProvider.orderType,
                        orderAmount: widget.amount!,
                        couponCode: widget.couponCode,
                        deliveryCharge: checkoutProvider.deliveryCharge,
                        isCutlery: widget.isCutlery,
                        scrollController: scrollController,
                        dropdownKey: dropdownKey,
                      ),
                    ]),
                  ]),
                )),
              ]),
            ))),

            if (isDesktop) const SliverToBoxAdapter(
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                SizedBox(height: Dimensions.paddingSizeLarge),
                FooterWidget(),
              ]),
            ),
          ])),

          if (!isDesktop) Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.1), blurRadius: 10)],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
            child: Column(children: [
              UpsideExpansionWidget(
                title: ItemViewWidget(
                  title: getTranslated('total_amount', context)!,
                  subTitle: PriceConverterHelper.convertPrice(widget.amount! + checkoutProvider.deliveryCharge),
                  titleStyle: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).primaryColor),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: CostSummeryWidget(),
                  ),
                ],
              ),
              ConfirmButtonWidget(
                 noteController: _noteController,
                 callBack: _callback,
                 cartList: _cartList,
                 kmWiseCharge: kmWiseCharge,
                 orderType: checkoutProvider.orderType,
                 orderAmount: widget.amount!,
                 couponCode: widget.couponCode,
                 deliveryCharge: checkoutProvider.deliveryCharge,
                 isCutlery: widget.isCutlery,
                 scrollController: scrollController,
                 dropdownKey: dropdownKey,
               ),
            ]),
          ),
        ]),
      ) : const NotLoggedInWidget(),
    );
  }

  Future<void> _onInitLoad() async {
    final CheckoutProvider checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final ProfileProvider profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final CartProvider cartProvider = Provider.of<CartProvider>(context, listen: false);
    final LocationProvider locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
    locationProvider.setAreaID(isUpdate: false, isReload: true);
    checkoutProvider.setDeliveryCharge(isReload: true, isUpdate: false);
    final bool isGuestCheckout = (splashProvider.configModel!.isGuestCheckout!) && authProvider.getGuestId() != null;

    double deliveryCharge = 0;

    _cartList = [];
    widget.fromCart ? _cartList.addAll(cartProvider.cartList) : _cartList.addAll(widget.cartList!);

    if(cartProvider.cartList.isEmpty && !widget.fromCart) {
      debugPrint("Cart is empty, proceeding carefully.");
    } else if (cartProvider.cartList.isEmpty && widget.fromCart) {
       RouterHelper.getDashboardRoute('cart');
       return;
    }

    currentBranch = Provider.of<BranchProvider>(context, listen: false).getBranch();
    splashProvider.getOfflinePaymentMethod(true);

    checkoutProvider.clearPrevData();

    if(splashProvider.configModel!.cashOnDelivery!) {
      _paymentList.add(PaymentMethod(getWay: 'cash_on_delivery', getWayImage: Images.cashOnDelivery));
      _paymentColor.add( Colors.primaries[Random().nextInt(Colors.primaries.length)].withOpacity(0.02));
    }

    if(splashProvider.configModel?.walletStatus ?? false) {
      _paymentList.add(PaymentMethod(getWay: 'wallet_payment', getWayImage: Images.walletPayment));
      _paymentColor.add( Colors.primaries[Random().nextInt(Colors.primaries.length)].withOpacity(0.1));
    }

    for (var method in splashProvider.configModel?.activePaymentMethodList ?? []) {
      _paymentList.add(method);
      _paymentColor.add( Colors.primaries[Random().nextInt(Colors.primaries.length)].withOpacity(0.1));
    }

    if(_isLoggedIn || (splashProvider.configModel?.isGuestCheckout ?? false)) {

      if(_isLoggedIn){
        profileProvider.getUserInfo(false, isUpdate: false);
      }

      checkoutProvider.initializeTimeSlot(context).then((value) {
        checkoutProvider.sortTime();
      });
      await locationProvider.initAddressList();

      AddressModel? addressModel;

      if(_isLoggedIn) {
        addressModel = await locationProvider.getDefaultAddress();
      }
      await CheckOutHelper.selectDeliveryAddressAuto(
        orderType: checkoutProvider.orderType,
        isLoggedIn: (_isLoggedIn || isGuestCheckout),
        lastAddress: addressModel
      );

      deliveryCharge = CheckOutHelper.getDeliveryCharge(
          splashProvider : splashProvider,
          googleMapStatus: splashProvider.configModel!.googleMapStatus!,
          distance: checkoutProvider.distance,
          minimumDistanceForFreeDelivery: splashProvider.deliveryInfoModel?.deliveryChargeSetup?.minimumDistanceForFreeDelivery?.toDouble() ?? 0,
          shippingPerKm: splashProvider.deliveryInfoModel?.deliveryChargeSetup?.deliveryChargePerKilometer?.toDouble() ?? 0,
          minShippingCharge: splashProvider.deliveryInfoModel?.deliveryChargeSetup?.minimumDeliveryCharge?.toDouble() ?? 0,
          defaultDeliveryCharge: splashProvider.deliveryInfoModel?.deliveryChargeSetup?.fixedDeliveryCharge?.toDouble() ?? 0,
          isTakeAway: checkoutProvider.orderType == OrderType.takeAway,
          kmWiseCharge: splashProvider.deliveryInfoModel?.deliveryChargeSetup?.deliveryChargeType == 'distance'
      );

      checkoutProvider.setDeliveryCharge(deliveryCharge: deliveryCharge, isUpdate: true);
      checkoutProvider.setCheckOutData = CheckOutModel(
        orderType: checkoutProvider.orderType.name.camelCaseToSnakeCase(),
        deliveryCharge: checkoutProvider.deliveryCharge,
        amount: widget.amount,
        placeOrderDiscount: 0,
        couponCode: widget.couponCode,
        orderNote: null,
      );

    }
  }

  void _callback(bool isSuccess, String message, String orderID, int addressID) async {
    if(isSuccess) {
      if(widget.fromCart) {
        Provider.of<CartProvider>(context, listen: false).clearCartList();
      }
      Provider.of<OrderProvider>(context, listen: false).stopLoader();
      RouterHelper.getOrderSuccessScreen(orderID, 'success');

    }else {
      showCustomSnackBarHelper(message);
    }
  }

  Future<Uint8List> convertAssetToUnit8List(String imagePath, {int width = 30}) async {
    ByteData data = await rootBundle.load(imagePath);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))!.buffer.asUint8List();
  }
}

Widget _buildSectionContainer(BuildContext context, {required List<Widget> children}) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 1,
          offset: const Offset(0, 2),
         )
      ],
    ),
    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _DeliverySection extends StatelessWidget {
  final Branches? currentBranch;
  final bool kmWiseCharge;
  final double? amount;
  final GlobalKey dropdownKey;
  final CheckoutProvider checkoutProvider;
  final LocationProvider locationProvider;

  const _DeliverySection({
    this.currentBranch,
    required this.kmWiseCharge,
    this.amount,
    required this.dropdownKey,
    required this.checkoutProvider,
    required this.locationProvider,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return _buildSectionContainer(context, children: [
      DeliveryDetailsWidget(
        currentBranch: currentBranch,
        kmWiseCharge: kmWiseCharge,
        deliveryCharge: checkoutProvider.deliveryCharge,
        amount: amount,
        dropdownKey: dropdownKey,
      ),
    ]);
  }
}

class _TimeSection extends StatelessWidget {
  final CheckoutProvider checkoutProvider;
  final bool isDesktop;

  const _TimeSection({required this.checkoutProvider, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    return _buildSectionContainer(context, children: [
        Text(getTranslated('preference_time', context)!, style: rubikBold.copyWith(
          fontSize: isDesktop ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefault,
          fontWeight: isDesktop ? FontWeight.w700 : FontWeight.w600,
        )),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        
        // --- Restore Original Day Selection (Radio Buttons) ---
        SizedBox(height: 50, child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: 2,
          itemBuilder: (context, index) {
            // Need Consumer here to get updated groupValue
            return Consumer<CheckoutProvider>(builder: (context, checkoutProvider, _) => 
               Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Radio(
                  activeColor: Theme.of(context).primaryColor,
                  value: index,
                  groupValue: checkoutProvider.selectDateSlot,
                  onChanged: (value)=> checkoutProvider.updateDateSlot(index),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Text(index == 0 ? getTranslated('today', context)! : getTranslated('tomorrow', context)!, style: rubikRegular.copyWith(
                  color: index == checkoutProvider.selectDateSlot ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                )),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              ])
            );
          },
        )),
        
        /* // New Day Selection Logic (ToggleButtons - commented out)
        Consumer<CheckoutProvider>( 
          builder: (context, checkoutProvider, child) {
            // ... Toggle Button Code ...
          }
        ),
        */

        const SizedBox(height: Dimensions.paddingSizeSmall),
        const Divider(thickness: 0.5, height: Dimensions.paddingSizeDefault),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // --- AnimatedSwitcher pointing back to Dropdowns ---
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400), // Keep animation duration or adjust
           transitionBuilder: (Widget child, Animation<double> animation) {
             // Keep or adjust transition
            return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                    scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                    child: child
                ),
            );
          },
          child: checkoutProvider.timeSlots != null
            ? checkoutProvider.timeSlots!.isNotEmpty
              // Call the dropdown builder function again
              ? SizedBox(key: const ValueKey('time_dropdowns_reverted'), child: _buildTimeDropdowns(context, checkoutProvider, splashProvider))
              : SizedBox(key: const ValueKey('no_slots'), child: Center(child: Text(getTranslated('no_slot_available', context)!)))
            : const SizedBox(key: ValueKey('time_loading'), child: Center(child: CircularProgressIndicator())),
        ),
      ]);
  }

  /* // Remove or comment out helpers for the new UI
  // --- Helper for Day Toggle Button Child ---
  Widget _buildDayToggle(BuildContext context, IconData icon, String text, bool isSelected) {
    // ... code ...
  }

  // --- Add this function inside _TimeSection class ---
  void _showTimeSlotPicker(BuildContext context, CheckoutProvider checkoutProvider, SplashProvider splashProvider) {
    // ... code ...
  }

  // --- Placeholder/Structure for Time Selector Button (Modal logic later) ---
  Widget _buildTimeSelectorButton(BuildContext context, CheckoutProvider checkoutProvider, SplashProvider splashProvider) {
      // ... code ...
  }
  */

  // --- Restore the Dropdown Builder function ---
  Widget _buildTimeDropdowns(BuildContext context, CheckoutProvider checkoutProvider, SplashProvider splashProvider) {
    // --- Logic to extract hours and minutes ---
    List<int> availableHours = [];
    Map<int, List<int>> minutesByHour = {};
    int? selectedHour;
    int? selectedMinute;
    int? selectedSlotIndex = checkoutProvider.selectTimeSlot;

    bool isAsapAvailable = selectedSlotIndex == 0 &&
                           checkoutProvider.selectDateSlot == 0 &&
                           splashProvider.isRestaurantOpenNow(context);

    if(checkoutProvider.timeSlots != null) {
      for (int i = 0; i < checkoutProvider.timeSlots!.length; i++) {
        if (checkoutProvider.timeSlots![i].startTime != null) {
          DateTime startTime = checkoutProvider.timeSlots![i].startTime!;
          int hour = startTime.hour;
          int minute = startTime.minute;

          if (!availableHours.contains(hour)) {
            availableHours.add(hour);
            minutesByHour[hour] = [];
          }
          if (!minutesByHour[hour]!.contains(minute)) {
             minutesByHour[hour]!.add(minute);
             minutesByHour[hour]!.sort();
          }

          if (i == selectedSlotIndex) {
            selectedHour = hour;
            selectedMinute = minute;
          }
        }
      }
      availableHours.sort();
    }

    if (selectedHour == null && selectedMinute == null && checkoutProvider.timeSlots != null && checkoutProvider.timeSlots!.isNotEmpty && !isAsapAvailable) {
      if(checkoutProvider.timeSlots![0].startTime != null){
          selectedHour = checkoutProvider.timeSlots![0].startTime!.hour;
          selectedMinute = checkoutProvider.timeSlots![0].startTime!.minute;
      }
    }

    List<int> currentMinutes = selectedHour != null ? (minutesByHour[selectedHour] ?? []) : [];

    if (availableHours.isEmpty) {
      return Center(child: Text(getTranslated('no_slot_available', context)!));
    }

    // Style constants
    final Color dropdownBackgroundColor = Theme.of(context).cardColor;
    final Color dropdownBorderColor = Theme.of(context).disabledColor.withOpacity(0.2);
    final double dropdownBorderRadius = Dimensions.radiusSmall;
    final EdgeInsets dropdownPadding = const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hour Dropdown Container
        Container(
          padding: dropdownPadding,
          decoration: BoxDecoration(
            color: dropdownBackgroundColor,
            borderRadius: BorderRadius.circular(dropdownBorderRadius),
            border: Border.all(color: dropdownBorderColor, width: 1),
          ),
          child: DropdownButton<int>(
            value: selectedHour,
            hint: Text(
                getTranslated('hour', context)!,
                style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
            ),
            items: availableHours.map((hour) {
              return DropdownMenuItem<int>(
                value: hour,
                child: Text(
                    hour.toString().padLeft(2, '0'),
                    style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                 ),
              );
            }).toList(),
            onChanged: (newHour) {
              if (newHour != null) {
                List<int> newMinutes = minutesByHour[newHour] ?? [];
                int? newMinute = newMinutes.isNotEmpty ? newMinutes.first : null;
                if(newMinute != null) {
                  int newIndex = checkoutProvider.timeSlots!.indexWhere((slot) =>
                      slot.startTime != null &&
                      slot.startTime!.hour == newHour &&
                      slot.startTime!.minute == newMinute);
                  if (newIndex != -1) {
                    checkoutProvider.updateTimeSlot(newIndex);
                  }
                }
              }
            },
            isDense: true,
            underline: const SizedBox.shrink(),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).hintColor, size: 20),
            iconSize: 0,
            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text(":", style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ),

        // Minute Dropdown Container
        Container(
          padding: dropdownPadding,
          decoration: BoxDecoration(
            color: dropdownBackgroundColor,
            borderRadius: BorderRadius.circular(dropdownBorderRadius),
            border: Border.all(color: dropdownBorderColor, width: 1),
          ),
          child: DropdownButton<int>(
            value: selectedMinute,
            hint: Text(
                getTranslated('minute', context)!,
                style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
            ),
            items: currentMinutes.map((minute) {
              return DropdownMenuItem<int>(
                value: minute,
                child: Text(
                    minute.toString().padLeft(2, '0'),
                    style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              );
            }).toList(),
            onChanged: (newMinute) {
               if (newMinute != null && selectedHour != null) {
                 int newIndex = checkoutProvider.timeSlots!.indexWhere((slot) =>
                     slot.startTime != null &&
                     slot.startTime!.hour == selectedHour &&
                     slot.startTime!.minute == newMinute);
                 if (newIndex != -1) {
                   checkoutProvider.updateTimeSlot(newIndex);
                 }
              }
            },
            isDense: true,
            underline: const SizedBox.shrink(),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).hintColor, size: 20),
            iconSize: 0,
            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),

        if (isAsapAvailable &&
            checkoutProvider.timeSlots!.isNotEmpty &&
            checkoutProvider.timeSlots![0].startTime != null &&
            selectedHour == checkoutProvider.timeSlots![0].startTime!.hour &&
            selectedMinute == checkoutProvider.timeSlots![0].startTime!.minute )
          Padding(
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            child: Text("(${getTranslated('asap', context)!})", style: rubikRegular.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
          ),
      ],
    );
  }

} // End of _TimeSection class

class _PaymentSection extends StatelessWidget {
  final double total;
  const _PaymentSection({required this.total});

  @override
  Widget build(BuildContext context) {
    return _buildSectionContainer(context, children: [
      PaymentDetailsWidget(total: total),
    ]);
  }
}

class _PartialPaySection extends StatelessWidget {
  final double totalPrice;
  const _PartialPaySection({required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    if(ResponsiveHelper.isDesktop(context)){
      return _buildSectionContainer(context, children: [
        PartialPayWidget(totalPrice: totalPrice),
      ]);
    } else {
      return PartialPayWidget(totalPrice: totalPrice);
    }
  }
}

class _NoteSection extends StatelessWidget {
  final TextEditingController noteController;
  final bool isDesktop;

  const _NoteSection({required this.noteController, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return _buildSectionContainer(context, children: [
      Text(getTranslated('add_delivery_note', context)!, style: rubikBold.copyWith(
        fontSize: isDesktop ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefault,
        fontWeight: isDesktop ? FontWeight.w700 : FontWeight.w600,
      )),
      const SizedBox(height: Dimensions.fontSizeSmall),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.2), width: 1),
        ),
        child: CustomTextFieldWidget(
          controller: noteController,
          hintText: getTranslated('additional_note', context),
          prefixIconData: Icons.notes_rounded,
          prefixIconColor: Theme.of(context).hintColor.withOpacity(0.7),
          isShowPrefixIcon: false,
          maxLines: 5,
          inputType: TextInputType.multiline,
          inputAction: TextInputAction.newline,
          capitalization: TextCapitalization.sentences,
          radius: Dimensions.radiusSmall,
        ),
      ),
    ]);
  }
}










