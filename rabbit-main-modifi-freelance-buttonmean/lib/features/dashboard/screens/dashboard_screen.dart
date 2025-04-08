import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/cart_button_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_pop_scope_widget.dart';
import 'package:flutter_restaurant/common/widgets/third_party_chat_widget.dart';
import 'package:flutter_restaurant/features/address/providers/location_provider.dart';
import 'package:flutter_restaurant/features/branch/providers/branch_provider.dart';
import 'package:flutter_restaurant/features/cart/providers/cart_provider.dart';
import 'package:flutter_restaurant/features/cart/screens/cart_screen.dart';
import 'package:flutter_restaurant/features/dashboard/widgets/bottom_nav_item_widget.dart';
import 'package:flutter_restaurant/features/home/screens/home_screen.dart';
import 'package:flutter_restaurant/features/menu/screens/menu_screen.dart';
import 'package:flutter_restaurant/features/order/providers/order_provider.dart';
import 'package:flutter_restaurant/features/order/screens/order_screen.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/features/wishlist/screens/wishlist_screen.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/app_localization.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';

import '../../../common/models/config_model.dart';
import '../../../helper/branch_helper.dart';

class DashboardScreen extends StatefulWidget {
  final int pageIndex;
  const DashboardScreen({super.key, required this.pageIndex});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  PageController? _pageController;
  int _pageIndex = 0;
  late List<Widget> _screens;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();



  @override
  void initState() {
    Provider.of<BranchProvider>(context,listen: false).getBranchValueList(context);
    super.initState();

    _pageIndex = widget.pageIndex;


    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final LocationProvider locationProvider = Provider.of<LocationProvider>(context, listen: false);


    if(splashProvider.policyModel == null) {
      Provider.of<SplashProvider>(context, listen: false).getPolicyPage();
    }
    HomeScreen.loadData(false);
    locationProvider.checkPermission(()=> locationProvider.getCurrentLocation(context, false).then((currentAddress) {
      locationProvider.onChangeCurrentAddress(currentAddress);
    }), canBeIgnoreDialog: true);


    Provider.of<OrderProvider>(context, listen: false).changeStatus(true);

    _setNearestBranch();
    _pageController = PageController(initialPage: widget.pageIndex);

    _screens = [
      const HomeScreen(false),
      const WishListScreen(),
      const CartScreen(),
      const OrderScreen(),
      MenuScreen(onTap: (int pageIndex) {
         _setPage(pageIndex);
      }),
    ];
  }


  Future<void> _setNearestBranch() async {
    try {
      final branchProvider = Provider.of<BranchProvider>(context, listen: false);
      final splashProvider = Provider.of<SplashProvider>(context, listen: false);

      // Get branch values sorted by distance
      List<BranchValue> branchValues = await branchProvider.getBranchValueList(context);
      branchProvider.updateBranchId(branchValues.first.branches!.id, );


      BranchHelper.setBranch(context,frmDashboard: true);


      // if (branchValues.isNotEmpty) {
      //   // Get the nearest branch (first in the sorted list)
      //   BranchValue nearestBranch = branchValues.first;
      //
      //   // Automatically set the nearest branch
      //   await branchProvider.setBranch(nearestBranch.branch!.id!, splashProvider);
      //
      //   // Notify listeners (optional if needed)
      //   branchProvider.notifyListeners();
      // }
    } catch (e) {
      debugPrint("Error setting nearest branch: $e");
    }
  }




  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    return CustomPopScopeWidget(
      isExit: _pageIndex == 0,
      onPopInvoked: () async {
        if (_pageIndex != 0) {
          _setPage(0);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        floatingActionButton: !ResponsiveHelper.isDesktop(context) && _pageIndex == 0
            ? Container(margin: const EdgeInsets.only(bottom: 80), child: const ThirdPartyChatWidget()) : null,



      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: ResponsiveHelper.isDesktop(context) ? 0 : defaultTargetPlatform == TargetPlatform.iOS ? 80 : 65),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _screens.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _screens[index];
              },
            ),
          ),

          ResponsiveHelper.isDesktop(context)  ? const SizedBox() : Align(
            alignment: Alignment.bottomCenter,
            child: Consumer<SplashProvider>(
                builder: (ctx, splashController, _) {

                  return Container(
                    width: size.width,
                    height: defaultTargetPlatform == TargetPlatform.iOS ? 80 : 65,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                    ),
                    child: Stack(children: [

                      Center(
                        heightFactor: 0.2,
                        child: CartButtonWidget(
                          onTap: () {
                            // Usar Future.microtask para evitar problemas con widgets desmontados
                            Future.microtask(() => _setPage(2));
                          },
                          size: 70,
                          icon: const CustomAssetImageWidget(
                            Images.order,
                            color: Colors.white,
                            height: 35,
                          ),
                          semanticLabel: getTranslated('cart', context),
                        ),
                      ),

                      ResponsiveHelper.isDesktop(context) ? const SizedBox() : Center(
                        child: SizedBox(
                          width: size.width, height: 80,
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                            BottomNavItemWidget(
                              title: getTranslated('home', context)!,
                              imageIcon: Images.homeSvg,
                              isSelected: _pageIndex == 0,
                              onTap: () => _setPage(0),
                            ),

                            BottomNavItemWidget(
                              title: getTranslated('favourite', context)!.toCapitalized(),
                              imageIcon: Images.favoriteSvg,
                              isSelected: _pageIndex == 1,
                              onTap: () => _setPage(1),
                            ),

                            Container(width: size.width * 0.2),

                            BottomNavItemWidget(
                              title: getTranslated('order', context)!,
                              imageIcon: Images.shopSvg,
                              isSelected: _pageIndex == 3,
                              onTap: () => _setPage(3),
                            ),

                            BottomNavItemWidget(
                              title: getTranslated('menu', context)!,
                              imageIcon: Images.menuSvg,
                              isSelected: _pageIndex == 4,
                              onTap: () => _setPage(4),
                            ),
                          ]),
                        ),
                      ),
                    ],
                    ),
                  );
                }
            ),
          ),

        ],
      ),
    ));
  }



  void _setPage(int pageIndex) {
    _pageController?.jumpToPage(pageIndex);
    setState(() {
      _pageIndex = pageIndex;
    });

  }
  
}


