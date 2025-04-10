import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/enums/data_source_enum.dart';
import 'package:flutter_restaurant/common/models/api_response_model.dart';
import 'package:flutter_restaurant/common/models/product_model.dart';
import 'package:flutter_restaurant/common/providers/data_sync_provider.dart';
import 'package:flutter_restaurant/data/datasource/local/cache_response.dart';
import 'package:flutter_restaurant/features/category/domain/category_model.dart';
import 'package:flutter_restaurant/features/category/domain/reposotories/category_repo.dart';
import 'package:flutter_restaurant/helper/api_checker_helper.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_restaurant/features/category/data/local/local_category_data.dart';

class CategoryProvider extends DataSyncProvider {
  final CategoryRepo? categoryRepo;

  CategoryProvider({required this.categoryRepo});

  List<CategoryModel>? _categoryList;
  List<CategoryModel>? _subCategoryList;
  ProductModel? _categoryProductModel;
  bool _pageFirstIndex = true;
  bool _pageLastIndex = false;
  bool _isLoading = false;
  String? _selectedSubCategoryId;

  List<CategoryModel>? get categoryList => _categoryList;
  List<CategoryModel>? get subCategoryList => _subCategoryList;
  ProductModel? get categoryProductModel => _categoryProductModel;
  bool get pageFirstIndex => _pageFirstIndex;
  bool get pageLastIndex => _pageLastIndex;
  bool get isLoading => _isLoading;
  String? get selectedSubCategoryId => _selectedSubCategoryId;

