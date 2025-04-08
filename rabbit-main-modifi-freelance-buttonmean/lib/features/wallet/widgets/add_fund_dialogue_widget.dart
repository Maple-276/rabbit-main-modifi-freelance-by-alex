import 'dart:convert'as convert;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaurant/common/models/config_model.dart';
import 'package:flutter_restaurant/common/widgets/custom_button_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_image_widget.dart';
import 'package:flutter_restaurant/features/checkout/providers/checkout_provider.dart';
import 'package:flutter_restaurant/features/language/providers/localization_provider.dart';
import 'package:flutter_restaurant/features/profile/providers/profile_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/features/wallet/providers/wallet_provider.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/app_constants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;



class AddFundDialogueWidget extends StatefulWidget {
  final String? status;
  const AddFundDialogueWidget({super.key, this.status});

  @override
  State<AddFundDialogueWidget> createState() => _AddFundDialogueWidgetState();
}

class _AddFundDialogueWidgetState extends State<AddFundDialogueWidget> {
  final TextEditingController inputAmountController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Provider.of<CheckoutProvider>(context, listen: false).changePaymentMethod(isUpdate: false, isClear: true);

  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    final ConfigModel? configModel = Provider.of<SplashProvider>(context, listen: false).configModel;
    return Align(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: ResponsiveHelper.isDesktop(context) ? width * 0.35 : width * 0.9,
            child: Align(alignment: Alignment.topRight, child: InkWell(
              onTap: ()=> context.pop(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor.withOpacity(0.5),
                ),
                padding: const EdgeInsets.all(3),
                child: const Icon(Icons.clear),
              ),
            )),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              color: Theme.of(context).cardColor,
            ),
            width: ResponsiveHelper.isDesktop(context) ? width * 0.35 : width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? 50 : Dimensions.paddingSizeLarge),
            child: Consumer<WalletProvider>(builder: (context, walletProvider, _) {
              return Consumer<CheckoutProvider>(builder: (context, checkoutProvider, _) {
                return Column(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    Text(getTranslated('add_fund_to_wallet', context)!, style: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Text(
                      getTranslated('add_fund_by_from', context)!,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    TextField(
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      controller: inputAmountController,
                      focusNode: focusNode,
                      textAlignVertical: TextAlignVertical.center,
                      textAlign: TextAlign.center,
                      style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.titleLarge!.color),
                      decoration: InputDecoration(
                        // isCollapsed : true,
                        hintText: getTranslated('enter_amount', context),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          borderSide: BorderSide(style: BorderStyle.solid, width: 0.3, color: Theme.of(context).primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          borderSide: BorderSide(style: BorderStyle.solid, width: 1, color: Theme.of(context).primaryColor),
                        ),
                        border : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          borderSide: BorderSide(style: BorderStyle.solid, width: 0.3, color: Theme.of(context).primaryColor),
                        ),
                        hintStyle: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.titleLarge!.color!.withOpacity(0.7),
                        ),
                      ),
                      onChanged: (String value){
                        setState(() {
                        });
                      },
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    inputAmountController.text.isNotEmpty ? Row(children: [
                      Text(getTranslated('payment_method', context)!, style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                      Expanded(child: Text(
                        '(${getTranslated('faster_and_secure_way_to_pay_bill', context)})',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      )),
                    ]) : const SizedBox(),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    // walletProvider.amountEmpty ? ListView.builder(
                    if(inputAmountController.text.isNotEmpty) Flexible(child: PaymentMethodView(
                      onTap: (index) => checkoutProvider.changePaymentMethod(
                        digitalMethod: configModel?.activePaymentMethodList![index],
                      ),
                      paymentList: configModel?.activePaymentMethodList ?? [],
                    )),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    CustomButtonWidget(
                      btnTxt: getTranslated('add_fund', context),
                      onTap: (){
                        final ProfileProvider profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                        if(inputAmountController.text.isEmpty){
                          showCustomSnackBarHelper(getTranslated('please_enter_amount', context));
                        }else if(checkoutProvider.paymentMethod == null){
                          showCustomSnackBarHelper(getTranslated('please_select_payment_method', context));
                        }else{
                          context.pop();
                          double amount = double.parse(inputAmountController.text.replaceAll(configModel!.currencySymbol!, ''));

                          String? hostname = html.window.location.hostname;
                          String protocol = html.window.location.protocol;
                          String port = html.window.location.port;


                          String url = "customer_id=${profileProvider.userInfoModel!.id}"
                              "&&callback=${AppConstants.baseUrl}${RouterHelper.wallet}&&order_amount=${amount.toStringAsFixed(2)}";

                          String webUrl = "customer_id=${profileProvider.userInfoModel!.id}"
                              "&&callback=$protocol//$hostname${RouterHelper.wallet}&&order_amount=${amount.toStringAsFixed(2)}&&status=";

                          String webUrlDebug = "customer_id=${profileProvider.userInfoModel!.id}"
                              "&&callback=$protocol//$hostname:$port${RouterHelper.wallet}&&order_amount=${amount.toStringAsFixed(2)}&&status=";


                          String tokenUrl = '${convert.base64Encode(convert.utf8.encode(ResponsiveHelper.isWeb() ? (kDebugMode ? webUrlDebug : webUrl) : url))}&&payment_platform=${kIsWeb ? 'web' : 'app'}&&is_add_fund=1';
                          String selectedUrl = '${AppConstants.baseUrl}/payment-mobile?token=$tokenUrl&&payment_method=${checkoutProvider.paymentMethod?.getWay}';

                            if(kIsWeb){
                              html.window.open(selectedUrl,"_self");
                            }else{
                              context.pop();
                              RouterHelper.getPaymentRoute(selectedUrl, fromCheckout: false);
                            }

                        }
                      },
                    ) ,

                  ]);
                }
              );
            }),
          ),

        ]),
      ),
    );
  }
}

