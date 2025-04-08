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



  Future<void> getCategoryList(bool reload, {DataSourceEnum source = DataSourceEnum.local}) async {
    if(_categoryList == null || reload) {
      _isLoading = true;

       fetchAndSyncData(
        fetchFromLocal: ()=> categoryRepo!.getCategoryList<CacheResponseData>(source: DataSourceEnum.local),
        fetchFromClient: ()=> categoryRepo!.getCategoryList(source: DataSourceEnum.client),
        onResponse: (data, _) {
          _categoryList = [];
          data.forEach((category) => _categoryList!.add(CategoryModel.fromJson(category)));

          if(_categoryList!.isNotEmpty){
            _selectedSubCategoryId = '${_categoryList?.first.id}';
          }
          _isLoading = false;

          notifyListeners();
        },
      );
    }
  }





  void getSubCategoryList(String categoryID, {String type = 'all', String? name}) async {
    _subCategoryList = null;
    _isLoading = true;
    ApiResponseModel apiResponse = await categoryRepo!.getSubCategoryList(categoryID);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _subCategoryList= [];
      apiResponse.response!.data.forEach((category) => _subCategoryList!.add(CategoryModel.fromJson(category)));
      getCategoryProductList(categoryID, 1, type: type);
    } else {
      ApiCheckerHelper.checkApi(apiResponse);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future getCategoryProductList(String? categoryID, int offset, {String type = 'all', String? name}) async {

    if(_selectedSubCategoryId != categoryID || offset == 1) {
      _categoryProductModel = null;
    }
    _selectedSubCategoryId = categoryID;
    notifyListeners();

    if(_categoryProductModel == null || offset != 1) {
      ApiResponseModel apiResponse = await categoryRepo!.getCategoryProductList(categoryID: categoryID, offset: offset, type: type, name: name);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        if(offset == 1) {
          _categoryProductModel = ProductModel.fromJson(apiResponse.response?.data);
        }else {
          _categoryProductModel?.totalSize = ProductModel.fromJson(apiResponse.response?.data).totalSize;
          _categoryProductModel?.offset = ProductModel.fromJson(apiResponse.response?.data).offset;
          _categoryProductModel?.products?.addAll(ProductModel.fromJson(apiResponse.response?.data).products ?? []);
        }
      }else {
        ApiCheckerHelper.checkApi(apiResponse);
      }
    }

    notifyListeners();
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