  Future<void> getCategoryList(bool reload) async {
    print('[CategoryProvider] getCategoryList called with reload: $reload, _categoryList is null: ${_categoryList == null}');
    if(_categoryList == null || reload) {
      print('[CategoryProvider] Condition met, proceeding to fetchAndSyncData...');
      _isLoading = true;

      print('>>> [CategoryProvider] ABOUT TO CALL fetchAndSyncData <<<');
      fetchAndSyncData(
         fetchFromLocal: () => Future.value(ApiResponseModel<CacheResponseData>.withSuccess(CacheResponseData(id: -1, endPoint: '', header: '', response: '[]'))), // Dummy required
        fetchFromClient: () async => await categoryRepo!.getCategoryList<Response>(), 
        
        onResponse: (data, source) { 
          _categoryList = [];
          List<dynamic> categoryJsonList = [];

          print('[CategoryProvider] onResponse received data type: ${data.runtimeType} from source: $source');

          // Assume data is the List<dynamic> directly from the API response
          if (data is List) {
             categoryJsonList = List<dynamic>.from(data);
             print('[CategoryProvider] Received API list data with ${categoryJsonList.length} items');
          } else {
             print('[CategoryProvider] Received API data is not a List: ${data.runtimeType}');
             categoryJsonList = [];
          }

          // --- Add the local Grocery category (using imported data) --- 
          print('[CategoryProvider] Adding local Grocery category...');
          categoryJsonList.insert(0, groceryCategoryJson); // Use imported groceryCategoryJson
          // --- End of adding Grocery --- 

          print('[CategoryProvider] Processing combined list with ${categoryJsonList.length} categories...');

          // Process the combined list
          categoryJsonList.forEach((category) {
             if(category is Map<String, dynamic>) {
               print('[CategoryProvider] Parsing category: $category');
               try {
                 _categoryList!.add(CategoryModel.fromJson(category));
                 print('[CategoryProvider] Successfully parsed: ${category['name']}');
               } catch (e) {
                 print('[CategoryProvider] Error parsing category model: $category -> $e');
               }
             } else {
                print('[CategoryProvider] Skipping item, not a valid category map: $category');
             }
          });

          // Sort categories by position
          _categoryList?.sort((a, b) => (a.position ?? 999).compareTo(b.position ?? 999));
          print('[CategoryProvider] Final _categoryList count (after sorting): ${_categoryList?.length}');

          if(_categoryList!.isNotEmpty){
             _selectedSubCategoryId = '${_categoryList?.first.id}'; 
          }
          _isLoading = false;

          // Delay this notification
          WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
          });
        },
      );
    }
  }

  void getSubCategoryList(String categoryID, {String type = 'all', String? name}) async {
     print('[CategoryProvider] getSubCategoryList called for ID: $categoryID');
    // --- Check if it's the local Grocery category (use imported ID) --- 
    if (categoryID == groceryCategoryId) { // Use imported groceryCategoryId
      print('[CategoryProvider] Handling local Grocery subcategories.');
      _subCategoryList = [];
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
         notifyListeners(); 
      });

      try {
        // Use imported localGrocerySubcategoriesJson
        localGrocerySubcategoriesJson.forEach((subJson) { 
          _subCategoryList!.add(CategoryModel.fromJson(subJson));
        });
        print('[CategoryProvider] Loaded ${_subCategoryList?.length} local Grocery subcategories.');
         if(_subCategoryList!.isNotEmpty) {
           getCategoryProductList(_subCategoryList!.first.id.toString(), 1, type: type);
         } else {
            _categoryProductModel = null; 
            _isLoading = false; 
            WidgetsBinding.instance.addPostFrameCallback((_) {
               notifyListeners(); 
            });
         }
      } catch (e) {
         print('[CategoryProvider] Error parsing local subcategories: $e');
          _subCategoryList = []; 
          _categoryProductModel = null;
          _isLoading = false; 
           WidgetsBinding.instance.addPostFrameCallback((_) {
               notifyListeners(); 
           });
      }
      return; 
    }
    // --- End of local Grocery handling ---

    // Proceed with API call for non-Grocery categories
    _subCategoryList = null;
    _isLoading = true;
    // Delay this notification until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
       notifyListeners(); 
    }); 
    
    print('[CategoryProvider] Fetching subcategories from API for ID: $categoryID');
    try {
      ApiResponseModel apiResponse = await categoryRepo!.getSubCategoryList(categoryID);
      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        _subCategoryList= [];
        if(apiResponse.response!.data is List) {
           List<dynamic> responseData = apiResponse.response!.data;
           responseData.forEach((category) => _subCategoryList!.add(CategoryModel.fromJson(category)));
           print('[CategoryProvider] Received ${_subCategoryList?.length} subcategories from API.');
           if(_subCategoryList!.isNotEmpty) {
             getCategoryProductList(categoryID, 1, type: type); 
           } else {
             _categoryProductModel = null;
             _isLoading = false; 
             WidgetsBinding.instance.addPostFrameCallback((_) {
                notifyListeners(); 
             });
           }
        } else {
          print('[CategoryProvider] API subcategory response is not a List: ${apiResponse.response!.data}');
           _subCategoryList = [];
           _categoryProductModel = null;
           _isLoading = false;
           WidgetsBinding.instance.addPostFrameCallback((_) {
               notifyListeners(); 
           });
        }
        
      } else {
        print('[CategoryProvider] API error for subcategories: ${apiResponse.error}');
        ApiCheckerHelper.checkApi(apiResponse);
        _subCategoryList = []; 
        _categoryProductModel = null;
         _isLoading = false; 
         WidgetsBinding.instance.addPostFrameCallback((_) {
               notifyListeners(); 
           });
      }
    } catch(e) {
        print('[CategoryProvider] Exception fetching subcategories from API: $e');
         _subCategoryList = []; 
         _categoryProductModel = null;
         _isLoading = false; 
          WidgetsBinding.instance.addPostFrameCallback((_) {
               notifyListeners(); 
           });
    }
  }

  Future getCategoryProductList(String? categoryID, int offset, {String type = 'all', String? name}) async {
    if(_selectedSubCategoryId != categoryID || offset == 1) {
      _categoryProductModel = null;
    }
    // Don't notify immediately after changing _selectedSubCategoryId if it happens during build
    // The subsequent loading state change will trigger a notification later.
    final previousSelectedId = _selectedSubCategoryId;
    _selectedSubCategoryId = categoryID;
    if(previousSelectedId != categoryID) {
      // If the ID actually changed, notify after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } // Otherwise, let the loading state notification handle it

    if(_categoryProductModel == null || offset == 1) {
       print('[CategoryProvider][getCategoryProductList] Loading products for ID: $categoryID, Offset: $offset');
       _isLoading = true;
       // Notify about loading state change (delayed)
       WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
       });

      try {
        ApiResponseModel apiResponse = await categoryRepo!.getCategoryProductList(categoryID: categoryID, offset: offset, type: type, name: name);
        if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
          if(offset == 1) {
             print('[CategoryProvider][getCategoryProductList] Received first page products.');
             _categoryProductModel = ProductModel.fromJson(apiResponse.response?.data);
          } else {
             print('[CategoryProvider][getCategoryProductList] Received more products (page ${offset}).');
             _categoryProductModel?.totalSize = ProductModel.fromJson(apiResponse.response?.data).totalSize;
             _categoryProductModel?.offset = ProductModel.fromJson(apiResponse.response?.data).offset;
             _categoryProductModel?.products?.addAll(ProductModel.fromJson(apiResponse.response?.data).products ?? []);
          }
        } else {
          print('[CategoryProvider][getCategoryProductList] API Error: ${apiResponse.error}');
          ApiCheckerHelper.checkApi(apiResponse);
          if(offset == 1) _categoryProductModel = null; // Clear on error for first page
        }
       } catch (e) {
         print('[CategoryProvider][getCategoryProductList] Exception: $e');
         ApiCheckerHelper.checkApi(ApiResponseModel.withError(ApiErrorHandler.getMessage(e)));
          if(offset == 1) _categoryProductModel = null; // Clear on exception for first page
       } finally {
          print('[CategoryProvider][getCategoryProductList] Load finished. Setting isLoading = false.');
          _isLoading = false; 
          // Notify about final state (data or error) AFTER isLoading is false
           WidgetsBinding.instance.addPostFrameCallback((_) {
               notifyListeners();
          });
       }

    } else {
        print('[CategoryProvider][getCategoryProductList] Products already loaded, skipping fetch. Setting isLoading = false.');
        // If products already exist and offset is not 1, ensure loading is false
         _isLoading = false;
         WidgetsBinding.instance.addPostFrameCallback((_) {
             notifyListeners();
        });
    }
  }

  int _selectCategory = -1;
  final List<int> _selectedCategoryList = [];

  int get selectCategory => _selectCategory;
  List<int> get selectedCategoryList => _selectedCategoryList;

  void updateSelectCategory({required int id}) {
    _selectCategory = id;
    if (_selectedCategoryList.contains(id)) {
      _selectedCategoryList.remove(id);
    } else {
      _selectedCategoryList.add(id);
    }

    debugPrint(selectedCategoryList.toString());
    notifyListeners();
  }

  void clearSelectedCategory()=> _selectedCategoryList.clear();

  updateProductCurrentIndex(int index, int totalLength) {
    if(index > 0) {
      _pageFirstIndex = false;
      notifyListeners();
    }else{
      _pageFirstIndex = true;
      notifyListeners();
    }
    if(index + 1  == totalLength) {
      _pageLastIndex = true;
      notifyListeners();
    }else {
      _pageLastIndex = false;
      notifyListeners();
    }
  }
}
