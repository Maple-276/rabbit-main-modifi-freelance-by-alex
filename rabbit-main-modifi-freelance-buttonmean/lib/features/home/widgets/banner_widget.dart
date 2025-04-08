import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/cart_model.dart';
import 'package:flutter_restaurant/common/models/product_model.dart';
import 'package:flutter_restaurant/common/widgets/custom_image_widget.dart';
import 'package:flutter_restaurant/features/category/domain/category_model.dart';
import 'package:flutter_restaurant/features/category/providers/category_provider.dart';
import 'package:flutter_restaurant/features/home/providers/banner_provider.dart';
import 'package:flutter_restaurant/features/home/widgets/cart_bottom_sheet_widget.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// Widget that displays a promotional banner carousel
class BannerWidget extends StatefulWidget {
  const BannerWidget({super.key});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> with TickerProviderStateMixin {
  // State variables
  int _currentIndex = 0;
  
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _indicatorAnimationController;
  
  // Timers
  Timer? _autoPlayTimer;
  
  // Constants
  static const int _autoPlayDurationSeconds = 6;
  
  // Lista de claves de traducción para los banners
  final List<String> _bannerTitleKeys = [
    'banner_thirsty',
    'banner_desserts',
    'banner_healthy',
    'banner_fast_food',
    'banner_local_food'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize progress controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _autoPlayDurationSeconds),
    );
    
