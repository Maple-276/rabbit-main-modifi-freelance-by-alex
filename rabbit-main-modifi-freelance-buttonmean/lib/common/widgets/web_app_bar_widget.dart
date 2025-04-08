import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/language_model.dart';
import 'package:flutter_restaurant/common/providers/theme_provider.dart';
import 'package:flutter_restaurant/common/widgets/branch_button_widget.dart';
import 'package:flutter_restaurant/common/widgets/cart_button_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:flutter_restaurant/common/widgets/on_hover_widget.dart';
import 'package:flutter_restaurant/common/widgets/theme_switch_button_widget.dart';
import 'package:flutter_restaurant/features/address/providers/location_provider.dart';
import 'package:flutter_restaurant/features/cart/providers/cart_provider.dart';
import 'package:flutter_restaurant/features/category/domain/category_model.dart';
import 'package:flutter_restaurant/features/category/providers/category_provider.dart';
import 'package:flutter_restaurant/features/home/widgets/cetegory_hover_widget.dart';
import 'package:flutter_restaurant/features/home/widgets/language_hover_widget.dart';
import 'package:flutter_restaurant/features/language/providers/language_provider.dart';
import 'package:flutter_restaurant/features/language/providers/localization_provider.dart';
import 'package:flutter_restaurant/features/profile/providers/profile_provider.dart';
import 'package:flutter_restaurant/features/search/providers/search_provider.dart';
import 'package:flutter_restaurant/features/search/widget/search_recommended_widget.dart';
import 'package:flutter_restaurant/features/search/widget/search_suggestion_widget.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/features/wishlist/providers/wishlist_provider.dart';
import 'package:flutter_restaurant/helper/debounce_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/app_constants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';


class WebAppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  const    WebAppBarWidget({super.key});

  @override
  State<WebAppBarWidget> createState() => _WebAppBarWidgetState();

  @override
  Size get preferredSize => throw UnimplementedError();
}

class _WebAppBarWidgetState extends State<WebAppBarWidget> with TickerProviderStateMixin {
  final GlobalKey _searchBarKey = GlobalKey();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _appbarSearchFocusNode = FocusNode();
  
  // Usar claves de traducción en lugar de textos estáticos
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
  
  // Controladores para animaciones
  late AnimationController _progressController;
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    
    // Forzar el índice a 0 para asegurar que siempre se muestre el primer texto
    _currentHintIndex = 0;
    
