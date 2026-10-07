import 'package:flutter/material.dart';

import '../../../../database/converters/transaction_type.dart';

/// Represents a curated category icon with name, category group, and search tags.
class CategoryIconItem {
  const CategoryIconItem({
    required this.icon,
    required this.name,
    required this.group,
    this.tags = const [],
  });

  final IconData icon;
  final String name;
  final String group;
  final List<String> tags;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final lower = query.toLowerCase();
    if (name.toLowerCase().contains(lower)) return true;
    if (group.toLowerCase().contains(lower)) return true;
    return tags.any((tag) => tag.toLowerCase().contains(lower));
  }
}

/// Reusable icon picker widget with categorized filtering and real-time search.
class CategoryIconPicker extends StatefulWidget {
  const CategoryIconPicker({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconSelected,
    this.categoryType,
  });

  /// The currently selected icon.
  final IconData selectedIcon;

  /// The category color used to highlight the selected icon.
  final int selectedColor;

  /// Callback when an icon is selected.
  final ValueChanged<IconData> onIconSelected;

  /// Optional context transaction type for default group selection.
  final TransactionType? categoryType;

  /// Curated icon catalogue organized into groups with search tags.
  static const List<CategoryIconItem> allIcons = [
    // Food & Dining
    CategoryIconItem(
      icon: Icons.restaurant,
      name: 'Restaurant',
      group: 'Food',
      tags: ['dining', 'dinner', 'lunch', 'eat', 'meal'],
    ),
    CategoryIconItem(
      icon: Icons.fastfood,
      name: 'Fast Food',
      group: 'Food',
      tags: ['burger', 'fries', 'snack', 'junk food'],
    ),
    CategoryIconItem(
      icon: Icons.local_cafe,
      name: 'Coffee & Cafe',
      group: 'Food',
      tags: ['coffee', 'tea', 'cafe', 'starbucks', 'beverage'],
    ),
    CategoryIconItem(
      icon: Icons.local_bar,
      name: 'Bar & Alcohol',
      group: 'Food',
      tags: ['drink', 'beer', 'cocktail', 'nightlife', 'wine'],
    ),
    CategoryIconItem(
      icon: Icons.cake,
      name: 'Bakery & Cake',
      group: 'Food',
      tags: ['dessert', 'sweet', 'birthday', 'pastry'],
    ),
    CategoryIconItem(
      icon: Icons.icecream,
      name: 'Ice Cream',
      group: 'Food',
      tags: ['snack', 'gelato', 'dessert'],
    ),
    CategoryIconItem(
      icon: Icons.local_pizza,
      name: 'Pizza',
      group: 'Food',
      tags: ['italian', 'dinner', 'takeout'],
    ),

    // Transport & Travel
    CategoryIconItem(
      icon: Icons.directions_car,
      name: 'Car & Auto',
      group: 'Transport',
      tags: ['drive', 'vehicle', 'automobile'],
    ),
    CategoryIconItem(
      icon: Icons.directions_bus,
      name: 'Bus & Transit',
      group: 'Transport',
      tags: ['public transport', 'transjakarta', 'commute'],
    ),
    CategoryIconItem(
      icon: Icons.local_gas_station,
      name: 'Fuel & Gas',
      group: 'Transport',
      tags: ['petrol', 'gasoline', 'pertamina', 'shell', 'bensin'],
    ),
    CategoryIconItem(
      icon: Icons.two_wheeler,
      name: 'Motorcycle & Bike',
      group: 'Transport',
      tags: ['motorbike', 'scooter', 'motor', 'ojek'],
    ),
    CategoryIconItem(
      icon: Icons.local_taxi,
      name: 'Taxi & Rideshare',
      group: 'Transport',
      tags: ['grab', 'gojek', 'maxim', 'cab'],
    ),
    CategoryIconItem(
      icon: Icons.flight,
      name: 'Flight & Airplane',
      group: 'Transport',
      tags: ['travel', 'vacation', 'holiday', 'plane'],
    ),
    CategoryIconItem(
      icon: Icons.train,
      name: 'Train & Railway',
      group: 'Transport',
      tags: ['mrt', 'lrt', 'kai', 'subway'],
    ),
    CategoryIconItem(
      icon: Icons.commute,
      name: 'Daily Commute',
      group: 'Transport',
      tags: ['travel', 'work route'],
    ),

    // Shopping
    CategoryIconItem(
      icon: Icons.shopping_bag,
      name: 'Shopping Bag',
      group: 'Shopping',
      tags: ['mall', 'retail', 'clothes', 'purchase'],
    ),
    CategoryIconItem(
      icon: Icons.shopping_cart,
      name: 'Supermarket',
      group: 'Shopping',
      tags: ['groceries', 'indomaret', 'alfamart', 'market'],
    ),
    CategoryIconItem(
      icon: Icons.store,
      name: 'Store & Shop',
      group: 'Shopping',
      tags: ['convenience', 'outlet'],
    ),
    CategoryIconItem(
      icon: Icons.checkroom,
      name: 'Fashion & Clothes',
      group: 'Shopping',
      tags: ['apparel', 'shoes', 'outfit', 'wardrobe'],
    ),
    CategoryIconItem(
      icon: Icons.sell,
      name: 'Deals & Sales',
      group: 'Shopping',
      tags: ['discount', 'promo', 'clearance'],
    ),

    // Bills & Utilities
    CategoryIconItem(
      icon: Icons.receipt_long,
      name: 'Bills & Invoice',
      group: 'Bills',
      tags: ['utility', 'tax', 'receipt', 'tagihan'],
    ),
    CategoryIconItem(
      icon: Icons.home,
      name: 'Housing & Rent',
      group: 'Bills',
      tags: ['apartment', 'kost', 'mortgage', 'property'],
    ),
    CategoryIconItem(
      icon: Icons.bolt,
      name: 'Electricity',
      group: 'Bills',
      tags: ['pln', 'token', 'power', 'energy'],
    ),
    CategoryIconItem(
      icon: Icons.water_drop,
      name: 'Water & Utilities',
      group: 'Bills',
      tags: ['pdam', 'water utility'],
    ),
    CategoryIconItem(
      icon: Icons.wifi,
      name: 'Internet & WiFi',
      group: 'Bills',
      tags: ['broadband', 'indihome', 'biznet', 'data'],
    ),
    CategoryIconItem(
      icon: Icons.phone_android,
      name: 'Mobile Phone',
      group: 'Bills',
      tags: ['pulsa', 'telecom', 'telkomsel', 'xl', 'indosat'],
    ),
    CategoryIconItem(
      icon: Icons.build,
      name: 'Repair & Tools',
      group: 'Bills',
      tags: ['maintenance', 'hardware', 'service'],
    ),
    CategoryIconItem(
      icon: Icons.cleaning_services,
      name: 'Cleaning & Laundry',
      group: 'Bills',
      tags: ['laundry', 'maid', 'hygiene'],
    ),

    // Health & Wellness
    CategoryIconItem(
      icon: Icons.medical_services,
      name: 'Medical & Health',
      group: 'Health',
      tags: ['hospital', 'doctor', 'clinic', 'dentist'],
    ),
    CategoryIconItem(
      icon: Icons.local_pharmacy,
      name: 'Pharmacy',
      group: 'Health',
      tags: ['medicine', 'drugs', 'apotek', 'vitamins'],
    ),
    CategoryIconItem(
      icon: Icons.fitness_center,
      name: 'Fitness & Gym',
      group: 'Health',
      tags: ['workout', 'exercise', 'training', 'sport'],
    ),
    CategoryIconItem(
      icon: Icons.spa,
      name: 'Beauty & Spa',
      group: 'Health',
      tags: ['salon', 'barber', 'haircut', 'skincare'],
    ),
    CategoryIconItem(
      icon: Icons.sports_soccer,
      name: 'Sports & Games',
      group: 'Health',
      tags: ['football', 'badminton', 'match', 'futsal'],
    ),

    // Leisure & Life
    CategoryIconItem(
      icon: Icons.movie,
      name: 'Cinema & Movie',
      group: 'Leisure',
      tags: ['netflix', 'film', 'theater', 'xx1'],
    ),
    CategoryIconItem(
      icon: Icons.sports_esports,
      name: 'Gaming',
      group: 'Leisure',
      tags: ['playstation', 'steam', 'xbox', 'nintendo'],
    ),
    CategoryIconItem(
      icon: Icons.music_note,
      name: 'Music & Audio',
      group: 'Leisure',
      tags: ['spotify', 'concert', 'streaming'],
    ),
    CategoryIconItem(
      icon: Icons.pets,
      name: 'Pets',
      group: 'Leisure',
      tags: ['dog', 'cat', 'veterinary', 'pet food'],
    ),
    CategoryIconItem(
      icon: Icons.card_giftcard,
      name: 'Gift & Donation',
      group: 'Leisure',
      tags: ['present', 'charity', 'birthday', 'zakat'],
    ),
    CategoryIconItem(
      icon: Icons.school,
      name: 'Education & School',
      group: 'Leisure',
      tags: ['tuition', 'course', 'college', 'books'],
    ),
    CategoryIconItem(
      icon: Icons.menu_book,
      name: 'Books & Learning',
      group: 'Leisure',
      tags: ['reading', 'novel', 'study'],
    ),

    // Finance & Income
    CategoryIconItem(
      icon: Icons.payments,
      name: 'Salary & Wages',
      group: 'Finance',
      tags: ['payroll', 'paycheck', 'gaji', 'income'],
    ),
    CategoryIconItem(
      icon: Icons.trending_up,
      name: 'Investments',
      group: 'Finance',
      tags: ['stocks', 'crypto', 'shares', 'mutual fund', 'reksadana'],
    ),
    CategoryIconItem(
      icon: Icons.savings,
      name: 'Savings & Deposit',
      group: 'Finance',
      tags: ['tabungan', 'piggy bank', 'emergency fund'],
    ),
    CategoryIconItem(
      icon: Icons.work,
      name: 'Side Job & Freelance',
      group: 'Finance',
      tags: ['freelance', 'project', 'gig', 'hustle'],
    ),
    CategoryIconItem(
      icon: Icons.monetization_on,
      name: 'Bonus & Allowance',
      group: 'Finance',
      tags: ['thr', 'bonus', 'dividend', 'reward'],
    ),
    CategoryIconItem(
      icon: Icons.account_balance,
      name: 'Bank & Transfer',
      group: 'Finance',
      tags: ['atm', 'bca', 'mandiri', 'bni', 'transfer'],
    ),
    CategoryIconItem(
      icon: Icons.credit_card,
      name: 'Credit Card',
      group: 'Finance',
      tags: ['card', 'installment', 'cicilan'],
    ),
  ];

