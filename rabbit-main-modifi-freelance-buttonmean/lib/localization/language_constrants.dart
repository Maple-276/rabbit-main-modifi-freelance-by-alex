import 'package:flutter/material.dart';
import 'package:flutter_restaurant/localization/app_localization.dart';

String? getTranslated(String? key, BuildContext context) {
  try {
    final loc = AppLocalization.of(context)!;

    // If the key is null, return a default value
    if (key == null || key.isEmpty) {
      return '[Key Null]';
    }

    String? translation = loc.translate(key);

    // If translation equals key (translation not found)
    // AND it's a search-related key
    if (translation == key && key.contains('search_hint')) {
      // Return a friendly text in the current language
      // (This fallback is specific to search hints)
      return '¿Buscas algo delicioso?'; // Consider localizing this fallback too if needed
    }

    // If there's an error translating a search key (should ideally not happen with above checks)
    if (translation == null && key.contains('search_hint')) {
      return '¿Buscas algo delicioso?';
    }

    // Return the translation or the key itself if null
    return translation ?? key;
  } catch (e) {
    // Log error if needed
    return key ?? '[Error]';
  }
}