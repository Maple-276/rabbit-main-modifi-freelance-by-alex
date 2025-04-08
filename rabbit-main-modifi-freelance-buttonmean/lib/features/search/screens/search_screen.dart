import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:flutter_restaurant/common/widgets/web_app_bar_widget.dart';
import 'package:flutter_restaurant/features/search/providers/search_provider.dart';
import 'package:flutter_restaurant/features/search/widget/search_recommended_widget.dart';
import 'package:flutter_restaurant/features/search/widget/search_suggestion_widget.dart';
import 'package:flutter_restaurant/helper/debounce_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchBarFocus = FocusNode();
  final DebounceHelper debounce = DebounceHelper(milliseconds: 500);
  
  // Lista de sugerencias de búsqueda para el hint text rotativo
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
  String _currentHintText = '';

  @override
  void initState() {
    super.initState();

    final SearchProvider searchProvider = Provider.of<SearchProvider>(context, listen: false);

    searchProvider.initHistoryList();
    searchProvider.onClearSearchSuggestion();

    _searchController.addListener(_onChange);
    _searchBarFocus.addListener(_onFocusChange);
    
    // Iniciar el primer hint
    _updateHintText();
    
    // Iniciar el temporizador para rotar los hints cada 4 segundos
    _startHintRotation();
  }

  @override
  void dispose() {
    // Liberar recursos
    _hintRotationTimer?.cancel();
    _searchBarFocus.removeListener(_onFocusChange);
    super.dispose();
  }
  
  // Actualiza el texto del hint actual
  void _updateHintText() {
    if (mounted) {
      setState(() {
        _currentHintText = getTranslated(_searchHints[_currentHintIndex], context) ?? 'Buscar...';
      });
    }
  }
  
  // Inicia la rotación de hints
  void _startHintRotation() {
    // Cancelar el temporizador existente si lo hay
    _hintRotationTimer?.cancel();
    
    // Crear un nuevo temporizador que cambia el hint cada 4 segundos
    _hintRotationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          // Avanzar al siguiente hint
          _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
          _updateHintText();
        });
      }
    });
  }

  void _onFocusChange() {
    if(mounted){
      setState(() {
        // Detener la rotación cuando el campo obtiene el foco
        if (_searchBarFocus.hasFocus) {
          _hintRotationTimer?.cancel();
        } else {
          // Reiniciar la rotación cuando pierde el foco
          _startHintRotation();
        }
      });
    }
  }

  void _onChange() {
    if(_searchController.text.isEmpty) {
      Provider.of<SearchProvider>(context, listen: false).onClearSearchSuggestion();
    }
    if(mounted){
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context)
          ? const PreferredSize(preferredSize: Size.fromHeight(100), child: WebAppBarWidget())
          : AppBar(
        toolbarHeight: 70,
        leadingWidth: 0,
        backgroundColor: Theme.of(context).cardColor, // Matches your container's color
        elevation: 0, // Removes the AppBar shadow
        automaticallyImplyLeading: false, // Prevents default back button
        titleSpacing: 0,
        title: Consumer<SearchProvider>(
          builder: (context, searchProvider, _) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor,
                    blurRadius: Dimensions.radiusSmall, // Adjust for soft shadow
                    spreadRadius: 1, // Spread only affects bottom because of offset
                    offset: const Offset(0, 4), // Only vertical shadow
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.02,
                bottom: Dimensions.paddingSizeDefault,
                right: Dimensions.paddingSizeLarge,
                left: Dimensions.paddingSizeSmall,
              ),
              child: Row(children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                Expanded(
                  child: CustomTextFieldWidget(
                    hintText: _currentHintText,
                    isShowBorder: true,
                    controller: _searchController,
                    focusNode: _searchBarFocus,
                    inputAction: TextInputAction.search,
                    isIcon: true,
                    suffixIconUrl: Images.closeSvg,
                    isShowSuffixIcon: _searchController.text.isNotEmpty,
                    onSuffixTap: () => _searchController.clear(),
                    onSubmit: (text) {
                      if (_searchController.text.trim().isNotEmpty) {
                        searchProvider.saveSearchAddress(_searchController.text);
                        searchProvider.searchProduct(
                          name: _searchController.text,
                          offset: 1,
                          context: context,
                        );
                        RouterHelper.getSearchResultRoute(
                          _searchController.text.replaceAll(' ', '-'),
                        );
                      }
                    },
                    onChanged: (String text) => debounce.run(() {
                      if (text.isNotEmpty) {
                        searchProvider.onChangeAutoCompleteTag(searchText: text);
                      }
                    }),
                  ),
                ),
              ]),
            );
          },
        ),
      ),

      body: SafeArea(child: SizedBox(
        width: Dimensions.webScreenWidth,
        child: _searchController.text.isNotEmpty
            ? SearchSuggestionWidget(searchedText: _searchController.text)
            :  const SearchRecommendedWidget(),
      )),
    );
  }
}