  static const List<String> groups = [
    'All',
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Leisure',
    'Finance',
  ];

  @override
  State<CategoryIconPicker> createState() => _CategoryIconPickerState();
}

class _CategoryIconPickerState extends State<CategoryIconPicker> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedGroup;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.categoryType == TransactionType.income
        ? 'Finance'
        : 'All';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryIconItem> get _filteredIcons {
    return CategoryIconPicker.allIcons.where((item) {
      if (_selectedGroup != 'All' && item.group != _selectedGroup) {
        return false;
      }
      return item.matches(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filteredIcons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Title
        Text(
          'Icon',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Search Input
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search icons (e.g. food, salary, car)...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onChanged: (val) {
            setState(() => _searchQuery = val.trim());
          },
        ),
        const SizedBox(height: 8),

        // Group Filter Chips
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CategoryIconPicker.groups.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final group = CategoryIconPicker.groups[index];
              final isSelected = group == _selectedGroup;

              return ChoiceChip(
                label: Text(group),
                selected: isSelected,
                labelStyle: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedGroup = group);
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Icons Grid Box
        Container(
          height: 180,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        size: 32,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No icons match "$_searchQuery"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected = item.icon == widget.selectedIcon;

                    return Tooltip(
                      message: item.name,
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: item.name,
                        child: InkWell(
                          onTap: () => widget.onIconSelected(item.icon),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(widget.selectedColor)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Color(widget.selectedColor)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurfaceVariant,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
