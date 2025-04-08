import 'package:flutter/material.dart';
import 'package:flutter_restaurant/localization/app_localization.dart';

String? getTranslated(String? key, BuildContext context) {
  // Si la clave es null, devolvemos un valor predeterminado
  if (key == null) return '...';
  
  String? text = key;
  try {
    text = AppLocalization.of(context)!.translate(key);
    
    // Si la traducción es igual a la clave (no se encontró traducción)
    // Y es una clave relacionada con la búsqueda
    if (text == key && 
        (key.contains('are_you_hungry') || 
         key.contains('search_hint'))) {
      // Devuelve un texto amigable en el idioma que se está viendo actualmente
      return '¿Buscas algo delicioso?';
    }
  } catch (error) {
    debugPrint('error --- $error');
    
    // Si hay un error en la traducción de una clave de búsqueda
    if (key.contains('are_you_hungry') || key.contains('search_hint')) {
      return '¿Buscas algo delicioso?';
    }
  }
  return text;
}