    // Inicializar controladores de animación
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Iniciar con una breve demora para dar tiempo a que las traducciones se carguen
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _startHintRotation();
        _progressController.forward();
      }
    });
    
    _appbarSearchFocusNode.addListener(_onFocusChange);
    _searchFocusNode.addListener(_onFocusChange);
    
    // Agregamos listener al controlador de texto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final SearchProvider searchProvider = Provider.of<SearchProvider>(context, listen: false);
        searchProvider.searchController.addListener(_onTextChange);
      }
    });
  }

  @override
  void dispose() {
    _hintRotationTimer?.cancel();
    _appbarSearchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.removeListener(_onFocusChange);
    _progressController.dispose();
    _fadeController.dispose();
    
    // Eliminamos el listener al destruir el widget
    final SearchProvider searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.searchController.removeListener(_onTextChange);
    
    super.dispose();
  }
  
  void _onFocusChange() {
    if (mounted) {
      setState(() {
        // Detener la rotación cuando el campo obtiene el foco y tiene texto
        if ((_appbarSearchFocusNode.hasFocus && Provider.of<SearchProvider>(context, listen: false).searchController.text.trim().isNotEmpty) || 
            (_searchFocusNode.hasFocus && Provider.of<SearchProvider>(context, listen: false).searchController.text.trim().isNotEmpty)) {
          _hintRotationTimer?.cancel();
          _progressController.stop();
        } else {
          // Reiniciar la rotación cuando pierde el foco o cuando está vacío
          _startHintRotation();
        }
      });
    }
  }

  // Método mejorado de rotación con animaciones
  void _startHintRotation() {
    // Cancelar temporizadores existentes
    _hintRotationTimer?.cancel();
    _progressController.reset();
    
    // Iniciar animación de progreso
    _progressController.forward();
    
    // Configurar el temporizador para cambiar el texto y reiniciar las animaciones
    _hintRotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        // Animar desvanecimiento de texto actual
        _fadeController.forward().then((_) {
          setState(() {
            // Cambiar al siguiente texto
            _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
          });
          
          // Mostrar nuevo texto con animación
          _fadeController.reverse();
          
          // Reiniciar barra de progreso
          _progressController.reset();
          _progressController.forward();
        });
      }
    });
  }

  // Método para manejar cambios en el texto
  void _onTextChange() {
    if (mounted) {
      setState(() {
        final SearchProvider searchProvider = Provider.of<SearchProvider>(context, listen: false);
        if (searchProvider.searchController.text.trim().isNotEmpty) {
          _hintRotationTimer?.cancel();
          _progressController.stop();
        } else if (_hintRotationTimer == null || !_hintRotationTimer!.isActive) {
          _startHintRotation();
        }
      });
    }
  }

  Future<void> _showSearchDialog() async {
    final SearchProvider searchProvider = Provider.of(context, listen: false);
    RenderBox renderBox = _searchBarKey.currentContext!.findRenderObject() as RenderBox;
    final searchBarPosition = renderBox.localToGlobal(Offset.zero);
    final DebounceHelper debounce = DebounceHelper(milliseconds: 500);
    searchProvider.initHistoryList();
    searchProvider.onClearSearchSuggestion();

    if(searchProvider.searchController.text.isNotEmpty) {
      searchProvider.onChangeAutoCompleteTag(searchText: searchProvider.searchController.text);
    }

    // Cancelar cualquier temporizador activo para evitar cambios no deseados
    _hintRotationTimer?.cancel();
    
    // Forzar al primer índice (que muestra "¿Buscas algo delicioso?")
    setState(() {
      _currentHintIndex = 0;
    });

    Future.delayed(const Duration(milliseconds: 200)).then((_){
      _searchFocusNode.requestFocus();
    });

    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(children: [
        Positioned(
          top: searchBarPosition.dy,
          left: searchBarPosition.dx - 50,
          width: renderBox.size.width + 100,
          child: Material(
            color: Provider.of<ThemeProvider>(context, listen: false).darkTheme ? Theme.of(context).cardColor : null,
            elevation: 0,
            borderRadius: BorderRadius.circular(30),
            child: Consumer<SearchProvider>(builder: (context, searchProvider,_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 410, height: 40,
                  child: CustomTextFieldWidget(
                    radius: 50,
                    hintText: _getCurrentHintText(context),
                    isShowBorder: true,
                    fillColor: Theme.of(context).cardColor,
                    isShowPrefixIcon: searchProvider.searchLength == 0,
                    prefixIconUrl: Images.search,
                    prefixIconColor: Theme.of(context).primaryColor,
                    suffixIconColor: Theme.of(context).hintColor,
                    inputDecoration: InputDecoration(
                      hintText: _getCurrentHintText(context),
                      hintStyle: rubikRegular.copyWith(
                        fontSize: Dimensions.fontSizeLarge + 3,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                        fontStyle: FontStyle.italic,
                        overflow: TextOverflow.ellipsis
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
                      fillColor: Theme.of(context).cardColor,
                      filled: true,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
                      // Indicador de progreso
                      suffixIcon: searchProvider.searchLength == 0 ? Stack(
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
                      ) : null,
                    ),
                    onChanged: (str){
                      searchProvider.getSearchText(str);
                      debounce.run(() {
                        if(str.isNotEmpty) {
                          searchProvider.onChangeAutoCompleteTag(searchText: str);
                        }
                      });

                    },
                    focusNode: _searchFocusNode,
                    controller: searchProvider.searchController,
                    inputAction: TextInputAction.search,
                    isIcon: true,
                    isShowSuffixIcon: searchProvider.searchLength > 0,
                    suffixIconUrl: Images.cancelSvg,
                    onSuffixTap: (){
                      searchProvider.searchController.clear();
                      searchProvider.getSearchText('');

                    },

                    onSubmit: (text) {
                      if (searchProvider.searchController.text.isNotEmpty) {
                        RouterHelper.getSearchResultRoute(searchProvider.searchController.text);
                        searchProvider.searchDone();
                      }
                    },
                  ),
                ),
                // Recent Searches and Recommendations
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Container(
                  width: 600,
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),

                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [BoxShadow(
                        color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.05),
                        offset: const Offset(0, 5),
                        spreadRadius: 0,
                        blurRadius: 15,
                      )]
                  ),
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge, horizontal: 30),
                  child:  searchProvider.searchLength > 0
                      ?  SearchSuggestionWidget(searchedText: searchProvider.searchController.text)
                      : const SearchRecommendedWidget(),
                ),
              ],
            )
            ),
          ),
        ),

      ]),
    );


  }

  // Método para obtener el texto de sugerencia actual
  String _getCurrentHintText(BuildContext context) {
    String? translatedText = getTranslated(_searchHints[_currentHintIndex], context);
    
    // Si el texto contiene guiones bajos o es exactamente igual a la clave
    // probablemente la traducción no esté lista
    if (translatedText == null || 
        translatedText.contains('_') || 
        translatedText == _searchHints[_currentHintIndex]) {
      return '¿Buscas algo delicioso?';
    }
    
    return translatedText;
  }

  // Widget para mostrar el texto de sugerencia con animación
  Widget _buildAnimatedHintText(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Text(
        _getCurrentHintText(context),
        style: rubikRegular.copyWith(
          fontSize: Dimensions.fontSizeLarge + 3,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          fontStyle: FontStyle.italic,
          overflow: TextOverflow.ellipsis
        ),
      ),
    );
  }

  List<PopupMenuEntry<Object>> popUpMenuList(BuildContext context) {
    List<PopupMenuEntry<Object>> list = <PopupMenuEntry<Object>>[];
    List<CategoryModel>? categoryList =  Provider.of<CategoryProvider>(context, listen: false).categoryList;
    list.add(
        PopupMenuItem(
          padding: EdgeInsets.zero,
          value: categoryList,
          child: MouseRegion(
            onExit: (_)=> context.pop(),
            child: CategoryHoverWidget(categoryList: categoryList),
          ),
        ));
    return list;
  }

  List<PopupMenuEntry<Object>> popUpLanguageList(BuildContext context) {
    List<PopupMenuEntry<Object>> languagePopupMenuEntryList = <PopupMenuEntry<Object>>[];
    List<LanguageModel> languageList =  AppConstants.languages;
    languagePopupMenuEntryList.add(
        PopupMenuItem(
          padding: EdgeInsets.zero,
          value: languageList,
          child: MouseRegion(
            onExit: (_)=> context.pop(),
            child: LanguageHoverWidget(languageList: languageList),
          ),
        ));
    return languagePopupMenuEntryList;
  }



  _showPopupMenu(Offset offset, BuildContext context, bool isCategory) async {
    double left = offset.dx;
    double top = offset.dy;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    List<CategoryModel>? categoryList =  Provider.of<CategoryProvider>(context, listen: false).categoryList;
    if(isCategory && (categoryList?.isNotEmpty ?? false) || !isCategory) {
      await showMenu(
        context: context,
        position: RelativeRect.fromLTRB(left, top, overlay.size.width, overlay.size.height),
        items: isCategory ? popUpMenuList(context) : popUpLanguageList(context),
        elevation: 8.0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(Dimensions.radiusDefault),
          ),
        ),

      );

    }


  }

  @override
  Widget build(BuildContext context) {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final ProfileProvider profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    Provider.of<LanguageProvider>(context, listen: false).initializeAllLanguages(context);
    final LanguageModel currentLanguage = AppConstants.languages.firstWhere((language) => language.languageCode == Provider.of<LocalizationProvider>(context, listen: false).locale.languageCode);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(
          blurRadius: 15, offset: const Offset(0, 5),
          color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.05),
        )],
      ),
      child: Column(children: [

        Center(child: SizedBox( width: Dimensions.webScreenWidth, child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

            if(!splashProvider.isRestaurantOpenNow(context))
              Text('${getTranslated('restaurant_is_close_now', context)}', style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge)),

            if(splashProvider.isRestaurantOpenNow(context)) Consumer<LocationProvider>(
              builder: (context, locationProvider, _) {
                return locationProvider.address!.isNotEmpty ? locationProvider.isLoading ? const SizedBox() : Row(children: [
                  CustomAssetImageWidget(
                    Images.locationPlacemarkSvg, color: Theme.of(context).primaryColor,
                    width: Dimensions.paddingSizeDefault, height: Dimensions.paddingSizeDefault,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),


                  Text(locationProvider.currentAddress ?? '', style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),

                ]) : const SizedBox();
              },
            ),

            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const ThemeSwitchButtonWidget(),
              const SizedBox(width: Dimensions.paddingSizeExtraLarge),

              if(AppConstants.languages.length > 1) SizedBox(
                height: Dimensions.paddingSizeLarge,
                child: OnHoverWidget(
                  builder: (isHovered) {
                    final color = isHovered ? Theme.of(context).primaryColor : Theme.of(context).textTheme.titleLarge?.color;

                    return MouseRegion(
                      onHover: (details) {
                        _showPopupMenu(details.position, context, false);
                      },
                      child: Row(children: [
                        Text('${currentLanguage.languageCode?.toUpperCase()}', style: rubikSemiBold.copyWith(
                          color: color, fontSize: Dimensions.fontSizeExtraSmall,
                        )),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                        Icon(Icons.expand_more, color: color, size: Dimensions.paddingSizeLarge)
                      ]),
                    );
                  },
                ),
              ),
            ]),
          ]),
        ))),

        Container(height: 0.5, color: Theme.of(context).dividerColor.withOpacity(0.2)),

        Expanded(child: Center(child: SizedBox(width: Dimensions.webScreenWidth, child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          InkWell(
            onTap: () {
              RouterHelper.getMainRoute(action: RouteAction.pushReplacement);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Provider.of<SplashProvider>(context).baseUrls != null?  Consumer<SplashProvider>(
                builder:(context, splash, child) => CustomImageWidget(
                  image: '${splash.baseUrls?.restaurantImageUrl}/${splash.configModel!.restaurantLogo}',
                  placeholder: Images.webAppBarLogo,
                  fit: BoxFit.contain,
                  width: 120, height: 80,
                )): const SizedBox(),
            ),
          ),

          OnHoverWidget(builder: (isHover)=> InkWell(
            onTap: () =>RouterHelper.getHomeRoute(fromAppBar: 'true'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Text(
                getTranslated('home', context)!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: rubikRegular.copyWith(
                  color: isHover ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          )),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: MouseRegion(
              onHover: (details) {
                if(categoryProvider.categoryList != null) {
                  _showPopupMenu(details.position, context, true);
                }
              },
              child: OnHoverWidget(builder: (isHover)=> Text(
                getTranslated('categories', context)!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: rubikRegular.copyWith(
                  color: isHover ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              )),
            ),
          ),

          const Spacer(),

          SizedBox(
            key: _searchBarKey,
            width: 410, height: 40,
            child: Consumer<SearchProvider>(builder: (context,search,_)=> CustomTextFieldWidget(
              onTap: _showSearchDialog,
              focusNode: _appbarSearchFocusNode,
              radius: 50,
              hintText: _getCurrentHintText(context),
              isShowBorder: true,
              fillColor: Theme.of(context).cardColor,
              isShowPrefixIcon: search.searchLength == 0,
              prefixIconUrl: Images.search,
              prefixIconColor: Theme.of(context).primaryColor,
              suffixIconColor: Theme.of(context).hintColor,
              inputDecoration: InputDecoration(
                hintText: _getCurrentHintText(context),
                hintStyle: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeLarge + 3,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  fontStyle: FontStyle.italic,
                  overflow: TextOverflow.ellipsis
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
                fillColor: Theme.of(context).cardColor,
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
                // Indicador de progreso
                suffixIcon: search.searchLength == 0 ? Stack(
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
                ) : null,
              ),
              onChanged: (str){
                search.getSearchText(str);
              },

              controller: search.searchController,
              inputAction: TextInputAction.search,
              isIcon: true,
              isShowSuffixIcon: search.searchLength > 0,
              suffixIconUrl: Images.cancelSvg,
              onSuffixTap: (){
                search.searchController.clear();
                search.getSearchText('');

              },

              onSubmit: (text) {
                if (search.searchController.text.isNotEmpty) {
                  RouterHelper.getSearchResultRoute(search.searchController.text);
                  search.searchDone();
                }
              },
            )),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
            child: BranchButtonWidget(isPopup: true),
          ),

          InkWell(
            onTap: ()=> RouterHelper.getDashboardRoute('favourite'),
            child: OnHoverWidget(builder: (isHover) {
              return Consumer<WishListProvider>(
                builder: (context, wishlistProvider, _) {
                  return  CountIconView(count: '${wishlistProvider.wishList?.length ?? 0}', icon: Icons.favorite);
                }
              );
            }),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: CartButtonWidget(
              onTap: () {
                Future.microtask(() => RouterHelper.getDashboardRoute('cart'));
              },
              size: 50,
              borderWidth: 0,
              icon: CustomAssetImageWidget(
                Images.navOrderSvg,
                width: Dimensions.paddingSizeLarge + 2,
                color: Theme.of(context).primaryColor,
              ),
              backgroundColor: Colors.transparent,
              semanticLabel: getTranslated('cart', context),
            ),
          ),

          OnHoverWidget(builder: (isHover)=> Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
            child: InkWell(
              onTap:()=> RouterHelper.getProfileRoute(),
              child: profileProvider.userInfoModel?.image != null ?
              ClipOval(
                child: CustomImageWidget(
                  image: "${splashProvider.baseUrls!.customerImageUrl}/${profileProvider.userInfoModel?.image}",
                  fit: BoxFit.cover,
                  height: Dimensions.paddingSizeExtraLarge,
                  width: Dimensions.paddingSizeExtraLarge,
                ),
              ) : CustomAssetImageWidget(
                fit: BoxFit.cover,
                Images.navUserSvg, width: Dimensions.paddingSizeLarge,
                color: isHover ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5),
              ),
            ),
          )),

          OnHoverWidget(builder: (isHover)=> InkWell(
            onTap: ()=> RouterHelper.getDashboardRoute('menu'),
            child: Icon(
              Icons.menu, size: Dimensions.paddingSizeExtraLarge,
              color: Theme.of(context).primaryColor,
            ),
          )),
        ])))),

      ]),
    );
  }

  @override
  // ignore: override_on_non_overriding_member
  Size get preferredSize => const Size(double.maxFinite, 50);
}

