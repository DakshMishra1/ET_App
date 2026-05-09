// lib/screens/expenses_screen.dart
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/app_data.dart';
import '../services/api_service.dart';

class ExpensesScreen extends StatefulWidget {
  final UserData? data;
  final ValueChanged<UserData> onDataUpdated;

  const ExpensesScreen({super.key, required this.data, required this.onDataUpdated});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _allCats = ['All', ...UserData.allCategories];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _allCats.length, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _delete(String category, int index) async {
    try {
      final updated = await ApiService.deleteExpense(category, index);
      widget.onDataUpdated(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: kRed,
        ));
      }
    }
  }

  List<Expense> _expensesForTab(int tabIdx) {
    final d = widget.data;
    if (d == null) return [];
    if (tabIdx == 0) return d.allExpenses;
    final cat = _allCats[tabIdx];
    return d.categories[cat]!.expenses
        .asMap()
        .entries
        .map((e) => e.value)
        .toList()
        .reversed
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Column(
      children: [
        // ── Tab bar ───────────────────────────────────────────────────────
        Container(
          color: kBg2,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            indicatorColor: kGold,
            indicatorWeight: 2.5,
            labelColor: kGold,
            unselectedLabelColor: kMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabAlignment: TabAlignment.start,
            tabs: _allCats.map((c) {
              int count = 0;
              if (d != null) {
                count = c == 'All'
                    ? d.allExpenses.length
                    : (d.categories[c]?.expenses.length ?? 0);
              }
              return Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(c),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                          color: kGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('$count',
                          style: const TextStyle(color: kGold, fontSize: 10)),
                    ),
                  ]
                ]),
              );
            }).toList(),
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: List.generate(_allCats.length, (tabIdx) {
              final expenses = _expensesForTab(tabIdx);
              if (expenses.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.receipt_long_rounded, color: kMuted, size: 52),
                    const SizedBox(height: 14),
                    const Text('No expenses here',
                        style: TextStyle(color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Tap + to add one',
                        style: TextStyle(color: kMuted, fontSize: 13)),
                  ]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                itemCount: expenses.length,
                itemBuilder: (ctx, i) {
                  final exp = expenses[i];
                  // For 'All' tab we need original category index
                  int realIndex = i;
                  if (tabIdx == 0) {
                    // find real index within that category
                    final catExps = d!.categories[exp.category]!.expenses;
                    realIndex = catExps.indexWhere(
                        (e) => e.item == exp.item &&
                               e.amount == exp.amount &&
                               e.date == exp.date);
                  }

                  return Dismissible(
                    key: Key('${exp.category}-$realIndex-${exp.item}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: kRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.delete_rounded, color: kRed),
                    ),
                    confirmDismiss: (_) => showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: kCard,
                        title: const Text('Delete expense?',
                            style: TextStyle(color: Colors.white)),
                        content: Text('Remove "${exp.item}"?',
                            style: const TextStyle(color: kMuted)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel',
                                  style: TextStyle(color: kMuted))),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: kRed))),
                        ],
                      ),
                    ),
                    onDismissed: (_) => _delete(exp.category, realIndex),
                    child: _expenseCard(exp),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _expenseCard(Expense exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: _catColor(exp.category).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(_catIcon(exp.category), color: _catColor(exp.category), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exp.item,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
            const SizedBox(height: 3),
            Row(children: [
              _chip(exp.category, _catColor(exp.category)),
              const SizedBox(width: 6),
              Text(exp.date, style: const TextStyle(color: kMuted, fontSize: 11)),
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${exp.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: kRed, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 2),
          const Text('Swipe to delete',
              style: TextStyle(color: kSubtle, fontSize: 9)),
        ]),
      ]),
    );
  }

  Widget _chip(String label, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  Color _catColor(String cat) {
    switch (cat) {
      case 'Food':       return kGreen;
      case 'Stationary': return kBlue;
      case 'Clothes':    return kPurple;
      default:           return kTeal;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Food':       return Icons.restaurant_rounded;
      case 'Stationary': return Icons.edit_rounded;
      case 'Clothes':    return Icons.checkroom_rounded;
      default:           return Icons.category_rounded;
    }
  }
}
