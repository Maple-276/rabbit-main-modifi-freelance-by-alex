import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaurant/common/widgets/custom_loader_widget.dart';
import 'package:flutter_restaurant/helper/date_converter_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/coupon/providers/coupon_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:flutter_restaurant/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter_restaurant/common/widgets/footer_widget.dart';
import 'package:flutter_restaurant/common/widgets/no_data_widget.dart';
import 'package:flutter_restaurant/common/widgets/not_logged_in_widget.dart';
import 'package:flutter_restaurant/common/widgets/web_app_bar_widget.dart';
import 'package:provider/provider.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}
late bool _isLoggedIn;
class _CouponScreenState extends State<CouponScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isLoggedIn();
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    if(_isLoggedIn || splashProvider.configModel!.isGuestCheckout!) {
      Provider.of<CouponProvider>(context, listen: false).getCouponList();
    }
  }
  @override
  Widget build(BuildContext context) {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    double width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;


    return Scaffold(
      appBar: (ResponsiveHelper.isDesktop(context) ? const PreferredSize(preferredSize: Size.fromHeight(100), child: WebAppBarWidget()) : CustomAppBarWidget(context: context, title: getTranslated('coupon', context))) as PreferredSizeWidget?,
      body: (splashProvider.configModel!.isGuestCheckout! || _isLoggedIn) ? Consumer<CouponProvider>(
        builder: (context, coupon, child) {

          return coupon.couponList == null ? CustomLoaderWidget(color: Theme.of(context).primaryColor) : (coupon.couponList?.isNotEmpty ?? false) ? RefreshIndicator(
            onRefresh: () async {
              await coupon.getCouponList();
            },
            backgroundColor: Theme.of(context).primaryColor,
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: !ResponsiveHelper.isDesktop(context) && height < 600 ? height : height - 400),
                      child: Container(
                        padding: width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeLarge) : EdgeInsets.zero,
                        child: Container(
                          width: width > 700 ? 700 : width,
                          padding: width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : null,
                          decoration: width > 700 ? BoxDecoration(
                            color: Theme.of(context).canvasColor, borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 5, spreadRadius: 1)],
                          ) : null,
                          child: ListView.builder(
                            itemCount: coupon.couponList!.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                                child: InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: coupon.couponList![index].code ?? ''));
                                  },
                                  child: Stack(children: [

                                    Image.asset(Images.couponBg, height: 100, width: 1170, fit: BoxFit.fitWidth, color: Theme.of(context).primaryColor),

                                    Container(
                                      height: 100,
                                      alignment: Alignment.center,
                                      child: Row(children: [

                                        const SizedBox(width: 50),
                                        Image.asset(Images.percentage, height: 50, width: 50),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                                          child: Image.asset(Images.line, height: 100, width: 5),
                                        ),

                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                            SelectableText(
                                              coupon.couponList![index].code!,
                                              style: rubikRegular.copyWith(color: Colors.white),
                                            ),
                                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                            Text(
                                              '${coupon.couponList![index].discount}${coupon.couponList![index].discountType == 'percent' ? '%'
                                                  : Provider.of<SplashProvider>(context, listen: false).configModel!.currencySymbol} off',
                                              style: rubikSemiBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraLarge),
                                            ),
                                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                            Text(
                                              '${getTranslated('valid_until', context)} ${DateConverterHelper.isoStringToLocalDateOnly(coupon.couponList![index].expireDate!)}',
                                              style: rubikRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                                            ),
                                          ]),
                                        ),

                                          ]),
                                        ),

                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  if(ResponsiveHelper.isDesktop(context))  const FooterWidget()
                ],
              ),
            ),
          ) : const Center(child: NoDataWidget());
        },
      ) : const NotLoggedInWidget(),
    );
  }
}
