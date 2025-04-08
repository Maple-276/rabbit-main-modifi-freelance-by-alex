import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/models/cart_model.dart';
import 'package:flutter_restaurant/common/models/product_model.dart';
import 'package:flutter_restaurant/common/providers/product_provider.dart';
import 'package:flutter_restaurant/features/cart/domain/reposotories/cart_repo.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/main.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:provider/provider.dart';

class CartProvider extends ChangeNotifier {
  final CartRepo? cartRepo;
  CartProvider({required this.cartRepo});

  List<CartModel?> _cartList = [];
  double _amount = 0.0;
  bool _isCartUpdate = false;

  List<CartModel?> get cartList => _cartList;
  double get amount => _amount;
  bool get isCartUpdate => _isCartUpdate;

  // Duración reducida para notificaciones del carrito
  final Duration _cartNotificationDuration = const Duration(seconds: 1);

  void getCartData(BuildContext context) {
    _cartList = [];
    _cartList.addAll(cartRepo!.getCartList(context));
    for (var cart in _cartList) {
      _amount = _amount + (cart!.discountedPrice! * cart.quantity!);
    }
  }

  void addToCart(CartModel cartModel, int? index) {
    if(index != null && index != -1) {
      _cartList.replaceRange(index, index+1, [cartModel]);
    }else {
      _cartList.add(cartModel);
    }
    cartRepo!.addToCartList(_cartList);
    setCartUpdate(false);
    
    // Mensaje simplificado
    String productName = cartModel.product!.name ?? 'Producto';
    
    showCustomSnackBarHelper(
      index == -1 
        ? '✓ $productName añadido al carrito' 
        : '✓ $productName actualizado', 
      isToast: true, 
      isError: false,
      type: SnackBarType.cart,
      duration: _cartNotificationDuration,
      showProgressBar: true
    );

    notifyListeners();
  }

  void setQuantity(
      {required bool isIncrement,
      CartModel? cart,
      int? productIndex,
      required bool fromProductView}) {
    int? index = fromProductView ? productIndex :  _cartList.indexOf(cart);
    String productName = _cartList[index!]!.product!.name ?? 'Producto';
    
    // Incrementar o decrementar cantidad
    if (isIncrement) {
      _cartList[index]!.quantity = (_cartList[index]!.quantity ?? 0) + 1;
      _amount = _amount + _cartList[index]!.discountedPrice!;
    } else {
      _cartList[index]!.quantity = (_cartList[index]!.quantity ?? 0) - 1;
      _amount = _amount - _cartList[index]!.discountedPrice!;
    }
    
    int quantity = _cartList[index]!.quantity ?? 0;
    
    // Mensaje simplificado
    showCustomSnackBarHelper(
      isIncrement
        ? '✓ Cantidad: $quantity'
        : '✓ Cantidad: $quantity', 
      isError: false,
      type: SnackBarType.cart,
      duration: _cartNotificationDuration,
      showProgressBar: true
    );
    
    cartRepo!.addToCartList(_cartList);
    notifyListeners();
  }

  void removeFromCart(int index) {
    String productName = _cartList[index]!.product!.name ?? 'Producto';
    
    _amount = _amount - (_cartList[index]!.discountedPrice! * _cartList[index]!.quantity!);
    _cartList.removeAt(index);
    cartRepo!.addToCartList(_cartList);
    
    // Mensaje simplificado
    showCustomSnackBarHelper(
      '✗ $productName eliminado', 
      isError: false, 
      type: SnackBarType.cart,
      duration: _cartNotificationDuration,
      showProgressBar: true
    );
    
    notifyListeners();
  }

  void removeAddOn(int index, int addOnIndex) {
    // No podemos acceder al nombre del AddOn directamente
    _cartList[index]!.addOnIds!.removeAt(addOnIndex);
    cartRepo!.addToCartList(_cartList);
    
    // Mensaje simplificado
    showCustomSnackBarHelper(
      '✗ Complemento eliminado', 
      isError: false, 
      type: SnackBarType.cart,
      duration: _cartNotificationDuration,
      showProgressBar: true
    );
    
    notifyListeners();
  }

