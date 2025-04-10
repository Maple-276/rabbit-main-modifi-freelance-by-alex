import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/enums/data_source_enum.dart';
import 'package:flutter_restaurant/common/providers/product_provider.dart';
import 'package:flutter_restaurant/common/widgets/branch_button_widget.dart';
import 'package:flutter_restaurant/common/widgets/branch_list_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/customizable_space_bar_widget.dart';
import 'package:flutter_restaurant/common/widgets/footer_widget.dart';
import 'package:flutter_restaurant/common/widgets/paginated_list_widget.dart';
import 'package:flutter_restaurant/common/widgets/sliver_delegate_widget.dart';
import 'package:flutter_restaurant/common/widgets/title_widget.dart';
import 'package:flutter_restaurant/common/widgets/web_app_bar_widget.dart';
import 'package:flutter_restaurant/features/address/providers/location_provider.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/branch/providers/branch_provider.dart';
import 'package:flutter_restaurant/features/cart/providers/cart_provider.dart';
import 'package:flutter_restaurant/features/cart/providers/frequently_bought_provider.dart';
import 'package:flutter_restaurant/features/category/providers/category_provider.dart';
import 'package:flutter_restaurant/features/category/domain/category_model.dart';
import 'package:flutter_restaurant/features/home/providers/banner_provider.dart';
import 'package:flutter_restaurant/features/home/widgets/banner_widget.dart';
import 'package:flutter_restaurant/features/home/widgets/category_web_widget.dart';
import 'package:flutter_restaurant/features/home/widgets/chefs_recommendation_widget.dart';
import 'package:flutter_restaurant/features/home/widgets/home_local_eats_widget.dart';
import 'package:flutter_restaurant/features/home/widgets/home_set_menu_widget.dart';
import 'package:flutter_restaurant/features/home/widgets/product_view_widget.dart';
import 'package:flutter_restaurant/features/home/widgets/sorting_button_widget.dart';
import 'package:flutter_restaurant/features/menu/widgets/options_widget.dart';
import 'package:flutter_restaurant/features/order/providers/order_provider.dart';
import 'package:flutter_restaurant/features/profile/providers/profile_provider.dart';
import 'package:flutter_restaurant/features/search/providers/search_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/features/wishlist/providers/wishlist_provider.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/main.dart';
import 'package:flutter_restaurant/utill/color_resources.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_restaurant/common/widgets/product_shimmer_widget.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';

import '../../../common/models/config_model.dart';

