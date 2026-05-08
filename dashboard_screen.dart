// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';
import '../models/app_data.dart';

class DashboardScreen extends StatelessWidget {
  final UserData? data;
  final String username;
  final VoidCallback onRefresh;

  const DashboardScreen({
    super.key,
    required this.data,
    required this.username,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Center(child: CircularProgressIndicator(color: kGold));
    }
    final d = data!;
    final totalLimit = d.totalAmount.limit;
    final totalSpent = d.totalSpent;
    final remaining  = totalLimit - totalSpent;
    final pct        = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final recent     = d.allExpenses.take(5).toList();

    return RefreshIndicator(
      color: kGold,
      backgroundColor: kCard,
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Greeting ────────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hello, ${username.isEmpty ? 'there' : username} 👋',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                const Text("Here's your spending overview",
                    style: TextStyle(color: kMuted, fontSize: 13)),
              ]),
            ),
            IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, color: kMuted)),
          ]),
          const SizedBox(height: 20),

          // ── Budget overview card ─────────────────────────────────────────
          _glassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('BUDGET OVERVIEW',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: kMuted, letterSpacing: 0.9)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('₹${totalSpent.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800, color: kGold)),
                    Text('of ₹${totalLimit.toStringAsFixed(0)} budget',
                        style: const TextStyle(color: kMuted, fontSize: 13)),
                  ]),
                ),
                _ringChart(pct),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: kSubtle.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation(pct > 0.9 ? kRed : kGold),
                ),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _statChip('Spent', '₹${totalSpent.toStringAsFixed(0)}', kRed),
                _statChip('Remaining', '₹${remaining.toStringAsFixed(0)}',
                    remaining >= 0 ? kGreen : kRed),
                _statChip('Budget', '₹${totalLimit.toStringAsFixed(0)}', kBlue),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Category breakdown bars ──────────────────────────────────────
          _sectionTitle('Category Breakdown'),
          const SizedBox(height: 10),
          ...UserData.allCategories.map((cat) {
            final cd       = d.categories[cat]!;
            final catPct   = cd.limit > 0
                ? (cd.totalSpent / cd.limit).clamp(0.0, 1.0)
                : 0.0;
            final over     = cd.remaining < 0;
            final barColor = over ? kRed : _catColor(cat);
            return _glassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                        color: _catColor(cat).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(_catIcon(cat), color: _catColor(cat), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(cat,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                  ),
                  if (over)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: kRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('Over',
                          style: TextStyle(color: kRed, fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: catPct,
                    minHeight: 6,
                    backgroundColor: kSubtle.withOpacity(0.25),
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('₹${cd.totalSpent.toStringAsFixed(0)} spent',
                      style: const TextStyle(color: kMuted, fontSize: 12)),
                  Text('₹${cd.limit.toStringAsFixed(0)} limit',
                      style: const TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ]),
            );
          }),
          const SizedBox(height: 16),

          // ── Donut chart ──────────────────────────────────────────────────
          if (d.totalSpent > 0) ...[
            _sectionTitle('Spending Mix'),
            const SizedBox(height: 10),
            _glassCard(
              child: Column(children: [
                SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(
                    centerSpaceRadius: 55,
                    sectionsSpace: 3,
                    sections: UserData.allCategories
                        .where((c) => d.categories[c]!.totalSpent > 0)
                        .map((c) {
                      final spent = d.categories[c]!.totalSpent;
                      return PieChartSectionData(
                        value: spent,
                        color: _catColor(c),
                        radius: 35,
                        showTitle: false,
                      );
                    }).toList(),
                  )),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12, runSpacing: 6,
                  children: UserData.allCategories
                      .where((c) => d.categories[c]!.totalSpent > 0)
                      .map((c) => Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(
                                color: _catColor(c),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(c, style: const TextStyle(color: kMuted, fontSize: 12)),
                      ]))
                      .toList(),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── Recent expenses ──────────────────────────────────────────────
          _sectionTitle('Recent Expenses'),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            _glassCard(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(children: [
                    Icon(Icons.receipt_long_rounded, color: kMuted, size: 36),
                    SizedBox(height: 10),
                    Text('No expenses yet',
                        style: TextStyle(color: kMuted, fontSize: 14)),
                  ]),
                ),
              ),
            )
          else
            _glassCard(
              child: Column(
                children: recent.asMap().entries.map((e) {
                  final exp  = e.value;
                  final last = e.key == recent.length - 1;
                  return Column(children: [
                    _expenseTile(exp),
                    if (!last) Divider(color: Colors.white.withOpacity(0.07), height: 1),
                  ]);
                }).toList(),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _expenseTile(Expense exp) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
            color: _catColor(exp.category).withOpacity(0.15),
            borderRadius: BorderRadius.circular(9)),
        child: Icon(_catIcon(exp.category),
            color: _catColor(exp.category), size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exp.item,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
          Text('${exp.category} · ${exp.date}',
              style: const TextStyle(color: kMuted, fontSize: 11)),
        ]),
      ),
      Text('₹${exp.amount.toStringAsFixed(0)}',
          style: const TextStyle(
              color: kRed, fontWeight: FontWeight.w700, fontSize: 14)),
    ]),
  );

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white));

  Widget _statChip(String label, String value, Color col) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: kMuted, fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: col, fontWeight: FontWeight.w700, fontSize: 14)),
    ],
  );

  Widget _ringChart(double pct) {
    final col = pct > 0.9 ? kRed : kGold;
    return SizedBox(
      width: 70, height: 70,
      child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 26,
          sections: [
            PieChartSectionData(value: pct * 100, color: col, radius: 10, showTitle: false),
            PieChartSectionData(
                value: (1 - pct) * 100,
                color: kSubtle.withOpacity(0.3),
                radius: 10,
                showTitle: false),
          ],
        )),
        Text('${(pct * 100).toInt()}%',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? margin}) => Container(
    margin: margin ?? EdgeInsets.zero,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: child,
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
