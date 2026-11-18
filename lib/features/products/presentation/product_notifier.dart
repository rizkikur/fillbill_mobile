import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/operator_detector.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/product_remote_data_source.dart';
import '../data/product_repository.dart';
import '../domain/product_entity.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return ProductRepository(ProductRemoteDataSourceImpl(client));
});

// Home Dashboard State & Notifier
class HomeState {
  final bool isLoading;
  final bool isBalanceHidden;
  final HomeDashboardData? data;
  final String? errorMessage;

  const HomeState({
    this.isLoading = false,
    this.isBalanceHidden = false,
    this.data,
    this.errorMessage,
  });

  HomeState copyWith({
    bool? isLoading,
    bool? isBalanceHidden,
    HomeDashboardData? data,
    String? errorMessage,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isBalanceHidden: isBalanceHidden ?? this.isBalanceHidden,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

final homeNotifierProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return HomeNotifier(repo);
});

class HomeNotifier extends StateNotifier<HomeState> {
  final ProductRepository _repo;

  HomeNotifier(this._repo) : super(const HomeState()) {
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    if (!AppConfig.isMockupEnabled) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final data = await _repo.getHomeDashboard();
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void toggleBalanceVisibility() {
    state = state.copyWith(isBalanceHidden: !state.isBalanceHidden);
  }
}

// Prepaid Transaction State & Notifier
class PrepaidState {
  final String phone;
  final CellularOperatorInfo operatorInfo;
  final String activeTab; // 'pulsa' or 'data'
  final List<ProductEntity> products;
  final ProductEntity? selectedProduct;
  final bool isLoading;

  const PrepaidState({
    this.phone = '',
    this.operatorInfo = const CellularOperatorInfo(
      type: CellularOperatorType.unknown,
      name: 'Nomor Ponsel',
      code: 'unknown',
      primaryColor: Colors.grey,
      icon: Icons.phone_android,
    ),
    this.activeTab = 'pulsa',
    this.products = const [],
    this.selectedProduct,
    this.isLoading = false,
  });

  PrepaidState copyWith({
    String? phone,
    CellularOperatorInfo? operatorInfo,
    String? activeTab,
    List<ProductEntity>? products,
    ProductEntity? selectedProduct,
    bool? isLoading,
  }) {
    return PrepaidState(
      phone: phone ?? this.phone,
      operatorInfo: operatorInfo ?? this.operatorInfo,
      activeTab: activeTab ?? this.activeTab,
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final prepaidNotifierProvider = StateNotifierProvider<PrepaidNotifier, PrepaidState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return PrepaidNotifier(repo);
});

class PrepaidNotifier extends StateNotifier<PrepaidState> {
  final ProductRepository _repo;

  PrepaidNotifier(this._repo) : super(const PrepaidState());

  void setPhoneNumber(String phone) {
    // 1. Deteksi operator seluler lokal secara instan (0ms)
    final detectedOperator = OperatorDetector.detect(phone);

    state = state.copyWith(
      phone: phone,
      operatorInfo: detectedOperator,
    );

    // 2. Jika nomor sudah 4 digit atau lebih, muat katalog produk operator tersebut
    if (phone.length >= 4 && detectedOperator.type != CellularOperatorType.unknown) {
      _loadProducts(phone, detectedOperator.name, category: state.activeTab);
    } else if (phone.length < 4) {
      state = state.copyWith(products: [], selectedProduct: null);
    }
  }

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
    if (state.phone.length >= 4 && state.operatorInfo.type != CellularOperatorType.unknown) {
      _loadProducts(state.phone, state.operatorInfo.name, category: tab);
    }
  }

  void selectProduct(ProductEntity product) {
    state = state.copyWith(selectedProduct: product);
  }

  void reset() {
    state = const PrepaidState();
  }

  Future<void> _loadProducts(String phone, String operatorName, {String? category}) async {
    state = state.copyWith(isLoading: true);
    final cat = category ?? state.activeTab;
    final products = await _repo.getProductsByOperatorPrefix(phone, operatorName, category: cat);
    state = state.copyWith(isLoading: false, products: products);
  }
}

