// lib/models/app_data.dart

class Expense {
  final String item;
  final double amount;
  final String date;
  final String category;

  const Expense({
    required this.item,
    required this.amount,
    required this.date,
    required this.category,
  });

  factory Expense.fromJson(Map<String, dynamic> json, String category) {
    return Expense(
      item:     json['item']   as String? ?? '',
      amount:   ((json['amount'] ?? 0) as num).toDouble(),
      date:     json['date']   as String? ?? '',
      category: category,
    );
  }

  Map<String, dynamic> toJson() => {
    'item':   item,
    'amount': amount,
    'date':   date,
  };
}

class CategoryData {
  final double limit;
  final List<Expense> expenses;

  const CategoryData({required this.limit, required this.expenses});

  factory CategoryData.fromJson(Map<String, dynamic> json, String category) {
    final rawExpenses = json['expenses'] as List<dynamic>? ?? [];
    return CategoryData(
      limit:    ((json['limit'] ?? 0) as num).toDouble(),
      expenses: rawExpenses
          .map((e) => Expense.fromJson(e as Map<String, dynamic>, category))
          .toList(),
    );
  }

  double get totalSpent =>
      expenses.fold(0, (sum, e) => sum + e.amount);

  double get remaining => limit - totalSpent;
}

class UserData {
  final CategoryData totalAmount;
  final Map<String, CategoryData> categories;

  static const allCategories = ['Food', 'Stationary', 'Clothes', 'Other'];

  const UserData({required this.totalAmount, required this.categories});

  factory UserData.fromJson(Map<String, dynamic> json) {
    final cats = <String, CategoryData>{};
    for (final cat in allCategories) {
      cats[cat] = CategoryData.fromJson(
        json[cat] as Map<String, dynamic>? ?? {},
        cat,
      );
    }
    return UserData(
      totalAmount: CategoryData.fromJson(
        json['Total Amount'] as Map<String, dynamic>? ?? {},
        'Total Amount',
      ),
      categories: cats,
    );
  }

  double get totalSpent =>
      categories.values.fold(0, (s, c) => s + c.totalSpent);

  /// All expenses from every category, sorted newest first.
  List<Expense> get allExpenses {
    final all = <Expense>[];
    for (final c in categories.values) {
      all.addAll(c.expenses);
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }
}
