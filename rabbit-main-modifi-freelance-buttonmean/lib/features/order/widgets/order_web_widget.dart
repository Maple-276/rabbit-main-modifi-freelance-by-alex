import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/providers/theme_provider.dart';
import 'package:flutter_restaurant/common/widgets/footer_widget.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/order/providers/order_provider.dart';
import 'package:flutter_restaurant/features/order/widgets/order_list_web_widget.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';

class OrderWebWidget extends StatefulWidget {
  const OrderWebWidget({super.key, });

  @override
  State<OrderWebWidget> createState() => _OrderWebWidgetState();
}

class _OrderWebWidgetState extends State<OrderWebWidget> with TickerProviderStateMixin {

  late TabController _tabController;
  late bool _isLoggedIn;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _isLoggedIn = Provider.of<AuthProvider>(context, listen: false).isLoggedIn();
    if(_isLoggedIn) {
      _tabController = TabController(length: 2, initialIndex: _selectedIndex, vsync: this);
      Provider.of<OrderProvider>(context, listen: false).getOrderList(context);
    }

    _tabController.addListener(() {
      _selectedIndex = _tabController.index;
      if(mounted){
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return SingleChildScrollView(child: Column(children: [

      /*Center(
        child: Container(
          constraints: BoxConstraints(minHeight: ResponsiveHelper.isDesktop(context) ? size.height - 400 : size.height),
          width: Dimensions.webScreenWidth,
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 5, spreadRadius: 1)],
          ),
          child: Column(children: [

            Center(
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  border: Border.all(color: Theme.of(context).hintColor.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                margin: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
                child: TabBar(padding: EdgeInsets.zero, labelPadding: EdgeInsets.zero, controller: _tabController, indicatorWeight: 0.001, tabs: [

                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Container(
                      height: double.maxFinite, width: double.maxFinite,
                      margin: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        color: _selectedIndex == 0 ? Theme.of(context).primaryColor : Theme.of(context).canvasColor,
                      ),
                      child: Center(child: Text(
                        getTranslated('ongoing', context)!,
                        style: rubikRegular.copyWith(
                          color: _selectedIndex == 0 ? Theme.of(context).cardColor : Theme.of(context).primaryColor,
                        ),
                      )),
                    ),
                  ),

                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Container(
                      height: double.maxFinite, width: double.maxFinite,
                      margin: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        color: _selectedIndex == 1 ? Theme.of(context).primaryColor : Theme.of(context).canvasColor,
                      ),
                      child: Center(child: Text(
                        getTranslated('history', context)!,
                        style: rubikRegular.copyWith(
                          color: _selectedIndex == 1 ? Theme.of(context).cardColor : Theme.of(context).primaryColor,
                        ),
                      )),
                    ),
                  ),

                ]),
              ),
            ),

            Expanded(child: TabBarView(
              controller: _tabController,
              children: const [
                OrderListWebWidget(isRunning: true),
                OrderListWebWidget(isRunning: false),
              ],
            )),

          ]),
        ),
      ),*/

      Container(
        width: Dimensions.webScreenWidth,
        constraints: BoxConstraints(minHeight: ResponsiveHelper.isDesktop(context) ? size.height - 400 : size.height),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 5, spreadRadius: 1)],
        ),
        child: Column(children: [

          Center(child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: themeProvider.darkTheme ? Colors.white : Theme.of(context).hintColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            margin: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
            child: TabBar(
                padding: EdgeInsets.zero,
                labelPadding: EdgeInsets.zero,
                controller: _tabController,
                dividerHeight: 0,
                indicatorColor: Colors.transparent,
                indicatorWeight: 0.1,
                indicator: const UnderlineTabIndicator(borderSide: BorderSide.none),
                tabs: [

              Tab(
                iconMargin: EdgeInsets.zero,
                child: Container(
                  height: double.maxFinite, width: double.maxFinite,
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: _selectedIndex == 0 ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                  ),
                  child: Center(child: Text(
                    getTranslated('ongoing', context)!,
                    style: rubikRegular.copyWith(
                      color: _selectedIndex == 0 ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  )),
                ),
              ),

              Tab(
                iconMargin: EdgeInsets.zero,
                child: Container(
                  height: double.maxFinite, width: double.maxFinite,
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: _selectedIndex == 1 ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                  ),
                  child: Center(child: Text(
                    getTranslated('history', context)!,
                    style: rubikRegular.copyWith(
                      color: _selectedIndex == 1 ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  )),
                ),
              ),

            ]),
          )),

          SizedBox(height: 500, child: TabBarView(
            controller: _tabController,
            children: const [
              OrderListWebWidget(isRunning: true),
              OrderListWebWidget(isRunning: false),
            ],
          )),

        ]),
      ),

      const Padding(
        padding: EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        child: FooterWidget(),
      ),

    ]));
  }
}
