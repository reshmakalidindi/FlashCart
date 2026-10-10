import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';

  List<Product> get products => _selectedCategory == 'All'
      ? _products
      : _products.where((p) => p.category == _selectedCategory).toList();

  List<String> get categories {
    final set = {'All'};
    for (var p in _products) {
      set.add(p.category);
    }
    return set.toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  ProductProvider() {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productService.getAllProducts();
    } catch (e) {
      _errorMessage = 'Failed to load product catalog: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Product?> scanProductBarcode(String barcode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = await _productService.getProductByBarcode(barcode);
      _isLoading = false;
      notifyListeners();
      return product;
    } catch (e) {
      _errorMessage = 'Error scanning barcode: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> seedSampleData() async {
    _isLoading = true;
    notifyListeners();

    final count = await _productService.seedSampleProducts();
    await fetchProducts();

    _isLoading = false;
    notifyListeners();
    return count > 0;
  }

  void selectCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }
}
