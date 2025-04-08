import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/config_model.dart';
import 'package:flutter_restaurant/features/checkout/providers/checkout_provider.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/profile/providers/profile_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:flutter_restaurant/common/widgets/custom_button_widget.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/features/checkout/widgets/offline_payment_widget.dart';
import 'package:flutter_restaurant/features/checkout/widgets/partial_pay_dialog_widget.dart';
import 'package:flutter_restaurant/features/checkout/widgets/payment_button_widget.dart';
import 'package:flutter_restaurant/features/wallet/widgets/add_fund_dialogue_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';


class PaymentMethodBottomSheetWidget extends StatefulWidget {
  final double totalPrice;
  const PaymentMethodBottomSheetWidget({super.key, required this.totalPrice});

  @override
  State<PaymentMethodBottomSheetWidget> createState() => _PaymentMethodBottomSheetWidgetState();
}

class _PaymentMethodBottomSheetWidgetState extends State<PaymentMethodBottomSheetWidget> {
  bool canSelectWallet = false;
  bool notHideCod = true;
  bool notHideDigital = true;
  bool notHideOffline = true;
   final JustTheController? toolTip = JustTheController();

  List<PaymentMethod> paymentList = [];

  @override
  void initState() {
    super.initState();

    final CheckoutProvider checkoutProvider =  Provider.of<CheckoutProvider>(context, listen: false);
    final AuthProvider authProvider =  Provider.of<AuthProvider>(context, listen: false);

    double? walletBalance = Provider.of<ProfileProvider>(context, listen: false).userInfoModel?.walletBalance;
    final ConfigModel configModel = Provider.of<SplashProvider>(context, listen: false).configModel!;

    checkoutProvider.setPaymentIndex(null, isUpdate: false);
    checkoutProvider.setOfflineSelectedValue(null, isUpdate: false);
    Future.delayed(const Duration(milliseconds: 500)).then((value){
      checkoutProvider.changePaymentMethod(isClear: true, isUpdate: true);
    });

    if(authProvider.isLoggedIn() && walletBalance != null && walletBalance > 0 && walletBalance >= widget.totalPrice){
      canSelectWallet = true;
    }
    if(checkoutProvider.partialAmount != null){
      if(configModel.partialPaymentCombineWith!.toLowerCase() == 'cod'){
        notHideCod = true;
        notHideDigital = false;
        notHideOffline = false;
      } else if(configModel.partialPaymentCombineWith!.toLowerCase() == 'digital_payment'){
        notHideCod = false;
        notHideDigital = true;
        notHideOffline = false;
      } else if(configModel.partialPaymentCombineWith!.toLowerCase() == 'offline_payment'){
        notHideCod = false;
        notHideDigital = false;
        notHideOffline = true;

      } else if(configModel.partialPaymentCombineWith!.toLowerCase() == 'all'){
        notHideCod = true;
        notHideDigital = true;
        notHideOffline = true;
      }
    }




    if(notHideDigital) {
      paymentList.addAll(configModel.activePaymentMethodList ?? []);
    }

    if(configModel.isOfflinePayment! && notHideOffline){
      paymentList.add(PaymentMethod(
        getWay: 'offline', getWayTitle: getTranslated('offline', context),
        type: 'offline',
        getWayImage: Images.offlinePayment,
      ));
    }

  }
  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ProfileProvider profileProvider  = Provider.of<ProfileProvider>(context, listen: false);
    final ConfigModel configModel = Provider.of<SplashProvider>(context, listen: false).configModel!;

    bool isPartialPayment = authProvider.isLoggedIn() && configModel.isPartialPayment!
        && configModel.walletStatus!
        && (profileProvider.userInfoModel != null
            && (profileProvider.userInfoModel!.walletBalance ?? 0) > 0
            &&  profileProvider.userInfoModel!.walletBalance! <= widget.totalPrice);

