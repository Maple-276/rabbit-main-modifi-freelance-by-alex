import 'package:flutter/material.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/order/providers/order_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/common/providers/theme_provider.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:flutter_restaurant/common/widgets/custom_button_widget.dart';
import 'package:flutter_restaurant/common/widgets/footer_widget.dart';
import 'package:flutter_restaurant/common/widgets/web_app_bar_widget.dart';
import 'package:flutter_restaurant/features/home/screens/home_screen.dart';
import 'package:provider/provider.dart';

class OrderSuccessfulScreen extends StatefulWidget {
  final String? orderID;
  final int status;
  const OrderSuccessfulScreen({super.key, required this.orderID, required this.status});

  @override
  State<OrderSuccessfulScreen> createState() => _OrderSuccessfulScreenState();
}

class _OrderSuccessfulScreenState extends State<OrderSuccessfulScreen> {
  bool _isReload = true;

  @override
  void initState() {
    ///delay for widget tree load and fix issue for notify controller
    Future.delayed(const Duration(milliseconds: 300)).then((_){
      HomeScreen.loadData(true);
    });    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if(_isReload && widget.status == 0) {
      Provider.of<OrderProvider>(context, listen: false).trackOrder(widget.orderID, fromTracking: false);
      _isReload = false;
    }
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: ResponsiveHelper.isDesktop(context) ? const PreferredSize(preferredSize: Size.fromHeight(100), child: WebAppBarWidget()) : null,
      body: SafeArea(
        child: Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              double total = 0;
              bool success = true;


              if(orderProvider.trackModel != null && Provider.of<SplashProvider>(context, listen: false).configModel!.loyaltyPointItemPurchasePoint != null) {
                total = ((orderProvider.trackModel?.orderAmount ?? 1) * (Provider.of<SplashProvider>(context, listen: false).configModel?.loyaltyPointItemPurchasePoint ?? 1) / 100);
              }

            return orderProvider.isLoading ? const Center(child: CircularProgressIndicator()) : ResponsiveHelper.isWeb() ? CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: OrderSuccessfulWidget(widget: widget, success: success, total: total, size: size)),

                if(ResponsiveHelper.isDesktop(context))  const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    SizedBox(height: Dimensions.paddingSizeLarge),

                    FooterWidget(),
                  ]),
                ),
              ],
            ): OrderSuccessfulWidget(widget: widget, success: success, total: total, size: size);
          }
        ),
      ),
    );
  }
}

class OrderSuccessfulWidget extends StatelessWidget {
  const OrderSuccessfulWidget({
    super.key,
    required this.widget,
    required this.success,
    required this.total,
    required this.size,
  });

  final OrderSuccessfulScreen widget;
  final bool success;
  final double total;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final OrderProvider orderProvider = Provider.of<OrderProvider>(context, listen:false);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Center(child: SizedBox(
          width: Dimensions.webScreenWidth,
          child: orderProvider.isLoading ? const CircularProgressIndicator() :  Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Container(
                height: 100, width: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.status == 0 ? Icons.check_circle : widget.status == 1 ? Icons.sms_failed : widget.status == 2 ? Icons.question_mark : Icons.cancel,
                  color: Theme.of(context).primaryColor, size: 80,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),


              Text(
                getTranslated(widget.status == 0 ? 'order_placed_successfully' : widget.status == 1 ? 'payment_failed' : widget.status == 2 ? 'order_failed' : 'payment_cancelled', context)!,
                style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              if(widget.status == 0) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${getTranslated('order_id', context)}:', style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Text('${widget.orderID}', style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
              ]),
              const SizedBox(height: 30),

              (widget.status == 0 && Provider.of<AuthProvider>(context, listen: false).isLoggedIn() && success && Provider.of<SplashProvider>(context).configModel!.loyaltyPointStatus!  && total.floor() > 0 )  ? Column(children: [

                Image.asset(
                  Provider.of<ThemeProvider>(context, listen: false).darkTheme
                      ? Images.gifBoxDark : Images.gifBox,
                  width: 150, height: 150,
                ),

                Text(getTranslated('congratulations', context)! , style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                  child: Text(
                    '${getTranslated('you_have_earned', context)!} ${total.floor().toString()} ${getTranslated('points_it_will_add_to', context)!}',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge,color: Theme.of(context).disabledColor),
                    textAlign: TextAlign.center,
                  ),
                ),

              ]) : const SizedBox.shrink() ,
              const SizedBox(height: Dimensions.paddingSizeDefault),

              if((orderProvider.trackModel?.orderType !='take_away') && widget.status == 0) SizedBox(
                width: ResponsiveHelper.isDesktop(context) ? 400 : size.width,
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: CustomButtonWidget(
                      btnTxt: getTranslated('track_order' , context),
                      onTap: () {
                        RouterHelper.getOrderTrackingRoute(int.tryParse('${widget.orderID}'));
                  }),
                ),
              ),

              SizedBox(
                width: ResponsiveHelper.isDesktop(context) ? 400 : size.width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                  child: CustomButtonWidget(
                    btnTxt: getTranslated('back_home', context),
                    onTap: ()=> RouterHelper.getDashboardRoute('home', action: RouteAction.pushNamedAndRemoveUntil),
                  ),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