class CountIconView extends StatelessWidget {
  final String? count;
  final IconData? icon;
  final String? image;
  final Color? color;
  const CountIconView({
    super.key, this.count, this.icon, this.image, this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (context == null) return const SizedBox();
    
    return OnHoverWidget(builder: (isHover) {
      try {
        // Get safe values
        final String safeCount = count ?? '0';
        final Color primaryColor = Theme.of(context).primaryColor;
        final Color? textColor = Theme.of(context).textTheme.bodyMedium?.color;
        
        // Visual content of the button
        final Widget iconContent = Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
          child: Stack(clipBehavior: Clip.none, children: [
            // Main icon
            if (image != null) 
              CustomAssetImageWidget(
                image!, 
                width: Dimensions.paddingSizeLarge + 2,
                color: isHover ? primaryColor : textColor?.withOpacity(0.5),
              ) 
            else 
              Icon(
                icon ?? Icons.favorite, // Provide a default value
                size: Dimensions.paddingSizeLarge + 2,
                color: color ?? (isHover ? primaryColor : textColor?.withOpacity(0.5)),
              ),

            // Quantity badge
            if (safeCount != '0' && safeCount != '') Positioned(
              top: -10, 
              right: -3, 
              child: Container(
                padding: const EdgeInsets.all(4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: primaryColor,
                  border: Border.all(color: Colors.white, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    safeCount, 
                    style: rubikSemiBold.copyWith(
                      color: Colors.white, 
                      fontSize: 8
                    )
                  )
                ),
              )
            )
          ]),
        );
        
        // Wrap with Material for better touch effect
        return Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: primaryColor.withOpacity(0.2),
            highlightColor: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              try {
                // If we're inside an InkWell that navigates elsewhere, ensure it's safe
                Future.microtask(() {
                  if (context.mounted) {
                    // The action will be defined in the parent, this InkWell is just visual
                  }
                });
              } catch (e) {
                debugPrint('Error in CountIconView onTap: $e');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: iconContent,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error in CountIconView: $e');
        // Safe fallback
        return SizedBox(
          height: Dimensions.paddingSizeLarge * 2,
          width: Dimensions.paddingSizeLarge * 2,
          child: Icon(
            icon ?? Icons.favorite,
            color: Theme.of(context).primaryColor,
          ),
        );
      }
    });
  }
}

