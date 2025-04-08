import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/product_model.dart';
import 'package:flutter_restaurant/features/cart/providers/cart_provider.dart';
import 'package:flutter_restaurant/helper/product_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';

/// A cart quantity control button optimized for accessibility and user experience.
/// 
/// This widget provides two states:
/// 1. Add button - When the product is not in cart (quantity = 0)
/// 2. Quantity controller - When the product is in cart (quantity > 0)
///
/// Features:
/// - Maintains 40x40 touch targets for accessibility while keeping visual size compact
/// - Provides visual feedback through splash and highlight effects
/// - Includes semantic labels for screen readers
/// - Automatically handles state management through CartProvider
/// - Uses Future.microtask for smooth UI updates
/// - Supports both light and dark themes
///
/// Usage example:
/// ```dart
/// CartProductButtonWidget(
///   product: myProduct,
/// )
/// ```
///
/// The widget will automatically handle all cart operations through the [CartProvider].
class CartProductButtonWidget extends StatelessWidget {
  /// The product this button controls in the cart.
  /// 
  /// This product is used to:
  /// - Check if it's already in the cart
  /// - Get its current quantity
  /// - Handle add/remove operations
  final Product product;

  // Button dimensions
  static const double _buttonVisualSize = 26.0;
  static const double _buttonTouchTarget = 40.0;
  static const double _containerHeight = 30.0;
  static const double _iconSize = 14.0;
  static const double _fontSize = 12.0;
  static const double _padding = 2.0;

  /// Creates a cart product button.
  /// 
  /// Requires a [product] to be provided which will be used for all cart operations.
  const CartProductButtonWidget({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(product != null, 'Product cannot be null');
    
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        // Validate cart provider is properly initialized
        if (cartProvider == null) {
          debugPrint('Warning: CartProvider is null in CartProductButtonWidget');
          return const SizedBox.shrink(); // Fallback widget
        }

        try {
          int quantity = cartProvider.getCartProductQuantityCount(product);
          int cartIndex = cartProvider.getCartIndex(product);

          return Material(
            color: Colors.transparent,
            child: quantity == 0 
              ? _buildAddButton(context, cartIndex)
              : _buildQuantityController(context, cartProvider, cartIndex, quantity));
        } catch (e) {
          debugPrint('Error building CartProductButtonWidget: $e');
          return const SizedBox.shrink(); // Fallback widget
        }
      });
  }

  /// Builds the "Add" button when product is not in cart
  Widget _buildAddButton(BuildContext context, int cartIndex) {
    return Material(
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      color: Colors.white,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        onTap: () => Future.microtask(() => ProductHelper.addToCart(cartIndex: cartIndex, product: product)),
        child: Semantics(
          button: true,
          enabled: true,
          label: '${getTranslated('add', context)} ${product.name}',
          child: Container(
            constraints: const BoxConstraints(
              minWidth: _buttonTouchTarget,
              minHeight: _buttonTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                Icons.add_circle,
                color: Theme.of(context).primaryColor,
                size: _iconSize,
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text(
                getTranslated('add', context) ?? 'Add',
                style: rubikBold.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontSize: _fontSize,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Builds the quantity controller when product is in cart
  Widget _buildQuantityController(
    BuildContext context,
    CartProvider cartProvider,
    int cartIndex,
    int quantity,
  ) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Material(
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      color: primaryColor,
      clipBehavior: Clip.hardEdge,
      child: Container(
        height: _containerHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: _padding,
          vertical: _padding,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // Decrement button
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Future.microtask(() => cartProvider.onUpdateCartQuantity(
                index: cartIndex,
                product: product,
                isRemove: true,
              )),
              child: Semantics(
                button: true,
                enabled: true,
                label: '${getTranslated('remove', context)} ${product.name}',
                child: Container(
                  width: _buttonVisualSize,
                  height: _buttonVisualSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove,
                    size: _iconSize,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),

          // Counter
          Container(
            alignment: Alignment.center,
            width: _buttonVisualSize,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: rubikMedium.copyWith(
                color: Colors.white,
                fontSize: _fontSize,
              ),
            ),
          ),

          // Increment button
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Future.microtask(() => cartProvider.onUpdateCartQuantity(
                index: cartIndex,
                product: product,
                isRemove: false,
              )),
              child: Semantics(
                button: true,
                enabled: true,
                label: '${getTranslated('add', context)} ${product.name}',
                child: Container(
                  width: _buttonVisualSize,
                  height: _buttonVisualSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: _iconSize,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
} 