    // Initialize indicator animation controller
    _indicatorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Start animations and timer
    _progressController.forward();
    _startAutoPlayTimer();
  }
  
  void _startAutoPlayTimer() {
    _autoPlayTimer?.cancel();
    
    _autoPlayTimer = Timer.periodic(
      const Duration(seconds: _autoPlayDurationSeconds), 
      (_) {
        if (!mounted) return;
        
        _progressController.reset();
        _progressController.forward();
        _animateIndicator();
      }
    );
  }
  
  void _animateIndicator() {
    // Reset animation sequence
    _indicatorAnimationController.reset();
    
    // Show with animation
    _indicatorAnimationController.forward();
    
    // Hide after delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _indicatorAnimationController.reverse();
      }
    });
  }
  
  void _handlePageChange(int index) {
    if (!mounted) return;
    
    setState(() => _currentIndex = index);
    _progressController.reset();
    _progressController.forward();
    _animateIndicator();
  }
  
  void _handleBannerTap(BuildContext context, int? categoryId, int? productId) {
    if (categoryId != null && categoryId > 0) {
      // Navigate to category
      Provider.of<CategoryProvider>(context, listen: false).getCategoryList(true);
      RouterHelper.getCategoryRoute(CategoryModel(id: categoryId));
    } else if (productId != null) {
      // Navigate to product
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CartBottomSheetWidget(
          product: Product(id: productId),
          callback: (CartModel cartModel) {
            showCustomSnackBarHelper(
              getTranslated('added_to_cart', context) ?? 'Added to cart', 
              isError: false
            );
          },
        ),
      ));
    }
  }
  
  // Obtener texto traducido para el banner
  String _getTranslatedBannerTitle(BuildContext context, int index, String? originalTitle) {
    // Si no hay título original, usar una traducción de la lista de claves
    if (originalTitle == null || originalTitle.isEmpty) {
      final keyIndex = index % _bannerTitleKeys.length;
      return getTranslated(_bannerTitleKeys[keyIndex], context) ?? 
             'Discover our special offers';
    }
    
    // Intentar traducir el título original si parece ser una clave de traducción
    if (originalTitle.contains('_') && !originalTitle.contains(' ')) {
      final translatedText = getTranslated(originalTitle, context);
      if (translatedText != null && translatedText != originalTitle) {
        return translatedText;
      }
    }
    
    // Si todo lo demás falla, devolver el título original
    return originalTitle;
  }
  
  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _progressController.dispose();
    _indicatorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BannerProvider>(
      builder: (context, bannerProvider, _) {
        if (bannerProvider.bannerList == null) {
          return _buildLoadingWidget(context);
        }
        
        if (bannerProvider.bannerList!.isEmpty) {
          return const SizedBox();
        }
        
        return _buildBannerCarousel(context, bannerProvider);
      }
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Container(
      height: ResponsiveHelper.isDesktop(context) 
          ? 280 : MediaQuery.of(context).size.width * 0.35,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Shimmer(
        duration: const Duration(seconds: 2),
        enabled: true,
                          child: Container(
                            decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      );
  }

  Widget _buildBannerCarousel(BuildContext context, BannerProvider bannerProvider) {
    return Container(
      height: ResponsiveHelper.isDesktop(context) 
          ? 280 : MediaQuery.of(context).size.width * 0.35,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Stack(
        children: [
          // Carousel
                    CarouselSlider.builder(
            itemCount: bannerProvider.bannerList!.length,
                      options: CarouselOptions(
              height: ResponsiveHelper.isDesktop(context) 
                  ? 280 : MediaQuery.of(context).size.width * 0.35,
              viewportFraction: 1.0,
              initialPage: 0,
                        enableInfiniteScroll: true,
                        autoPlay: true,
              autoPlayInterval: const Duration(seconds: _autoPlayDurationSeconds),
              autoPlayAnimationDuration: const Duration(milliseconds: 500),
              enlargeCenterPage: false,
                        scrollDirection: Axis.horizontal,
              onPageChanged: (index, _) => _handlePageChange(index),
            ),
            itemBuilder: (_, index, __) {
              final banner = bannerProvider.bannerList![index];
              String? imagePath;
              try {
                imagePath = '${Provider.of<SplashProvider>(context, listen: false).baseUrls!.bannerImageUrl}/${banner.image}';
              } catch (e) {
                // Silently handle error, fallback to placeholder
                imagePath = null;
              }
              
              return GestureDetector(
                onTap: () => _handleBannerTap(context, banner.categoryId, banner.productId),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Banner Image
                        CustomImageWidget(
                          image: imagePath ?? '',
                          fit: BoxFit.cover,
                          placeholder: Images.placeholderBanner,
                        ),
                        
                        // Title Overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0.85),
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                            ),
                            child: Text(
                              _getTranslatedBannerTitle(context, index, banner.title),
                              style: rubikMedium.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.7),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Page indicator with smooth fade animation
          if (bannerProvider.bannerList!.length > 1)
            Positioned(
              bottom: 5,
              right: 5,
              child: FadeTransition(
                opacity: _indicatorAnimationController,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      SizedBox(
                        width: 40,
                        height: 3,
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Page counter
                      Text(
                        '${_currentIndex + 1}/${bannerProvider.bannerList!.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget para mostrar un shimmer mientras se carga el banner
class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    final bannerProvider = Provider.of<BannerProvider>(context, listen: false);

    return Shimmer(
      duration: const Duration(seconds: 2),
      enabled: bannerProvider.bannerList == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          _buildTitleShimmer(context),
          _buildContentShimmer(context),
        ]
      ),
    );
  }
  
  /// Construye el shimmer para el título
  Widget _buildTitleShimmer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault, 
        vertical: Dimensions.paddingSizeSmall
      ),
          child: Container(
            height: Dimensions.paddingSizeLarge,
            width: 150,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Theme.of(context).shadowColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
    );
  }

  /// Construye el shimmer para el contenido
  Widget _buildContentShimmer(BuildContext context) {
    return SizedBox(
          height: ResponsiveHelper.isDesktop(context)? 240 : 130,
      child: Row(
        children: [
          const SizedBox(width: Dimensions.paddingSizeLarge),
          Expanded(
            flex: 7, 
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Theme.of(context).shadowColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
            )
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          
          Expanded(
            flex: 3, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
                Expanded(
                  child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Theme.of(context).shadowColor.withOpacity(0.2),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(Dimensions.radiusDefault)
                      ),
                    ),
                  )
                ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Container(
                height: 10,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Theme.of(context).shadowColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
              ),
              ]
            )
          ),
        ]
      ),
    );
  }
}

