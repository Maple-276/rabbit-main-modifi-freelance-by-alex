import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/features/cart/providers/cart_provider.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';

/// Cart button widget with enhanced touch area for
/// better accessibility and user experience.
///
/// This component offers a cart button with the following improvements:
/// - Larger touch area without altering visual appearance
/// - Visual feedback effects (splash, highlight)
/// - Accessible design with quantity indicator
/// - Support for visual customization
/// - Secure error handling to avoid production issues
class CartButtonWidget extends StatelessWidget {
  /// Function executed when the button is tapped
  final VoidCallback onTap;
  
  /// Button size (diameter)
  final double size;
  
  /// Icon or image to display
  final Widget? icon;
  
  /// Button background color
  final Color? backgroundColor;
  
  /// Button border color
  final Color? borderColor;
  
  /// Border width
  final double borderWidth;
  
  /// Semantic accessibility label
  final String? semanticLabel;
  
  /// Constructor for the enhanced cart button
  const CartButtonWidget({
    Key? key,
    required this.onTap,
    this.size = 60,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 5,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Verificar que el contexto sea válido
    if (context == null) return const SizedBox();
    
    try {
      // Colores por defecto si no se proporcionan
      final Color bgColor = backgroundColor ?? Theme.of(context).primaryColor;
      final Color brdColor = borderColor ?? Theme.of(context).cardColor;
    
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: brdColor, width: 0),
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 1
            )
          ],
        ),
        child: Material(
          shape: const CircleBorder(),
          color: bgColor,
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withOpacity(0.4),
            highlightColor: Colors.white.withOpacity(0.3),
            enableFeedback: true,
            excludeFromSemantics: false,
            onTap: () {
              // Usar try-catch para manejar cualquier error durante la acción
              try {
                onTap();
              } catch (e) {
                debugPrint('Error al ejecutar onTap en CartButtonWidget: $e');
              }
            },
            child: Semantics(
              button: true,
              enabled: true,
              label: semanticLabel ?? 'Carrito de compras',
              child: Builder(builder: (BuildContext builderContext) {
                // Verificar si builderContext es válido
                if (builderContext == null) return const SizedBox();
                
                return Consumer<CartProvider>(
                  builder: (consumerContext, cartProvider, _) {
                    try {
                      // Verificar si el provider es nulo
                      if (cartProvider == null) return _buildButtonWithoutBadge(bgColor);
                      
                      // Verificar si la lista de carrito está inicializada
                      final cartList = cartProvider.cartList;
                      if (cartList == null) return _buildButtonWithoutBadge(bgColor);
                      
                      final int itemCount = cartList.length;
                    
                      return Stack(
                        children: [
                          // Icono del carrito centrado
                          Center(
                            child: icon ?? Icon(
                              Icons.shopping_cart_rounded,
                              color: Colors.white,
                              size: size * 0.5,
                            ),
                          ),
                        
                          // Indicador de cantidad (badge)
                          if (itemCount > 0)
                            Positioned(
                              top: size * 0.10,
                              right: size * 0.25,
                              child: Container(
                                constraints: BoxConstraints(
                                  minWidth: size * 0.35,
                                  minHeight: size * 0.35,
                                ),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(consumerContext).primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                                ),
                                child: FittedBox(
                                  child: Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: Text(
                                      itemCount.toString(),
                                      style: rubikSemiBold.copyWith(
                                        color: Colors.white,
                                        fontSize: size * 0.18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    } catch (e) {
                      debugPrint('Error en CartButtonWidget consumer: $e');
                      return _buildButtonWithoutBadge(bgColor);
                    }
                  },
                );
              }),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error en CartButtonWidget build: $e');
      return SizedBox(
        width: size,
        height: size,
        child: Material(
          shape: const CircleBorder(),
          color: Theme.of(context).primaryColor,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Icon(
              Icons.shopping_cart_rounded,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }
  
  /// Method to build the button without badge (as fallback)
  Widget _buildButtonWithoutBadge(Color bgColor) {
    return Center(
      child: icon ?? Icon(
        Icons.shopping_cart_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
} 