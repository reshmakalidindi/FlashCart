import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';
import '../widgets/flash_cart_app_bar.dart';
import '../widgets/product_card.dart';
import 'scanner_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class _CategoryItem {
  final String id;
  final String name;
  final String assetPath;
  final IconData fallbackIcon;
  final Color fallbackColor;

  const _CategoryItem({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.fallbackIcon,
    required this.fallbackColor,
  });
}

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  static HomeScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<HomeScreenState>();
  }

  static void switchTab(BuildContext context, int tabIndex) {
    final state = of(context);
    if (state != null) {
      state.onTabTapped(tabIndex);
    }
  }

  static void openCart(BuildContext context) {
    final state = of(context);
    if (state != null) {
      state.navigateToCart();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
    }
  }

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryFilter;

  final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileNavKey = GlobalKey<NavigatorState>();

  static const List<_CategoryItem> _categories = [
    _CategoryItem(
      id: 'food',
      name: 'Food',
      assetPath: 'assets/categories/food.png',
      fallbackIcon: Icons.fastfood_rounded,
      fallbackColor: Color(0xFFFFECE5),
    ),
    _CategoryItem(
      id: 'stationery',
      name: 'Stationery',
      assetPath: 'assets/categories/stationery.png',
      fallbackIcon: Icons.edit_note_rounded,
      fallbackColor: Color(0xFFE5F1FF),
    ),
    _CategoryItem(
      id: 'clothes',
      name: 'Clothes',
      assetPath: 'assets/categories/clothes.png',
      fallbackIcon: Icons.checkroom_rounded,
      fallbackColor: Color(0xFFFFECEB),
    ),
    _CategoryItem(
      id: 'groceries',
      name: 'Groceries',
      assetPath: 'assets/categories/groceries.png',
      fallbackIcon: Icons.local_grocery_store_rounded,
      fallbackColor: Color(0xFFE8F5E9),
    ),
    _CategoryItem(
      id: 'utensils',
      name: 'Utensils',
      assetPath: 'assets/categories/utensils.png',
      fallbackIcon: Icons.soup_kitchen_rounded,
      fallbackColor: Color(0xFFEDE7F6),
    ),
    _CategoryItem(
      id: 'toys',
      name: 'Toys',
      assetPath: 'assets/categories/toys.png',
      fallbackIcon: Icons.toys_rounded,
      fallbackColor: Color(0xFFFFF8E1),
    ),
    _CategoryItem(
      id: 'footwear',
      name: 'Footwear',
      assetPath: 'assets/categories/footwear.png',
      fallbackIcon: Icons.snowshoeing_rounded,
      fallbackColor: Color(0xFFE0F7FA),
    ),
    _CategoryItem(
      id: 'cosmetics',
      name: 'Cosmetics',
      assetPath: 'assets/categories/cosmetics.png',
      fallbackIcon: Icons.spa_rounded,
      fallbackColor: Color(0xFFFCE4EC),
    ),
  ];

  late final List<Product> _catalogProducts;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _catalogProducts = AppConstants.sampleProducts.map((map) => Product.fromMap(map, map['productId'] ?? '')).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void onTabTapped(int index) {
    if (_currentIndex == index) {
      if (index == 0) {
        _homeNavKey.currentState?.popUntil((route) => route.isFirst);
      } else if (index == 2) {
        _profileNavKey.currentState?.popUntil((route) => route.isFirst);
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void navigateToCart() {
    setState(() => _currentIndex = 0);
    _homeNavKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentIndex == 0 && _homeNavKey.currentState?.canPop() == true) {
          _homeNavKey.currentState?.pop();
          return;
        }

        if (_currentIndex == 2 && _profileNavKey.currentState?.canPop() == true) {
          _profileNavKey.currentState?.pop();
          return;
        }

        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 0: Home tab with nested navigator preserving state & displaying bottom bar
            Navigator(
              key: _homeNavKey,
              onGenerateRoute: (routeSettings) {
                return MaterialPageRoute(
                  builder: (context) => SafeArea(child: _buildHomeView(context)),
                );
              },
            ),
            // Tab 1: Existing Working Scanner Screen
            ScannerScreen(
              key: const ValueKey('scanner_tab'),
              isActive: _currentIndex == 1,
              showAppBar: true,
            ),
            // Tab 2: Customer Profile Screen with working logout & nested navigator
            Navigator(
              key: _profileNavKey,
              onGenerateRoute: (routeSettings) {
                return MaterialPageRoute(
                  builder: (context) => const ProfileScreen(
                    key: ValueKey('profile_tab'),
                    showAppBar: true,
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: onTabTapped,
            backgroundColor: AppColors.white,
            selectedItemColor: AppColors.leafGreen,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11.5),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11.5),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_outlined),
                activeIcon: Icon(Icons.qr_code_scanner_rounded),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeView(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final filteredCategories = _searchQuery.trim().isEmpty
        ? _categories
        : _categories
            .where((cat) => cat.name.toLowerCase().contains(_searchQuery.trim().toLowerCase()))
            .toList();

    final displayedProducts = _catalogProducts.where((p) {
      final matchesSearch = _searchQuery.trim().isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.trim().toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.trim().toLowerCase()) ||
          p.barcode.toLowerCase().contains(_searchQuery.trim().toLowerCase());
      final matchesCat = _selectedCategoryFilter == null ||
          p.category.toLowerCase() == _selectedCategoryFilter!.toLowerCase();
      return matchesSearch && matchesCat;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header Area (Location / Store & Actions)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location & Store Identifier
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'FlashCart Store #001 • CyberCity',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTimeGreeting(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Welcome to FlashCart',
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('FlashCart Store is open • Self-checkout active'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
                    tooltip: 'Notifications',
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary, size: 24),
                        tooltip: 'View Cart',
                      ),
                      if (cartProvider.itemCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              '${cartProvider.itemCount}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const ProfileAvatarButton(),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Polished Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.leafGreen, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      hintText: 'Search for products...',
                      hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedCategoryFilter = null;
                      });
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.leafGreen),
                    tooltip: 'Filters',
                    onPressed: () {
                      setState(() {
                        _selectedCategoryFilter = null;
                      });
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 3. Fresh Groceries Promotional Banner
          InkWell(
            onTap: () {
              onTabTapped(1);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.butterYellow, Color(0xFFFFF4C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEED78A), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldenYellow.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/banner_groceries.png',
                      width: 95,
                      height: 82,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 95,
                        height: 82,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.shopping_basket_rounded, color: AppColors.primary, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Shopping, Made Simple',
                          style: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Scan your products, pay with ease, and skip the checkout queue.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF383838),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.goldenYellow, width: 1),
                              ),
                              child: Text(
                                'Scan • Add • Pay',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.leafGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.leafGreen),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // 4. Shop by Category Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shop by Category',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedCategoryFilter = null;
                  });
                },
                child: Text(
                  'See All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.leafGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 5. Category Cards Grid (4 cols x 2 rows = 8 categories)
          // Strictly image & name only; NO prices or plus buttons
          if (filteredCategories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No categories found for "$_searchQuery"',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            GridView.builder(
              key: const ValueKey('category_grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final cat = filteredCategories[index];
                return _buildCategoryCard(context, cat);
              },
            ),

          const SizedBox(height: 24),

          // 6. Popular In-Store Products Showcase
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategoryFilter != null
                    ? '$_selectedCategoryFilter Items'
                    : 'Popular In-Store Products',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${displayedProducts.length} items',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 7. Product Cards Grid (2 columns)
          if (displayedProducts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 44, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'No products found matching your search.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final product = displayedProducts[index];
                return ProductCard(product: product);
              },
            ),

          const SizedBox(height: 24),

          // 8. Self-Checkout Callout Card (NO QR icon)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.butterYellow, Color(0xFFFFF2C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.goldenYellow, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.goldenYellow.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.shopping_basket_rounded, color: AppColors.leafGreen, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to shop in-store?',
                        style: GoogleFonts.inter(
                          color: AppColors.charcoal,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scan barcodes from shelves to build your live bill instantly.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF4A4A4A),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => onTabTapped(1),
                  child: Text(
                    'Scan Now',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Category Card containing ONLY an image and category name.
  /// Strictly NO prices, NO add buttons, NO plus symbols.
  Widget _buildCategoryCard(BuildContext context, _CategoryItem cat) {
    final isSelected = _selectedCategoryFilter != null &&
        _selectedCategoryFilter!.toLowerCase() == cat.name.toLowerCase();

    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedCategoryFilter == cat.name) {
            _selectedCategoryFilter = null;
          } else {
            _selectedCategoryFilter = cat.name;
          }
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing ${cat.name} items. Scan barcodes on shelves to add!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Open Scan',
              textColor: Colors.white,
              onPressed: () => onTabTapped(1),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.leafGreen : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Image.asset(
                  cat.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: cat.fallbackColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(cat.fallbackIcon, color: AppColors.primary, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cat.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.leafGreen : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
