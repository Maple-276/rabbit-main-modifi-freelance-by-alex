import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/providers/theme_provider.dart';
import 'package:flutter_restaurant/common/widgets/custom_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/on_hover_widget.dart';
import 'package:flutter_restaurant/features/category/providers/category_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/color_resources.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';

class CategoryPageWidget extends StatefulWidget {
  final CategoryProvider categoryProvider;
  final PageController pageController;
  const CategoryPageWidget({super.key, required this.categoryProvider, required this.pageController});

  @override
  State<CategoryPageWidget> createState() => _CategoryPageWidgetState();
}

class _CategoryPageWidgetState extends State<CategoryPageWidget> {
  int initialLength = 8;
  int currentIndex = 0;


  @override
  Widget build(BuildContext context) {

    final isDesktop = ResponsiveHelper.isDesktop(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final length = isDesktop ? 10 : 8;

    int totalPage = (widget.categoryProvider.categoryList!.length / length).ceil();
    List<int> totalPageIndexList = [];
    for(int i= 0; i < totalPage; i++) {
      totalPageIndexList.add(i);
    }

    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    return Column(mainAxisSize: MainAxisSize.min, children: [

        const SizedBox(height: Dimensions.paddingSizeDefault),
        Center(child: Text(getTranslated('dish_discoveries', context)!, textAlign: TextAlign.center, style: rubikBold.copyWith(
          fontSize: isDesktop ? Dimensions.fontSizeExtraLarge : Dimensions.fontSizeDefault,
          color: themeProvider.darkTheme ? Theme.of(context).primaryColor : ColorResources.homePageSectionTitleColor
        ))),
        SizedBox(height: isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall),

      Expanded(child: PageView.builder(
        controller: widget.pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: totalPage,
        onPageChanged: (index) {
          widget.categoryProvider.updateProductCurrentIndex(index, totalPage);
        },
        itemBuilder: (context, index) {
          initialLength = length;
          currentIndex = length * index;

          if(index + 1 == totalPage) {
            initialLength = widget.categoryProvider.categoryList!.length - (index * length);
          }

          return GridView.builder(
            itemCount: initialLength,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 5 : ResponsiveHelper.isTab(context) ? 8 : 4,
              mainAxisExtent: 110,
            ),
            padding: EdgeInsets.zero,
            itemBuilder: (context, i) {
              int currentIndex0 = i  + currentIndex;
              String? name = widget.categoryProvider.categoryList![currentIndex0].name;

              return Column(mainAxisSize: MainAxisSize.min, children: [
                InkWell(
                  onTap: () => RouterHelper.getCategoryRoute(widget.categoryProvider.categoryList![currentIndex0]),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: isDesktop ? OnHoverWidget(builder: (isHoverActive) {
                    return Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        color: Colors.white,
                        border: isHoverActive ? Border.all(color: Theme.of(context).primaryColor) : null,
                        boxShadow: [BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.2),
                          spreadRadius: Dimensions.radiusSmall, blurRadius: Dimensions.radiusLarge,
                        )],
                      ),
                      child: CustomImageWidget(
                        height: 45, width: 45,
                        image: splashProvider.baseUrls != null
                            ? '${splashProvider.baseUrls!.categoryImageUrl}/${widget.categoryProvider.categoryList![currentIndex0].image}' : '',
                      ),
                    );
                  }) : Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      color: Theme.of(context).cardColor.withOpacity(0.5),
                      boxShadow: [BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.2),
                        spreadRadius: Dimensions.radiusSmall, blurRadius: Dimensions.radiusLarge,
                      )],
                    ),
                    child: CustomImageWidget(
                      height: 45, width: 45,
                      image: splashProvider.baseUrls != null
                          ? '${splashProvider.baseUrls!.categoryImageUrl}/${widget.categoryProvider.categoryList![currentIndex0].image}' : '',
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Text(name!, maxLines: 1, textAlign: TextAlign.center,  style: rubikSemiBold.copyWith(
                  fontSize: isDesktop ? Dimensions.fontSizeDefault : Dimensions.fontSizeSmall,
                )),
              ]);
            },
          );
        },
      )),


      Row(mainAxisAlignment: MainAxisAlignment.center, children: totalPageIndexList.map((index) {
        return Container(
          width: currentIndex == index * length ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeExtraSmall,
          height: Dimensions.paddingSizeExtraSmall,
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              color: currentIndex == index * length
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor.withOpacity(0.3)
          ),
        );
      }).toList()),

    ]);
  }
}
