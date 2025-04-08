import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/web_app_bar_widget.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/main.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:go_router/go_router.dart';

class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool isBackButtonExist;
  final Function? onBackPressed;
  final BuildContext? context;
  final Widget? actionView;
  final bool centerTitle;
  final bool isTransparent;
  final double elevation;
  final Widget? leading;
  final Color? titleColor;

  const CustomAppBarWidget({
    super.key,
    required this.title,
    this.isBackButtonExist = true,
    this.onBackPressed,
    this.context,
    this.actionView,
    this.centerTitle = true,
    this.isTransparent = false,
    this.elevation = 0,
    this.leading,
    this.titleColor
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isDesktop(context) ? const WebAppBarWidget() : AppBar(
      title: Text(
        title!,
        style: rubikSemiBold.copyWith(
          fontSize: Dimensions.fontSizeLarge,
          color: titleColor ?? (isTransparent ? Theme.of(context).cardColor : Theme.of(context).textTheme.bodyLarge!.color),
        ),
      ),
      centerTitle: centerTitle,
      leading: isBackButtonExist ? IconButton(
        icon: leading ?? const Icon(Icons.arrow_back_ios),
        color: titleColor ?? (isTransparent ? Theme.of(context).cardColor : Theme.of(context).primaryColor),
        onPressed: () => onBackPressed != null ? onBackPressed!() : context.pop(),
      ) : const SizedBox(),
      actions: actionView != null ? [Padding(
        padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
        child: actionView!,
      )] : [],
      backgroundColor: isTransparent ? Colors.transparent : Theme.of(context).cardColor,
      elevation: elevation,
    );
  }

  @override
  Size get preferredSize => Size(double.maxFinite, ResponsiveHelper.isDesktop(Get.context) ? 100 : 50);
}
