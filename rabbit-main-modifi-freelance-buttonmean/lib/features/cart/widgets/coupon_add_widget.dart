import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_bottom_sheet_header.dart';
import 'package:flutter_restaurant/common/widgets/custom_dialog_shape_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:flutter_restaurant/features/coupon/providers/coupon_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/helper/date_converter_helper.dart';
import 'package:flutter_restaurant/helper/price_converter_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/color_resources.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class CouponAddWidget extends StatefulWidget {
  const CouponAddWidget({
    super.key,
    required TextEditingController couponController,
    required this.total,
  }) : _couponController = couponController;

  final TextEditingController _couponController;
  final double total;

  @override
  State<CouponAddWidget> createState() => _CouponAddWidgetState();
}

class _CouponAddWidgetState extends State<CouponAddWidget> {

  @override
  void initState() {
    Provider.of<CouponProvider>(context, listen: false).getCouponList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final CouponProvider couponProvider = Provider.of<CouponProvider>(context, listen: false);
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    final double height = MediaQuery.sizeOf(context).height;
    final Size size = MediaQuery.sizeOf(context);
    // final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return CustomDialogShapeWidget(maxHeight: height * 0.6, child: Column(children: [

      CustomBottomSheetHeader(
          title: getTranslated('available_promo', context)!,
          titleSize: Dimensions.fontSizeLarge,
        titleWeight: FontWeight.bold,
      ),
      const SizedBox(height: Dimensions.paddingSizeLarge),

      /// for Coupon add text field
      Consumer<CouponProvider>(
        builder: (context, coupon, child) {
          return IntrinsicHeight(
            child: Row(children: [
              /*Expanded(child: TextField(
                          controller: _couponController,
                          style: rubikRegular,
                          decoration: InputDecoration(
                            hintText: getTranslated('enter_promo_code', context),
                            hintStyle: rubikRegular.copyWith(color: ColorResources.getHintColor(context)),
                            isDense: true,
                            filled: true,
                            enabled: coupon.discount == 0,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(Provider.of<LocalizationProvider>(context, listen: false).isLtr ? 10 : 0),
                                right: Radius.circular(Provider.of<LocalizationProvider>(context, listen: false).isLtr ? 0 : 10),
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        )),*/

              Expanded(child: CustomTextFieldWidget(
                isShowBorder: true,
                hintText: getTranslated('enter_coupon', context),
                controller: widget._couponController,
                prefixIconUrl: Images.couponSvg,
                isShowPrefixIcon: true,
                prefixIconColor: Theme.of(context).hintColor.withOpacity(0.5),
                borderColor: Theme.of(context).hintColor.withOpacity(0.5),
              )),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

              InkWell(
                onTap: coupon.discount != 0 ? null : () {
                  if(widget._couponController.text.isNotEmpty && !coupon.isLoading) {
                    if(coupon.discount! < 1) {
                      coupon.applyCoupon(widget._couponController.text, widget.total).then((discount) {
                        context.pop();

                        if (discount! > 0) {
                          showCustomSnackBarHelper('${getTranslated('you_got', context)} ${PriceConverterHelper.convertPrice(discount)} ${getTranslated('discount', context)}', isError: false);
                        } else {
                          showCustomSnackBarHelper(getTranslated('invalid_code_or', context), isError: true);
                          widget._couponController.clear();
                        }
                      });
                    } else {
                      coupon.removeCouponData(true);
                    }
                  } else if(widget._couponController.text.isEmpty) {
                    showCustomSnackBarHelper(getTranslated('enter_a_Coupon_code', context));
                  }
                },
                child: Container(
                  width: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: coupon.discount! <= 0 ? !coupon.isLoading ? Text(
                    getTranslated('apply', context)!,
                    style: rubikSemiBold.copyWith(color: Colors.white),
                  ) : const Center(child: SizedBox(
                    width: Dimensions.paddingSizeLarge,
                    height: Dimensions.paddingSizeLarge,
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )) : InkWell(
                    onTap: () {
                      widget._couponController.clear();
                      coupon.removeCouponData(true);
                      showCustomSnackBarHelper(getTranslated('coupon_removed_successfully', context),isError: false);

                    },
                    child: const Icon(Icons.clear, color: Colors.white),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
      const SizedBox(height: Dimensions.paddingSizeLarge),

      Expanded(
        child: Consumer<CouponProvider>(
          builder: (context, coupon, child) {
            return coupon.couponList == null ? _CouponShimmerWidget(isEnabled: couponProvider.couponList == null) :
            (coupon.couponList?.isNotEmpty ?? false) ? RefreshIndicator(
              onRefresh: () async {
                await couponProvider.getCouponList();
              },
              backgroundColor: Theme.of(context).primaryColor,
              color: Theme.of(context).cardColor,
              child: SingleChildScrollView(child: Column(children: [

                Center(child: ListView.builder(
                  itemCount: coupon.couponList!.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge), child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: coupon.couponList![index].code ?? ''));
                        widget._couponController.text = coupon.couponList![index].code ?? '';
                        showCustomSnackBarHelper(getTranslated('coupon_code_copied', context), isError:  false);
                      },
                      child: Container(
                        height: 85,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ColorResources.getSecondaryColor(context).withOpacity(0.05),
                          border: Border.all(color: ColorResources.getSecondaryColor(context).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Row(children: [

                          const CustomAssetImageWidget(Images.applyPromo, height: 35, width: 35),
                          const SizedBox(width: Dimensions.paddingSizeDefault),

                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                              SelectableText(
                                coupon.couponList![index].code!,
                                style: rubikRegular.copyWith(),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              Text(
                                '${coupon.couponList![index].discount}${coupon.couponList![index].discountType == 'percent' ? '%'
                                    : splashProvider.configModel!.currencySymbol} off',
                                style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              Text(
                                '${getTranslated('valid_until', context)} ${DateConverterHelper.isoStringToLocalDateOnly(coupon.couponList![index].expireDate!)}',
                                style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                              ),
                            ]),
                          ),

                        ]),
                      ),
                    ));
                  },
                )),

              ])),
            ) : Column(children: [
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),
              SizedBox(
                height: size.height * 0.2, width: size.width * 0.2,
                child: const CustomAssetImageWidget(
                  Images.noCouponSvg,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              Text(
                getTranslated('no_promo_available', context)!,
                style: rubikSemiBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeLarge),
                textAlign: TextAlign.center,
              ),
            ]);
          },
        ),
      ),

    ]));
  }
}

class _CouponShimmerWidget extends StatelessWidget {
  const _CouponShimmerWidget({required this.isEnabled});
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      enabled: isEnabled,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge), child: Container(
            height: 85,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Row(children: [

              Container(color: Theme.of(context).shadowColor.withOpacity(0.2), height: 35, width: 35),
              const SizedBox(width: Dimensions.paddingSizeDefault),

              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(color: Theme.of(context).shadowColor.withOpacity(0.2), height: 15, width: 120),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Container(color: Theme.of(context).shadowColor.withOpacity(0.2), height: 15, width: 100),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Container(color: Theme.of(context).shadowColor.withOpacity(0.2), height: 15, width: 80),
                ]),
              ),

            ]),
          ));
        },
      ),
    );
  }
}
