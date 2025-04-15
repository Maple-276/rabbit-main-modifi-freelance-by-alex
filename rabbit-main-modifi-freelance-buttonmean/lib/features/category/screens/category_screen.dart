import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/custom_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/filter_button_widget.dart';
import 'package:flutter_restaurant/common/widgets/footer_widget.dart';
import 'package:flutter_restaurant/common/widgets/no_data_widget.dart';
import 'package:flutter_restaurant/common/widgets/paginated_list_widget.dart';
import 'package:flutter_restaurant/common/widgets/product_shimmer_widget.dart';
import 'package:flutter_restaurant/common/widgets/web_app_bar_widget.dart';
import 'package:flutter_restaurant/features/category/providers/category_provider.dart';
import 'package:flutter_restaurant/features/home/widgets/product_card_widget.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'dart:async';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/common/widgets/enhanced_back_button.dart';
import 'package:flutter_restaurant/common/models/product_model.dart';
import 'package:flutter_restaurant/features/category/data/local/local_category_data.dart'; // Import local data

class CategoryScreen extends StatefulWidget {
  final String categoryId;
  final String? categoryName;
  final String? categoryBannerImage;
  const CategoryScreen({super.key, required this.categoryId, this.categoryName, this.categoryBannerImage});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with TickerProviderStateMixin {
  int _tabIndex = 0;
  String _selectedWeightFilter = 'all'; // 'all', 'small', 'medium', 'large'
  String _selectedVegFilter = 'all'; // 'all', 'veg', 'non_veg'
  final ScrollController _scrollController = ScrollController();
  
  // Define weight filter options and labels
  static const Map<String, String> _weightFilterOptions = {
    'all': 'Todos',
    'small': 'Pequeño', // <= 300
    'medium': 'Mediano', // > 300 && < 700
    'large': 'Grande', // >= 700
  };

  // Define vegetarian filter options and labels
  static const Map<String, String> _vegFilterOptions = {
    'all': 'Todos',
    'veg': 'Vegetariano',
    'non_veg': 'No Vegetariano',
  };
  
  // Variables for suggestion rotation functionality
  final List<String> _searchHints = [
    'are_you_hungry',
    'search_hint_thirsty',
    'search_hint_sweet_cravings',
    'search_hint_what_today',
    'search_hint_healthy',
    'search_hint_fast_food'
  ];
  
  int _currentHintIndex = 0;
  Timer? _hintRotationTimer;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  
  // Animation controllers
  late AnimationController _progressController;

 @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _loadData();
    
    // Start hint rotation
    _startHintRotation();
    _progressController.forward();
    
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _loadData() async {
   final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

   await categoryProvider.getCategoryList(false); // Add await here
   // Fetch all subcategories first
   categoryProvider.getSubCategoryList(widget.categoryId);
   // Then fetch all products for the main category initially
   await categoryProvider.getCategoryProductList(widget.categoryId, 1); // Removed type parameter
 }


 @override
  void dispose() {
    _scrollController.dispose();
    _hintRotationTimer?.cancel();
    _searchFocusNode.removeListener(_onFocusChange);
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   final Size size = MediaQuery.sizeOf(context);
   final double realSpaceNeeded = (size.width - Dimensions.webScreenWidth) / 2;
   final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: isDesktop ? const PreferredSize(preferredSize: Size.fromHeight(100), child: WebAppBarWidget()) : null,
      body: Consumer<CategoryProvider>(
        builder: (context, category, child) {
          // Determine if the current category is grocery
          final bool isGrocery = category.selectedSubCategoryId == groceryCategoryId;

          return category.isLoading || category.categoryList == null ?
          _categoryShimmer(context, size.height, category) :
          PaginatedListWidget(
            scrollController: _scrollController,
            onPaginate: (int? offset) async {
             // Pagination should respect the current filter - modify provider if needed
             // For client-side filtering, this might just fetch the next page of 'all' items
             await category.getCategoryProductList(
               '${category.selectedSubCategoryId}',
               offset ?? 1,
               // type: _selectedWeightFilter, // Remove type or ensure provider handles it for pagination
             );
            },
            totalSize: category.categoryProductModel?.totalSize, // Might need adjustment if filtering client-side
            offset: category.categoryProductModel?.offset,
            limit: category.categoryProductModel?.limit,
            isDisableWebLoader: !ResponsiveHelper.isDesktop(context),
            builder:(Widget loaderWidget)=> Expanded(child: CustomScrollView(
              controller: _scrollController,
              slivers: [

                SliverAppBar(
                  surfaceTintColor: Colors.transparent,
                  backgroundColor: Theme.of(context).cardColor,
                  expandedHeight: 200,
                  toolbarHeight: 80 + MediaQuery.of(context).padding.top,
                  pinned: true,
                  floating: false,
                  leadingWidth: 65,
                  leading: isDesktop ? const SizedBox() : const Padding(
                    padding: EdgeInsets.only(left: 10, top: 5),
                    child: EnhancedBackButton(
                      buttonColor: Colors.white,
                      iconSize: 20,
                      semanticLabel: 'Volver a la pantalla anterior',
                      isDarkBackground: true,
                    ),
                  ),
                  actions: !isDesktop ? [
                    // Replace search field with a simple search icon button
                    IconButton(
                      icon: Icon(Icons.search, color: Theme.of(context).textTheme.bodyLarge?.color),
                      tooltip: getTranslated('search', context),
                      onPressed: () {
                        RouterHelper.getSearchRoute();
                      },
                    ),
                  ] : null,
                  flexibleSpace: Container(
                    color:Theme.of(context).canvasColor,
                    margin: isDesktop? EdgeInsets.symmetric(horizontal: realSpaceNeeded) : const EdgeInsets.symmetric(horizontal: 0),
                    width: isDesktop ? Dimensions.webScreenWidth : MediaQuery.of(context).size.width,
                    child: FlexibleSpaceBar(
                      title: Text(widget.categoryName ?? '', style: rubikSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).cardColor,
                      )),
                      titlePadding: EdgeInsets.only(
                        bottom: 54 + (MediaQuery.of(context).padding.top/2),
                        left: 50,
                        right: 50,
                      ),
                      background: Container(
                        height: 50, 
                        width: isDesktop ? Dimensions.webScreenWidth : MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 50),
                        child: Consumer<SplashProvider>(
                          builder: (context, splashProvider, _) {
                            // Determine if the image is a local asset or a network URL
                            bool isLocalAsset = widget.categoryBannerImage != null && 
                                                widget.categoryBannerImage!.startsWith('assets/');
                            
                            if (isLocalAsset) {
                              // Use Image.asset for local assets
                              return Image.asset(
                                widget.categoryBannerImage!, 
                                fit: BoxFit.cover,
                                height: 50, // Apply height/width if needed
                                width: isDesktop ? Dimensions.webScreenWidth : MediaQuery.of(context).size.width,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  Images.categoryBanner, // Fallback placeholder
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              // Use CustomImageWidget for network images
                              String? imageUrl;
                              if (widget.categoryBannerImage != null && widget.categoryBannerImage!.isNotEmpty) {
                                imageUrl = '${splashProvider.baseUrls?.categoryBannerImageUrl}/${widget.categoryBannerImage}';
                              } else {
                                imageUrl = null; // Use placeholder if no banner is defined
                              }

                              return CustomImageWidget(
                                placeholder: Images.categoryBanner, 
                                fit: BoxFit.cover,
                                image: imageUrl ?? '', 
                              );
                            }
                          }
                        ),
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(30.0),
                    child: category.subCategoryList != null?Container(
                      width:  isDesktop ? Dimensions.webScreenWidth : MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0, // Adjust spread radius for shadow concentration
                            offset: const Offset(0, 10), // Shift shadow vertically downwards
                          ),
                        ],
                      ),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        controller: TabController(initialIndex: _tabIndex,
                            length: category.subCategoryList!.length+1, vsync: this),
                        isScrollable: true,
                        unselectedLabelColor: Theme.of(context).hintColor.withOpacity(0.7),
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorColor: Theme.of(context).primaryColor,
                        labelColor: Theme.of(context).textTheme.bodyLarge!.color,
                        tabs: _tabs(category),
                        onTap: (int index) async { // Make async
                          // Reset filter when changing tabs
                          _selectedWeightFilter = 'all';
                          _selectedVegFilter = 'all';
                          _tabIndex = index;
                          if(index == 0) {
                            // Fetch all products for the main category
                            await category.getCategoryProductList(widget.categoryId, 1); // Add await
                          }else {
                            // Fetch all products for the selected subcategory
                            await category.getCategoryProductList(category.subCategoryList![index-1].id.toString(), 1); // Add await
                          }
                        },
                      ),
                    ):const SizedBox(),
                  ),
                ),

                // Conditionally show filters
                SliverToBoxAdapter(child: isGrocery
                  ? FilterButtonWidget( // Show Size filter for Grocery
                      type: _weightFilterOptions[_selectedWeightFilter]!,
                      items: _weightFilterOptions.values.toList(),
                      onSelected: (selectedLabel) {
                        String selectedKey = _weightFilterOptions.entries
                            .firstWhere((entry) => entry.value == selectedLabel, orElse: () => _weightFilterOptions.entries.first)
                            .key;
                        setState(() {
                          _selectedWeightFilter = selectedKey;
                        });
                      },
                    )
                  : FilterButtonWidget( // Show Veg filter for non-Grocery
                      type: _vegFilterOptions[_selectedVegFilter]!, 
                      items: _vegFilterOptions.values.toList(),
                      onSelected: (selectedLabel) {
                        String selectedKey = _vegFilterOptions.entries
                            .firstWhere((entry) => entry.value == selectedLabel, orElse: () => _vegFilterOptions.entries.first)
                            .key;
                        setState(() {
                          _selectedVegFilter = selectedKey;
                        });
                      },
                    ),
                ),

                SliverPadding(
                  padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.symmetric(
                    horizontal: realSpaceNeeded,
                    vertical: Dimensions.paddingSizeSmall,
                  ) : const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  sliver: Builder( // Use Builder to access the latest category provider state
                    builder: (context) {
                      // Get potentially paginated but unfiltered list from provider
                      final allProductsInModel = category.categoryProductModel?.products ?? [];
                      
                      // Apply client-side filter based on category type
                      final filteredProducts = _getFilteredProducts(allProductsInModel, isGrocery);
                      
                      // Determine if we should show NoDataWidget
                      // Show NoData only if the model is loaded but the *filtered* list is empty
                      final bool showNoData = category.categoryProductModel != null && filteredProducts.isEmpty;
                      
                      return showNoData
                      ? const SliverToBoxAdapter(child: NoDataWidget(isFooter: false))
                      : SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisSpacing: Dimensions.paddingSizeSmall, mainAxisSpacing: Dimensions.paddingSizeSmall,
                          crossAxisCount: isDesktop ? 5 : ResponsiveHelper.isTab(context) ? 3 : 2,
                          mainAxisExtent: 260,
                        ),
                        // Use filtered list length. Handle null case for initial loading shimmer.
                        itemCount: category.categoryProductModel == null ? 10 : filteredProducts.length,
                        itemBuilder: (context, index) {
                          // Show shimmer if model is null (initial load)
                          if(category.categoryProductModel == null) {
                            return const ProductShimmerWidget(
                            isEnabled: true,
                            isList: false,
                            width: double.maxFinite,
                          );
                          }
                          // Use the filtered product list
                          // Add safety check in case itemCount calculation was off somehow during filtering
                          if (index >= filteredProducts.length) {
                            return const SizedBox.shrink(); // Should not happen
                          }
                          return ProductCardWidget(
                            product: filteredProducts[index],
                            imageWidth: 260,
                            isGroceryProduct: isGrocery, // Pass the flag based on ID comparison
                          );
                        },
                      );
                    }
                  ),
                ),


                if(ResponsiveHelper.isDesktop(context)) SliverToBoxAdapter(child: loaderWidget),



                if(isDesktop) const SliverToBoxAdapter(child: FooterWidget()),

              ],
            )),
          );
        },
      ),
    );
  }

  // Helper method to apply the correct filter based on category type
  List<Product> _getFilteredProducts(List<Product> allProducts, bool isGrocery) {
    if (isGrocery) { // Apply weight filter for Grocery
      if (_selectedWeightFilter == 'all') {
        return allProducts;
      }
      return allProducts.where((product) {
        // Use the actual weight field from the Product model
        final weight = product.weight; 
        if (weight == null) return false; // Skip products without weight data

        if (_selectedWeightFilter == 'small' && weight <= 300) return true;
        if (_selectedWeightFilter == 'medium' && weight > 300 && weight < 700) return true;
        if (_selectedWeightFilter == 'large' && weight >= 700) return true; 
        return false;
      }).toList();
    } else { // Apply vegetarian filter for non-Grocery
      if (_selectedVegFilter == 'all') {
        return allProducts;
      }
      return allProducts.where((product) {
        // Check the productType field (added in previous steps)
        bool isActuallyVeg = product.productType == 'veg'; // Example: 'veg' type
        if (_selectedVegFilter == 'veg' && isActuallyVeg) return true;
        if (_selectedVegFilter == 'non_veg' && !isActuallyVeg) return true;
        return false;
      }).toList();
    }
  }

  Widget _categoryShimmer(BuildContext context, double height, CategoryProvider category) {
   final isDesktop = ResponsiveHelper.isDesktop(context);

    return SingleChildScrollView(child: Column(children: [
      ConstrainedBox(
        constraints: BoxConstraints(minHeight: !isDesktop && height < 600 ? height : height - 400),
        child: Center(child: SizedBox(width: Dimensions.webScreenWidth, child: Column(children: [
          Shimmer(
            duration: const Duration(seconds: 2),
            enabled: true,
            child: Container(height: 200, width: double.infinity, color: Theme.of(context).shadowColor),
          ),
          GridView.builder(
            shrinkWrap: true,
            itemCount: 10,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: Dimensions.paddingSizeSmall, mainAxisSpacing: Dimensions.paddingSizeSmall,
              crossAxisCount: isDesktop ? 5 : ResponsiveHelper.isTab(context) ? 3 : 2,
              mainAxisExtent: isDesktop ? 260 : 260,
            ),
            itemBuilder: (context, index) {
              return ProductShimmerWidget(isEnabled: category.categoryProductModel == null, isList: false, width: double.maxFinite);
            },
          ),
        ]))),
      ),
      if(isDesktop) const FooterWidget(),
    ]));
  }

  List<Tab> _tabs(CategoryProvider category) {
    List<Tab> tabList = [];
    tabList.add(const Tab(text: 'All'));
    for (var subCategory in category.subCategoryList!) {
      tabList.add(Tab(text: subCategory.name));
    }
    return tabList;
  }

  // Method to handle focus changes in the search field
  void _onFocusChange() {
    if (mounted) {
      setState(() {
        // Stop rotation when field gains focus and has text
        if (_searchFocusNode.hasFocus && _searchController.text.trim().isNotEmpty) {
          _hintRotationTimer?.cancel();
          _progressController.stop();
        } else {
          // Restart rotation when focus is lost or when empty
          _startHintRotation();
        }
      });
    }
  }

  // Enhanced rotation method with animations
  void _startHintRotation() {
    // Cancel existing timers
    _hintRotationTimer?.cancel();
    _progressController.reset();
    
    // Start progress animation
    _progressController.forward();
    
    // Configure timer to change text and restart animations
    _hintRotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          // Change to next text
          _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
        });
        
        // Reset progress bar
        _progressController.reset();
        _progressController.forward();
      }
    });
  }
}