  void clearCartList() {
    _cartList = [];
    _amount = 0;
    cartRepo!.addToCartList(_cartList);
    
    // Mensaje simplificado
    showCustomSnackBarHelper(
      '✓ Carrito vaciado', 
      isError: false, 
      type: SnackBarType.cart,
      duration: _cartNotificationDuration,
      showProgressBar: true
    );
    
    notifyListeners();
  }

  int isExistInCart(int? productID, int? cartIndex) {
    for(int index=0; index<_cartList.length; index++) {
      if(_cartList[index]!.product!.id == productID) {
        if((index == cartIndex)) {
          return -1;
        }else {
          return index;
        }
      }
    }
    return -1;
  }


  int getCartIndex (Product product) {
    for(int index = 0; index < _cartList.length; index ++) {
      if(_cartList[index]!.product!.id == product.id ) {

        return index;
      }
    }
    return -1;
  }
  int getCartProductQuantityCount (Product product) {
    int quantity = 0;
    for(int index = 0; index < _cartList.length; index ++) {
      if(_cartList[index]!.product!.id == product.id ) {
        quantity = quantity + (_cartList[index]!.quantity ?? 0);
      }
    }
    return quantity;
  }


  setCartUpdate(bool isUpdate) {
    _isCartUpdate = isUpdate;
    if(_isCartUpdate) {
      notifyListeners();
    }

  }

  void onUpdateCartQuantity({required int index, required Product product, required bool isRemove}) {
    // Parameter validation
    if (product.id == null) {
      debugPrint('Error: product without ID when updating quantity');
      return;
    }
    
    if (index < 0 || (_cartList.isNotEmpty && index >= _cartList.length)) {
      debugPrint('Error: index $index out of range (0-${_cartList.length - 1})');
      return;
    }
    
    // Verify that the context is available
    final context = Get.context;
    if (context == null) {
      debugPrint('Error: onUpdateCartQuantity could not get a valid context');
      return;
    }

    try {
      // Check if the product is already in the cart more than once
      final bool isMultipleInCart = _isProductInCart(product);
      
      if(!isMultipleInCart) {
        // Get the product provider safely
        ProductProvider? productProvider;
        try {
          productProvider = Provider.of<ProductProvider>(context, listen: false);
        } catch (e) {
          debugPrint('Error getting ProductProvider: $e');
          return;
        }
        
        // Calculate new quantity
        int quantity = getCartProductQuantityCount(product) + (isRemove ? -1 : 1);
        
        // Check availability
        final bool isStockAvailable = !isRemove ? 
          productProvider.checkStock(product, quantity: quantity) : true;

        if(isStockAvailable || isRemove) {
          // If we're removing and it reaches zero, remove from cart
          if(isRemove && quantity == 0) {
            // Verify that the index is valid before removing
            if (index >= 0 && index < _cartList.length) {
              removeFromCart(index);
            } else {
              debugPrint('Error: Cannot remove, index $index out of range');
            }
          } else {
            // Verify that the index is valid before updating
            if (index >= 0 && index < _cartList.length && _cartList[index] != null) {
              _cartList[index]!.quantity = quantity;
              addToCart(_cartList[index]!, index);
            } else {
              debugPrint('Error: Cannot update, index $index out of range or null element');
            }
          }
        } else {
          // Show out of stock message
          Future.microtask(() {
            try {
              final notificationContext = Get.context;
              if (notificationContext != null) {
                showCustomSnackBarHelper(
                  '✗ ${product.name} not available in stock', 
                  type: SnackBarType.error,
                  duration: _cartNotificationDuration,
                  showProgressBar: true
                );
              }
            } catch (e) {
              debugPrint('Error showing stock notification: $e');
            }
          });
        }
      } else {
        // Show message to update from cart list
        Future.microtask(() {
          try {
            final notificationContext = Get.context;
            if (notificationContext != null) {
              showCustomSnackBarHelper(
                '⚠️ Update quantity from the cart list',
                duration: _cartNotificationDuration,
                showProgressBar: true
              );
            }
          } catch (e) {
            debugPrint('Error showing update notification: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating cart quantity: $e');
    }
  }

  bool _isProductInCart(Product product){
    int count = 0;
    for(int index = 0; index < _cartList.length; index ++) {
      if(_cartList[index]!.product!.id == product.id ) {
        count++;
        if(count > 1) {
          return true;
        }
      }
    }
    return false;

  }

}
