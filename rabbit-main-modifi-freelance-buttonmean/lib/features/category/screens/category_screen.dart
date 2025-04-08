import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/custom_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_loader_widget.dart';
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
import 'package:flutter_restaurant/common/providers/product_provider.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'dart:async';
import 'package:flutter_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:flutter_restaurant/features/search/providers/search_provider.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/common/widgets/enhanced_back_button.dart';

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
  String _type = 'all';
  final ScrollController _scrollController = ScrollController();
  
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

   categoryProvider.getCategoryList(false);
   categoryProvider.getSubCategoryList(widget.categoryId);
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
   final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
   final productProvider = Provider.of<ProductProvider>(context, listen: false);

   final Size size = MediaQuery.sizeOf(context);
   final double realSpaceNeeded = (size.width - Dimensions.webScreenWidth) / 2;
   final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: isDesktop ? const PreferredSize(preferredSize: Size.fromHeight(100), child: WebAppBarWidget()) : null,
      body: Consumer<CategoryProvider>(
        builder: (context, category, child) {
          return category.isLoading || category.categoryList == null ?
          _categoryShimmer(context, size.height, category) :
          PaginatedListWidget(
            scrollController: _scrollController,
            onPaginate: (int? offset) async {
             await category.getCategoryProductList('${category.selectedSubCategoryId}', offset ?? 1, type: _type);

            },
            totalSize: category.categoryProductModel?.totalSize,
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
                    // Search field in mobile app bar
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0, top: 8.0, bottom: 8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Consumer<SearchProvider>(
                          builder: (context, searchProvider, _) => CustomTextFieldWidget(
                            hintText: _getCurrentHintText(context),
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            radius: 50,
                            isShowBorder: true,
                            isShowPrefixIcon: true,
                            prefixIconUrl: Images.search,
                            prefixIconColor: Theme.of(context).primaryColor,
                            inputDecoration: InputDecoration(
                              fillColor: Theme.of(context).cardColor,
                              filled: true,
                              hintStyle: rubikRegular.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  width: 1,
                                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  width: 1,
                                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(
                                  width: 1, 
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                              // Indicator of progress
                              suffixIcon: Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
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
                                ],
                              ),
                            ),
                            onSubmit: (text) {
                              if(_searchController.text.trim().isNotEmpty) {
                                RouterHelper.getSearchResultRoute(_searchController.text);
                                searchProvider.searchDone();
                              }
                            },
                          ),
                        ),
                      ),
                    )
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
                      background: Container(height: 50, width : isDesktop ? Dimensions.webScreenWidth : MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.only(bottom: 50),
                        child: CustomImageWidget(
                          placeholder: Images.categoryBanner, fit: BoxFit.cover,
                          image: '${splashProvider.baseUrls?.categoryBannerImageUrl}/${widget.categoryBannerImage}',
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
                        onTap: (int index) {
                          _type = 'all';
                          _tabIndex = index;
                          if(index == 0) {
                            category.getCategoryProductList(widget.categoryId, 1);
                          }else {
                            category.getCategoryProductList(category.subCategoryList![index-1].id.toString(), 1);
                          }
                        },
                      ),
                    ):const SizedBox(),
                  ),
                ),

                SliverToBoxAdapter(child: FilterButtonWidget(
                  type: _type,
                  items: productProvider.productTypeList,
                  onSelected: (selected) {
                    _type = selected;
                    category.getCategoryProductList(category.selectedSubCategoryId, 1,  type: _type);
                  },
                )),

                SliverPadding(
                  padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.symmetric(
                    horizontal: realSpaceNeeded,
                    vertical: Dimensions.paddingSizeSmall,
                  ) : const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  sliver: category.categoryProductModel == null || (category.categoryProductModel?.products?.isNotEmpty ?? false) ? SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 5 : ResponsiveHelper.isTab(context) ? 3 : 2,
                      crossAxisSpacing: Dimensions.paddingSizeSmall,
                      mainAxisSpacing: Dimensions.paddingSizeSmall,
                      mainAxisExtent: 260,
                    ),
                    itemCount: category.categoryProductModel == null ? 10 : category.categoryProductModel!.products!.length,
                    itemBuilder: (context, index) {
                      if(category.categoryProductModel == null) {
                        return const ProductShimmerWidget(
                        isEnabled: true,
                        isList: false,
                        width: double.maxFinite,
                      );
                      }
                      return ProductCardWidget(
                        product: category.categoryProductModel!.products![index],
                        imageWidth: 260,
                      );
                    },
                  ) : const SliverToBoxAdapter(child: NoDataWidget(isFooter: false)),
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

  SingleChildScrollView _categoryShimmer(BuildContext context, double height, CategoryProvider category) {
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

  // Gets the translated hint text for the current index
  // If the translation is not available, returns a default text
  String _getCurrentHintText(BuildContext context) {
    String? translatedText = getTranslated(_searchHints[_currentHintIndex], context);
    
    // Check if the translation is valid or if we need to use fallback text
    // An invalid translation might contain underscores or be identical to the key
    if (translatedText == null || 
        translatedText.contains('_') || 
        translatedText == _searchHints[_currentHintIndex]) {
      return '¿Buscas algo delicioso?'; // Spanish fallback text
    }
    
    return translatedText;
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