    return SingleChildScrollView(
      child: Center(child: SizedBox(width: 550, child: Column(mainAxisSize: MainAxisSize.min, children: [
        if(ResponsiveHelper.isDesktop(context)) SizedBox(height: MediaQuery.sizeOf(context).height * 0.05),

        if(ResponsiveHelper.isDesktop(context)) Align(
          alignment: Alignment.topRight,
          child: InkWell(
            onTap: () => context.pop(),
            child: Container(
              height: 30, width: 30,
              margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(50)),
              child: const Icon(Icons.clear),
            ),
          ),
        ),

        Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
          width: 550,
          margin: const EdgeInsets.only(top: kIsWeb ? 0 : 30),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: ResponsiveHelper.isMobile() ? const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))
                : const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeExtraLarge * (ResponsiveHelper.isDesktop(context) ? 2 : 1),
            vertical: Dimensions.paddingSizeLarge,
          ),
          child: Consumer<CheckoutProvider>(
              builder: (ctx, checkoutProvider, _) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

                  !ResponsiveHelper.isDesktop(context) ? Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 4, width: 35,
                      margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                      decoration: BoxDecoration(color: Theme.of(context).disabledColor, borderRadius: BorderRadius.circular(10)),
                    ),
                  ) : const SizedBox(),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  Row(children: [
                    notHideCod ? Text(getTranslated('choose_payment_method', context)!, style: rubikBold.copyWith(fontSize: Dimensions.fontSizeDefault)) : const SizedBox(),
                    SizedBox(width: notHideCod ? Dimensions.paddingSizeExtraSmall : 0),

                    notHideCod ? Flexible(child: Text(
                      "(${getTranslated('click_one_of_the_option_below', context)!})",
                      style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                    )): const SizedBox(),
                  ]),


                  SizedBox(height: notHideCod ? Dimensions.paddingSizeLarge : 0),

                  Row(children: [
                    configModel.cashOnDelivery! && notHideCod ? Expanded(
                      child: PaymentButtonWidget(
                        icon: Images.moneyIcon,
                        title: getTranslated('cash_on_delivery', context)!,
                        isSelected: checkoutProvider.paymentMethodIndex == 0,
                        onTap: () {
                         checkoutProvider.setPaymentIndex(0);
                        },
                      ),
                    ) : const SizedBox(),
                    SizedBox(width: configModel.cashOnDelivery! ? Dimensions.paddingSizeLarge : 0),

                    configModel.walletStatus! && authProvider.isLoggedIn() && (checkoutProvider.partialAmount == null) && !isPartialPayment ? Expanded(
                      child: PaymentButtonWidget(
                        icon: Images.walletIcon,
                        title: getTranslated('pay_via_wallet', context)!,
                        isSelected: checkoutProvider.paymentMethodIndex == 1,
                        onTap: () {
                          if(canSelectWallet) {
                            context.pop();
                            showDialog(context: context, builder: (ctx)=> PartialPayDialogWidget(
                              isPartialPay: profileProvider.userInfoModel!.walletBalance! < widget.totalPrice,
                              totalPrice: widget.totalPrice,
                            ));
                          }else{
                            showCustomSnackBarHelper(getTranslated('your_wallet_have_not_sufficient_balance', context));
                          }
                        },
                      ),
                    ) : const SizedBox(),

                  ]),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                 if(paymentList.isNotEmpty) Row(children: [
                    Text(getTranslated('pay_via_online', context)!, style: rubikBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                    Expanded(
                      child: Text('(${getTranslated('faster_and_secure_way_to_pay_bill', context)})', style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor,
                      )),
                    ),

                  ]),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  Flexible(child: PaymentMethodView(
                      toolTip: toolTip,
                      paymentList: paymentList,
                      onTap: (index){
                        if(notHideOffline &&  paymentList[index].type == 'offline'){
                          checkoutProvider.changePaymentMethod(digitalMethod: paymentList[index]);
                        }else if(!notHideDigital){
                          showCustomSnackBarHelper('${getTranslated('you_can_not_use', context)} ${getTranslated('digital_payment', context)} ${getTranslated('in_partial_payment', context)}');
                        }else{
                          checkoutProvider.changePaymentMethod(digitalMethod: paymentList[index]);
                        }
                      }
                  )),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),


                  SafeArea(child: CustomButtonWidget(
                    btnTxt: getTranslated('select', context),
                    onTap: checkoutProvider.paymentMethodIndex == null
                        && checkoutProvider.paymentMethod == null
                        || (checkoutProvider.paymentMethod != null && checkoutProvider.paymentMethod?.type == 'offline' && checkoutProvider.selectedOfflineMethod == null)
                        ? null : () {
                      if(checkoutProvider.paymentMethod?.type == 'offline'){
                        if(checkoutProvider.selectedOfflineValue != null){
                          checkoutProvider.setOfflineSelect(true);
                          context.pop();
                        }else{
                          showDialog(context: context, builder: (ctx)=> OfflinePaymentWidget(totalAmount: widget.totalPrice));
                        }



                      }else{
                        checkoutProvider.savePaymentMethod(index: checkoutProvider.paymentMethodIndex, method: checkoutProvider.paymentMethod);
                        context.pop();

                      }
                    },
                  )),

                ]);
              }
          ),
        ),
      ]))),
    );
  }
}