class HomeScreen extends StatefulWidget {
  final bool fromAppBar;
  const HomeScreen(this.fromAppBar, {super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static Future<void> loadData(bool reload, {bool isFcmUpdate = false}) async {
    print('---- HomeScreen.loadData called with reload: $reload ----');
    try {
      final ProductProvider productProvider = Provider.of<ProductProvider>(Get.context!, listen: false);
      final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(Get.context!, listen: false);
      final SplashProvider splashProvider = Provider.of<SplashProvider>(Get.context!, listen: false);
      final BannerProvider bannerProvider = Provider.of<BannerProvider>(Get.context!, listen: false);
      final ProfileProvider profileProvider = Provider.of<ProfileProvider>(Get.context!, listen: false);
      final WishListProvider wishListProvider = Provider.of<WishListProvider>(Get.context!, listen: false);
      final SearchProvider searchProvider = Provider.of<SearchProvider>(Get.context!, listen: false);
      final FrequentlyBoughtProvider frequentlyBoughtProvider = Provider.of<FrequentlyBoughtProvider>(Get.context!, listen: false);

      final isLogin = Provider.of<AuthProvider>(Get.context!, listen: false).isLoggedIn();

      if(isLogin){
        print('[loadData] Getting user info...');
        profileProvider.getUserInfo(reload, isUpdate: reload);
        if(isFcmUpdate){
          print('[loadData] Updating FCM token...');
          Provider.of<AuthProvider>(Get.context!, listen: false).updateToken();
        }
      }else{
        profileProvider.setUserInfoModel = null;
      }
      print('[loadData] Initializing wishlist...');
      wishListProvider.initWishList();

      if(productProvider.latestProductModel == null || reload) {
        print('[loadData] Getting latest products...');
        productProvider.getLatestProductList(1, reload);
      }

      if(reload || productProvider.popularLocalProductModel == null){
        print('[loadData] Getting popular local products...');
        productProvider.getPopularLocalProductList(1,  true, isUpdate: false);
      }

      if(reload) {
        print('[loadData] Getting policy page...');
        splashProvider.getPolicyPage();
      }
      print('[loadData] Getting category list...');
      categoryProvider.getCategoryList(reload);

      if(productProvider.flavorfulMenuProductMenuModel == null || reload) {
        print('[loadData] Getting flavorful menu...');
        productProvider.getFlavorfulMenuProductMenuList(1, reload);
      }

      if(productProvider.recommendedProductModel == null || reload) {
        print('[loadData] Getting recommended products...');
        productProvider.getRecommendedProductList(1, reload);
      }

      print('[loadData] Getting banner list...');
      bannerProvider.getBannerList(reload);
      print('[loadData] Getting cuisine list...');
      searchProvider.getCuisineList(isReload: reload);
      print('[loadData] Getting search recommendations...');
      searchProvider.getSearchRecommendedData(isReload: reload);
      print('[loadData] Getting frequently bought products...');
      frequentlyBoughtProvider.getFrequentlyBoughtProduct(1, reload);

      print('---- HomeScreen.loadData finished successfully ----');

    } catch (e, stackTrace) {
      print('!!!!!! ERROR IN HomeScreen.loadData !!!!!!');
      print(e);
      print(stackTrace);
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    }
  }
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> drawerGlobalKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _localEatsScrollController = ScrollController();
  final ScrollController _setMenuScrollController = ScrollController();
  final ScrollController _branchListScrollController = ScrollController();
  
  // The list of translation keys for search hints that will rotate automatically
  final List<String> _searchHints = [
    'are_you_hungry',
    'search_hint_thirsty',
    'search_hint_sweet_cravings',
    'search_hint_what_today',
    'search_hint_healthy',
    'search_hint_fast_food'
  ];
  
  // Current index of the hint being displayed
  int _currentHintIndex = 0;
  
  // Timer that controls the rotation of search hints
  Timer? _hintRotationTimer;
  
  // Animation controller for the progress indicator
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for the progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    final BranchProvider branchProvider = Provider.of<BranchProvider>(Get.context!, listen: false);
    branchProvider.getBranchValueList(context);
    _checkCoverage();
    
    // Start hint rotation and animation
    _startHintRotation();
    _progressController.forward();

    // ---> ADD THIS BLOCK TO CALL loadData <--- 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('*** Calling HomeScreen.loadData from initState ***');
      HomeScreen.loadData(true); 
    });
    // ---> END OF BLOCK <--- 
  }
  
  /**
   * Gets the current translated hint text based on the selected language.
   * Includes fallback mechanism for missing translations.
   * 
   * @param context The BuildContext to access the localization system
   * @return A properly translated hint text string
   */
  String _getCurrentHintText(BuildContext context) {
    String? translatedText = getTranslated(_searchHints[_currentHintIndex], context);
    
    // Check if translation is valid or fallback to default text
    if (translatedText == null || 
        translatedText.contains('_') || 
        translatedText == _searchHints[_currentHintIndex]) {
      return '¿Buscas algo delicioso?';
    }
    
    return translatedText;
  }
  
  /**
   * Starts or restarts the hint rotation system with the progress indicator.
   * This rotates through different search suggestions at a 5-second interval.
   */
  void _startHintRotation() {
    // Cancel any existing timer
    _hintRotationTimer?.cancel();
    _progressController.reset();
    
    // Start progress animation
    _progressController.forward();
    
    // Configure timer to change text and reset animations
    _hintRotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          // Move to next hint text
          _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
        });
        
        // Reset progress bar animation
        _progressController.reset();
        _progressController.forward();
      }
    });
  }

  Future<bool> _checkCoverage() async {
    try {
      final BranchProvider branchProvider = Provider.of<BranchProvider>(Get.context!, listen: false);
      bool inRange = false;

      if(branchProvider.branchValueList == null && mounted){
        await branchProvider.getBranchValueList(context);
      }

      // Get the nearest branch values sorted by distance
      List<BranchValue>? branchValues = branchProvider.branchValueList;

      if (branchValues != null && branchValues.isNotEmpty) {
        // Get the nearest branch details
        BranchValue? nearestBranch = branchValues.first;

        double? branchLatitude = double.tryParse(nearestBranch.branches?.latitude ?? '');
        double? branchLongitude = double.tryParse(nearestBranch.branches?.longitude ?? '');
        double? branchCoverage = nearestBranch.branches?.coverage;

        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        LatLng? userLocation = await locationProvider.getCurrentLatLong();

        if (branchLatitude != null && branchLongitude != null && userLocation != null && branchCoverage != null) {
          double distance = Geolocator.distanceBetween(
            branchLatitude,
            branchLongitude,
            userLocation.latitude,
            userLocation.longitude,
          ) / 1000; // Convert meters to kilometers

          debugPrint("Distancia al branch: $distance km");
          debugPrint("Cobertura del branch: $branchCoverage km");

          if (distance > branchCoverage) {
            debugPrint("Fuera de cobertura");
            inRange = false;

            // Show dialog if distance exceeds coverage
            if (mounted) {
              _showOutOfCoverageDialog();
            }
          } else {
            debugPrint("Dentro de cobertura");
            inRange = true;
          }
        }
      }

      return inRange;
    } catch (e) {
      debugPrint("Error al verificar cobertura: $e");
      
      // If there's any error, assume the user is in range to avoid blocking the app
      return true;
    }
  }

  void _showOutOfCoverageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Center(
            child: Text(
              'Servicio no disponible',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            )
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/image/coming-soon.png', height: 150), // Replace with your image path
              SizedBox(height: 20),
              Text(
                'Próximamente serviremos en tu ubicación.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              Text(
                'Lamentamos las molestias.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Entendido'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
          backgroundColor: Theme.of(context).cardColor,
          elevation: 10,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _localEatsScrollController.dispose();
    _setMenuScrollController.dispose();
    _branchListScrollController.dispose();
    _hintRotationTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      key: drawerGlobalKey,
      endDrawerEnableOpenDragGesture: false,
      drawer: ResponsiveHelper.isTab(context) ? const Drawer(child: OptionsWidget(onTap: null)) : const SizedBox(),
      appBar: isDesktop ? const PreferredSize(preferredSize: Size.fromHeight(100), child: WebAppBarWidget()) : null,
      body: RefreshIndicator(
        onRefresh: () async {
          Provider.of<OrderProvider>(context, listen: false).changeStatus(true, notify: true);
          Provider.of<SplashProvider>(context, listen: false).initConfig(context, DataSourceEnum.client).then((value) {
            if(value != null) {
              HomeScreen.loadData(true);
            }
          });
        },
        backgroundColor: Theme.of(context).primaryColor,
        color: Theme.of(context).cardColor,
        child: Consumer<ProductProvider>(builder: (context, productProvider, _)=> PaginatedListWidget(
          scrollController: _scrollController,
          onPaginate: (int? offset) async {
            await productProvider.getLatestProductList(offset ?? 1, false);
          },
          totalSize: productProvider.latestProductModel?.totalSize,
          offset: productProvider.latestProductModel?.offset,
          limit: productProvider.latestProductModel?.limit,
          isDisableWebLoader: !ResponsiveHelper.isDesktop(context),
          builder: (loaderWidget) {
            return Expanded(child: CustomScrollView(controller: _scrollController, slivers: [

              if(!isDesktop) SliverAppBar(
                pinned: true, toolbarHeight: Dimensions.paddingSizeDefault,
                automaticallyImplyLeading: false,
                expandedHeight: kIsWeb ? 90 : 70,
                floating: false, elevation: 0,
                backgroundColor: isDesktop ? Colors.transparent : Theme.of(context).primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero, centerTitle: true, expandedTitleScale: 1,
                  title: CustomizableSpaceBarWidget(builder: (context, scrollingRate)=> Center(child: Container(
                    width: Dimensions.webScreenWidth,
                    color: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.only(top: 30),
                    margin: const EdgeInsets.symmetric(horizontal:  Dimensions.paddingSizeDefault),
                    child: Opacity(
                      opacity: (1 - scrollingRate),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,   children: [
                        if(scrollingRate < 0.01)
                          Column(crossAxisAlignment: CrossAxisAlignment.start,  children: [
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            Text(getTranslated('current_location', context)!, style: rubikSemiBold.copyWith(
                              color: ColorResources.white,
                            )),

                            Row(children: [
                              Consumer<LocationProvider>(builder: (context, locationProvider, _) => Text(
                                (locationProvider.currentAddress?.isNotEmpty ?? false)
                                    ? locationProvider.currentAddress!.length > 32 ? '${locationProvider.currentAddress!.substring(0, 35)}...' : locationProvider.currentAddress! :
                                '',
                                style: rubikRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              )),
                              const SizedBox(width: Dimensions.fontSizeExtraSmall),

                            ]),
                          ]),

                        if(scrollingRate < 0.01)
                          Row( children: [
                            // const Padding(
                            //   padding: EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                            //   child: BranchButtonWidget(isRow: false, color: Colors.white),
                            // ),

                            ResponsiveHelper.isTab(context) ? InkWell(
                              onTap: () => RouterHelper.getDashboardRoute('cart'),
                              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                CountIconView(
                                  count: Provider.of<CartProvider>(context).cartList.length.toString(),
                                  icon: Icons.shopping_cart_outlined,
                                  color: ColorResources.white,
                                ),
                                const SizedBox(height: 3),

                                Text(
                                  getTranslated('cart', context)!,
                                  style:  rubikRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ]),
                            ) : const SizedBox(),
                          ]),
                      ]),
                    ),
                  ))),
                ),
              ),

              /// Search Button
              if(!isDesktop) SliverPersistentHeader(pinned: true, delegate: SliverDelegateWidget(
                child: Center(child: Stack(children: [
                  Container(
                    transform: Matrix4.translationValues(0, -2, 0),
                    height: 60, width: Dimensions.webScreenWidth,
                    color: Colors.transparent,
                    child: Column(children: [
                      Expanded(child: Container(color: Theme.of(context).primaryColor)),

                      Expanded(child: Container(color: Colors.transparent)),
                    ]),
                  ),

                  Positioned(
                    left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                    top: Dimensions.paddingSizeExtraSmall, bottom: Dimensions.paddingSizeExtraSmall,
                    child: InkWell(
                      onTap: () => RouterHelper.getSearchRoute(),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                        height: 50, width: Dimensions.webScreenWidth,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusLarge)),
                          border: Border.all(width: 1, color: Theme.of(context).primaryColor),
                        ),
                        child: Row(children: [
                          Padding(
                            padding: const EdgeInsets.only(left: Dimensions.paddingSizeLarge, right: Dimensions.paddingSizeSmall),
                            child: CustomAssetImageWidget(
                              Images.search, color: Theme.of(context).hintColor,
                              height: Dimensions.paddingSizeDefault,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _getCurrentHintText(context), 
                              style: rubikRegular.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              )
                            )
                          ),
                          // Progress indicator
                          Padding(
                            padding: const EdgeInsets.only(right: 15.0),
                            child: SizedBox(
                              width: 35,
                              height: 2,
                              child: LinearProgressIndicator(
                                value: _progressController.value,
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ])),
              )),

              /// for Web banner and category
              if(isDesktop)  SliverToBoxAdapter(child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault),
                  child: SizedBox(/*height: 300,*/ width: Dimensions.webScreenWidth, child: IntrinsicHeight(
                    child: Consumer<BannerProvider>(
                        builder: (context, bannerProvider, _) {
                          return Consumer<CategoryProvider>(
                              builder: (context, categoryProvider, _) {
                                return Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                                  (bannerProvider.bannerList?.isEmpty ?? false) ? const SizedBox() : (categoryProvider.categoryList?.isNotEmpty ?? false) ?
                                  const Expanded(flex: 6, child: SizedBox(child: BannerWidget())):
                                  const SizedBox(width: Dimensions.webScreenWidth / 1.5, child: BannerWidget()),




                                  const SizedBox(width: Dimensions.paddingSizeDefault),
                                  (categoryProvider.categoryList?.isNotEmpty ?? true) ?
                                  const Expanded(flex: 4, child: CategoryWebWidget())
                                      : const SizedBox(),
                                ]);
                              }
                          );
                        }
                    ),
                  )),
                ),
              )),

              /// for App banner and category
              if(!isDesktop) SliverToBoxAdapter(child: Column(children: [
                const BannerWidget(),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Container(
                  decoration: BoxDecoration(color: ColorResources.getTertiaryColor(context)),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: const CategoryWebWidget(),
                ),
              ])),

              /// for Local eats
              SliverToBoxAdapter(child: Consumer<ProductProvider>(
                  builder: (context, productProvider, _) {
                    return (productProvider.popularLocalProductModel?.products?.isEmpty ?? false) ? const SizedBox() :  HomeLocalEatsWidget(controller: _localEatsScrollController);
                  }
              )),

              /// for Set menu
              SliverToBoxAdapter(child: Consumer<ProductProvider>(
                  builder: (context, productProvider,_) {
                    return (productProvider.flavorfulMenuProductMenuModel?.products?.isEmpty ?? false) ? const SizedBox() : HomeSetMenuWidget(controller: _setMenuScrollController);
                  }
              )),

              /*SliverToBoxAdapter(child: Center(child: Container(
                      width: Dimensions.webScreenWidth,
                      color: Theme.of(context).cardColor,
                      // padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        isDesktop? const SetMenuWebWidget() :  const SetMenuWidget(),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                      ]),
                    ))),*/

              /// for web Chefs recommendation banner
              if(isDesktop) ...[
                SliverToBoxAdapter(child: Consumer<ProductProvider>(
                    builder: (context, productProvider, _) {
                      return (productProvider.recommendedProductModel?.products?.isEmpty ?? false) ? const SizedBox() : const ChefsRecommendationWidget();
                    }
                )),
                const SliverToBoxAdapter(child: SizedBox(height: Dimensions.paddingSizeLarge)),
              ],

              /// for Branch list
              // SliverToBoxAdapter(child: Consumer<BranchProvider>(
              //     builder: (context, branchProvider, _) {
              //       return (branchProvider.branchValueList?.isEmpty ?? false) ? const SizedBox() : Center(child: SizedBox(
              //         width: Dimensions.webScreenWidth,
              //         child: Padding(
              //           padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : Dimensions.paddingSizeSmall),
              //           child: BranchListWidget(controller: _branchListScrollController),
              //         ),
              //       ));
              //     }
              // )),

              /// for app Chefs recommendation banner
              if(!isDesktop)  SliverToBoxAdapter(child: Consumer<ProductProvider>(
                  builder: (context, productProvider,_) {
                    return (productProvider.recommendedProductModel?.products?.isEmpty ?? false) ? const SizedBox() : const ChefsRecommendationWidget();
                  }
              )),

              if(productProvider.latestProductModel == null || (productProvider.latestProductModel?.products?.isNotEmpty ?? false))
                SliverToBoxAdapter(child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                    width: Dimensions.webMaxWidth,
                    child: TitleWidget(
                      title: getTranslated(isDesktop ? 'latest_item' : 'all_foods', context),
                      trailingIcon: const SortingButtonWidget(),
                      isShowTrailingIcon: true,
                    ),
                  ),
                )),


              const ProductViewWidget(),

              if(ResponsiveHelper.isDesktop(context)) SliverToBoxAdapter(child: loaderWidget),


              if(isDesktop) const SliverToBoxAdapter(child: FooterWidget()),

            ]));
          },
        )),
      ),
    );
  }

  Widget _buildSubCategoryGrid(BuildContext context) {
    // DIRECT ACCESS TO PRIVATE VARIABLES (NOT RECOMMENDED - ONLY FOR DEBUG/WORKAROUND)
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        // --- Filter subcategories directly here --- 
        List<CategoryModel>? subCategoryList;
        // Use categoryProvider.categoryList and the correct getter for the selected category ID
        if (categoryProvider.categoryList != null && categoryProvider.selectCategory != -1) { // Use selectCategory and check if it's valid (-1 might be initial state)
          subCategoryList = categoryProvider.categoryList!
              .where((cat) => cat.parentId == categoryProvider.selectCategory) // Use selectCategory here
              .toList();
        } else if (categoryProvider.categoryList != null && categoryProvider.selectCategory == -1 && categoryProvider.categoryList!.isNotEmpty) {
           // Optional: If no category is selected (-1), maybe show subcategories of the first top-level category?
           // Or simply leave subCategoryList null/empty
           final firstTopLevel = categoryProvider.categoryList!.firstWhere((c) => c.parentId == 0 || c.parentId == null, orElse: () => CategoryModel(id: -1));
           if(firstTopLevel.id != -1) {
             subCategoryList = categoryProvider.categoryList!
                 .where((cat) => cat.parentId == firstTopLevel.id) 
                 .toList();
           }
        }
        // --- End filtering --- 

        // Show shimmer if loading OR if the main category list is still loading initially
        if (categoryProvider.isLoading || (categoryProvider.categoryList == null && categoryProvider.isLoading)) {
           // Use a Grid Shimmer layout
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeLarge),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.isDesktop(context) ? 6 : ResponsiveHelper.isTab(context) ? 4 : 3,
                crossAxisSpacing: Dimensions.paddingSizeSmall,
                mainAxisSpacing: Dimensions.paddingSizeSmall,
                childAspectRatio: 1.0, // Adjust aspect ratio as needed
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => const ProductShimmerWidget(isEnabled: true, isList: false, width: double.infinity), 
                childCount: 6, // Show a few shimmer items
              ),
            ),
          );
        }

        // Show message if list is empty after loading
        if (subCategoryList == null || subCategoryList.isEmpty) {
          return SliverToBoxAdapter(child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Text(getTranslated('no_subcategories_available', context) ?? 'No subcategories found'),
            ),
          ));
        }

        // Build the GridView for subcategories (uses the locally filtered subCategoryList)
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeLarge),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( 
              crossAxisCount: ResponsiveHelper.isDesktop(context) ? 6 : ResponsiveHelper.isTab(context) ? 4 : 3,
              crossAxisSpacing: Dimensions.paddingSizeSmall,
              mainAxisSpacing: Dimensions.paddingSizeSmall,
              childAspectRatio: 1.0,
            ),
            itemCount: subCategoryList.length,
            itemBuilder: (context, index) {
              // Add Null Check with !
              CategoryModel subCategory = subCategoryList![index]; 
              return InkWell(
                onTap: () {
                   RouterHelper.getCategoryRoute(subCategory);
                },
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                 child: Container(
                   decoration: BoxDecoration(
                     color: Theme.of(context).cardColor,
                     borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                     boxShadow: [BoxShadow(
                       color: Theme.of(context).shadowColor.withOpacity(0.05),
                       blurRadius: 5, spreadRadius: 1, offset: const Offset(0, 2),
                     )],
                   ),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       ClipRRect(
                         borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                         child: CustomAssetImageWidget(
                           subCategory.image != null && subCategory.image!.isNotEmpty
                               ? '${Provider.of<SplashProvider>(context, listen: false).baseUrls?.categoryImageUrl}/${subCategory.image}'
                               : Images.placeholderImage,
                           width: 50, height: 50, fit: BoxFit.cover, 
                         ),
                       ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                         child: Text(
                           subCategory.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                           textAlign: TextAlign.center,
                           style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                         ),
                       ),
                     ],
                   ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/**
 * Enhanced back button component for the Categories screen that offers improved 
 * visibility, state management, and accessibility.
 * 
 * This component provides:
 * - High visual contrast with the background
 * - Safe navigation handling
 * - Touch feedback
 * - Accessibility support
 * - Responsive sizing
 */
class EnhancedBackButton extends StatelessWidget {
  /// Optional callback to execute before navigation
  final VoidCallback? onBeforeNavigate;
  
  /// Optional custom color for the button
  final Color? buttonColor;
  
  /// Icon size, defaults to 24.0
  final double iconSize;
  
  /// Semantic label for accessibility, defaults to 'Back'
  final String semanticLabel;

  /// Constructor with named parameters
  const EnhancedBackButton({
    Key? key,
    this.onBeforeNavigate,
    this.buttonColor,
    this.iconSize = 24.0,
    this.semanticLabel = 'Back',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get theme colors to ensure optimal contrast
    final ThemeData theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    
    // Calculate final button color with proper contrast
    final Color finalButtonColor = buttonColor ?? 
                      (ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark 
                          ? Colors.white 
                          : theme.primaryColor);
    
    return SafeArea(
      // SafeArea ensures the button is positioned properly on all screen sizes
      child: Semantics(
        // Semantics improves accessibility for screen readers
        label: semanticLabel,
        button: true,
        enabled: true,
        onTap: () => _handleBackNavigation(context),
        child: Container(
          // Provide ample touch target (48x48 following Material guidelines)
          margin: const EdgeInsets.only(left: 8.0, top: 8.0),
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(
            // Circular background with subtle shadow for better visibility
            color: backgroundColor.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            // Material provides ripple effect feedback
            color: Colors.transparent,
            child: InkWell(
              // InkWell provides touch feedback
              customBorder: const CircleBorder(),
              onTap: () => _handleBackNavigation(context),
              child: Center(
                child: Icon(
                  // Using the more visible variant of back icon
                  Icons.arrow_back_ios_new_rounded,
                  color: finalButtonColor,
                  size: iconSize,
                  semanticLabel: semanticLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Safely handles back navigation with proper error handling
  void _handleBackNavigation(BuildContext context) {
    try {
      // Execute any pre-navigation callback if provided
      if (onBeforeNavigate != null) {
        onBeforeNavigate!();
      }
      
      // Check if navigation is possible before attempting to pop
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else {
        // If we can't pop (e.g., this is the root), consider alternative navigation
        // This prevents exceptions when the navigation stack is empty
        debugPrint('Warning: Cannot navigate back from this screen - no parent routes');
      }
    } catch (e) {
      // Catch and log any navigation errors
      debugPrint('Error during back navigation: $e');
      
      // Attempt an alternative safe navigation approach if the standard one fails
      if (context.mounted) {
        Navigator.maybePop(context);
      }
    }
  }
}