class PaymentMethodView extends StatelessWidget {
  final Function(int index) onTap;
  final List<PaymentMethod> paymentList;
  final JustTheController? toolTip;
  const PaymentMethodView({
    super.key, required this.onTap, required this.paymentList, this.toolTip
  });


  @override
  Widget build(BuildContext context) {

    final CheckoutProvider checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final LocalizationProvider localizationProvider = Provider.of<LocalizationProvider>(context, listen: false);



    return SingleChildScrollView(child: ListView.builder(
       itemCount: paymentList.length,
       shrinkWrap: true,
       physics: const NeverScrollableScrollPhysics(),
       itemBuilder: (context, index){
         bool isSelected = paymentList[index] == checkoutProvider.paymentMethod;
         bool isOffline = paymentList[index].type == 'offline';
         return InkWell(
           onTap: isSelected && isOffline ? null : ()=> onTap(index),
           child: Container(
             decoration: BoxDecoration(
                 color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.transparent,
                 borderRadius: BorderRadius.circular(Dimensions.radiusDefault)
             ),
             padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeLarge),
             child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
               Row(mainAxisAlignment: MainAxisAlignment.spaceBetween , children: [


                 Row(children: [
                   Container(
                     height: Dimensions.paddingSizeLarge, width: Dimensions.paddingSizeLarge,
                     decoration: BoxDecoration(
                         shape: BoxShape.circle, color: isSelected ? Theme.of(context).secondaryHeaderColor : Theme.of(context).cardColor,
                         border: Border.all(color: Theme.of(context).disabledColor)
                     ),
                     child: Icon(Icons.check, color: Theme.of(context).cardColor, size: 16),
                   ),
                   const SizedBox(width: Dimensions.paddingSizeDefault),

                   isOffline ? Image.asset(
                     Images.offlinePayment,  height: Dimensions.paddingSizeLarge, fit: BoxFit.contain,
                   ) : CustomImageWidget(
                     height: Dimensions.paddingSizeLarge, fit: BoxFit.contain,
                     image: '${splashProvider.configModel?.baseUrls?.getWayImageUrl}/${paymentList[index].getWayImage}',
                   ),
                   const SizedBox(width: Dimensions.paddingSizeSmall),

                   Text(
                     isOffline ? getTranslated('pay_offline', context)! : paymentList[index].getWayTitle ?? '',
                     style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                   ),
                 ],),


                 isOffline ? Align(alignment: Alignment.centerRight,
                   child: JustTheTooltip(
                     preferredDirection: AxisDirection.down, tailLength: 14, tailBaseWidth: 20,
                     controller: toolTip,backgroundColor: Colors.black87,

                     content:  Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                       child: Container(
                         constraints: const BoxConstraints(maxWidth: 500),
                         child: Directionality(
                           textDirection: localizationProvider.isLtr ? TextDirection.ltr : TextDirection.rtl,
                           child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                             children: [
                               Text("Note", style: rubikBold.copyWith(color: Colors.blue),),
                               const SizedBox(height: Dimensions.paddingSizeSmall),

                               Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Padding(padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
                                   child: Icon(Icons.circle,size: 7, color: Theme.of(context).cardColor,),
                                 ),
                                 Expanded(child: Text(getTranslated('to_pay_offline_you_have_to', context)!, style: rubikSemiBold.copyWith(
                                   color: Theme.of(context).cardColor
                                 ),)),
                               ]),
                               const SizedBox(height: Dimensions.paddingSizeSmall),

                               Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center,children: [
                                 Padding(padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
                                   child: Icon(Icons.circle,size: 7, color: Theme.of(context).cardColor,),
                                 ),
                                 Expanded(child: Text(getTranslated('save_the_necessary_information', context)!, style: rubikSemiBold.copyWith(
                                     color: Theme.of(context).cardColor
                                 ),)),
                               ]),
                               const SizedBox(height: Dimensions.paddingSizeSmall),

                               Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center,children: [
                                 Padding(padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
                                   child: Icon(Icons.circle,size: 7, color: Theme.of(context).cardColor,),
                                 ),
                                 Expanded(child: Text(getTranslated('insert_the_informat', context)!, style: rubikSemiBold.copyWith(
                                     color: Theme.of(context).cardColor
                                 ),)),
                               ]),
                               const SizedBox(height: Dimensions.paddingSizeSmall),

                             ],
                           ),
                         ),
                       ),
                     ),
                     child: InkWell(
                       onTap: ()=> toolTip?.showTooltip(),
                       child: Image.asset(Images.tooltipIcon, height: 15, width: 15),),),
                 ) : const SizedBox()


                 ]),

               if(isOffline && isSelected && splashProvider.offlinePaymentModelList != null) SingleChildScrollView(
                 padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraLarge),
                 scrollDirection: Axis.horizontal,
                 child: Row(mainAxisAlignment: MainAxisAlignment.start, children: splashProvider.offlinePaymentModelList!.map((offlineMethod) => InkWell(
                   onTap: () {
                     checkoutProvider.changePaymentMethod(offlinePaymentModel: offlineMethod);
                     checkoutProvider.setOfflineSelectedValue(null);
                   },
                   child: Container(
                     margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                     padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeExtraLarge),
                     decoration: BoxDecoration(
                       color: Theme.of(context).cardColor,
                       border: Border.all(width: 2, color: checkoutProvider.selectedOfflineMethod == offlineMethod ? Theme.of(context).primaryColor.withOpacity(0.5,) : Colors.blue.withOpacity(0.05)) ,
                       borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                     ),
                     child: Text(offlineMethod?.methodName ?? ''),
                   ),
                 )).toList()),
               ),


               if(isOffline && checkoutProvider.selectedOfflineValue != null && isSelected ) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 const SizedBox(height: Dimensions.paddingSizeDefault),

                 Text(getTranslated('payment_info', context)!, style: rubikSemiBold,),
                 const SizedBox(height: Dimensions.paddingSizeSmall),

                 Column(children: checkoutProvider.selectedOfflineValue!.map((method) => Row(children: [
                   Flexible(child: Text(method.keys.single, style: rubikRegular, maxLines: 1, overflow: TextOverflow.ellipsis)),
                   const SizedBox(width: Dimensions.paddingSizeSmall),

                   Flexible(child: Text(' :  ${method.values.single}', style: rubikRegular, maxLines: 1, overflow: TextOverflow.ellipsis)),
                 ])).toList()),

               ]),



             ]),
           ),
         );
       },));
  }
}
