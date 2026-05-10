// lib/screens/limits_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/app_data.dart';
import '../services/api_service.dart';

class LimitsScreen extends StatefulWidget {
  final UserData? data;
  final ValueChanged<UserData> onDataUpdated;

  const LimitsScreen({super.key, required this.data, required this.onDataUpdated});

  @override
  State<LimitsScreen> createState() => _LimitsScreenState();
}

class _LimitsScreenState extends State<LimitsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = false;
  String _error  = '';
  String _success = '';

  static const _allCats = ['Total Amount', ...UserData.allCategories];

  @override
  void initState() {
    super.initState();
    for (final cat in _allCats) {
      _controllers[cat] = TextEditingController();
    }
    _populate();
  }

  @override
  void didUpdateWidget(LimitsScreen old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) _populate();
  }

  void _populate() {
    final d = widget.data;
    if (d == null) return;
    _controllers['Total Amount']!.text =
        d.totalAmount.limit > 0 ? d.totalAmount.limit.toStringAsFixed(0) : '';
    for (final cat in UserData.allCategories) {
      final lim = d.categories[cat]!.limit;
      _controllers[cat]!.text = lim > 0 ? lim.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _loading = true; _error = ''; _success = ''; });
    try {
      final limits = <String, double>{};
      for (final cat in _allCats) {
        final txt = _controllers[cat]!.text.trim();
        if (txt.isNotEmpty) {
          final val = double.tryParse(txt);
          if (val == null || val < 0) {
            setState(() { _error = 'Invalid value for $cat.'; _loading = false; });
            return;
          }
          limits[cat] = val;
        }
      }
      if (limits.isEmpty) {
        setState(() { _error = 'Enter at least one limit.'; _loading = false; });
        return;
      }
      final updated = await ApiService.setLimits(limits);
      widget.onDataUpdated(updated);
      setState(() => _success = 'Limits saved successfully!');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Header ──────────────────────────────────────────────────────
        const Text('Budget Limits',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        const Text('Set how much you want to spend per category.',
            style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 20),

        // ── Total budget card ────────────────────────────────────────────
        _buildCard(
          cat: 'Total Amount',
          icon: Icons.account_balance_wallet_rounded,
          color: kGold,
          subtitle: 'Your overall spending cap',
        ),
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('CATEGORIES',
                  style: TextStyle(fontSize: 10, color: kMuted,
                      fontWeight: FontWeight.w700, letterSpacing: 0.9)),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
          ]),
        ),

        // ── Category cards ───────────────────────────────────────────────
        _buildCard(cat: 'Food',       icon: Icons.restaurant_rounded,  color: kGreen,  subtitle: 'Meals, groceries, dining'),
        const SizedBox(height: 10),
        _buildCard(cat: 'Stationary', icon: Icons.edit_rounded,        color: kBlue,   subtitle: 'Pens, notebooks, supplies'),
        const SizedBox(height: 10),
        _buildCard(cat: 'Clothes',    icon: Icons.checkroom_rounded,   color: kPurple, subtitle: 'Clothing & accessories'),
        const SizedBox(height: 10),
        _buildCard(cat: 'Other',      icon: Icons.category_rounded,    color: kTeal,   subtitle: 'Everything else'),
        const SizedBox(height: 24),

        // ── Current spending preview ─────────────────────────────────────
        if (widget.data != null) ...[
          _spendingPreview(),
          const SizedBox(height: 24),
        ],

        // ── Error / Success banners ──────────────────────────────────────
        if (_error.isNotEmpty)
          _banner(_error, kRed, Icons.error_outline_rounded),
        if (_success.isNotEmpty)
          _banner(_success, kGreen, Icons.check_circle_outline_rounded),
        if (_error.isNotEmpty || _success.isNotEmpty) const SizedBox(height: 16),

        // ── Save button ──────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kBg))
                : const Icon(Icons.save_rounded),
            label: Text(_loading ? 'Saving…' : 'Save Limits',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGold,
              foregroundColor: kBg,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String cat,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cat,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
            Text(subtitle,
                style: const TextStyle(color: kMuted, fontSize: 11)),
          ]),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _controllers[cat],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            textAlign: TextAlign.right,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 16),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(color: kSubtle, fontSize: 16),
              prefixText: '₹',
              prefixStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
              filled: true,
              fillColor: color.withOpacity(0.05),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color.withOpacity(0.2))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color.withOpacity(0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color, width: 1.5)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _spendingPreview() {
    final d = widget.data!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CURRENT USAGE',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: kMuted, letterSpacing: 0.9)),
        const SizedBox(height: 12),
        ...UserData.allCategories.map((cat) {
          final cd   = d.categories[cat]!;
          final pct  = cd.limit > 0
              ? (cd.totalSpent / cd.limit).clamp(0.0, 1.0)
              : 0.0;
          final over = cd.remaining < 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(cat,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(
                  '₹${cd.totalSpent.toStringAsFixed(0)} / ₹${cd.limit.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: over ? kRed : kMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: kSubtle.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(
                      over ? kRed : _catColor(cat)),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _banner(String msg, Color col, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withOpacity(0.3))),
    child: Row(children: [
      Icon(icon, color: col, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(color: col, fontSize: 13))),
    ]),
  );

  Color _catColor(String cat) {
    switch (cat) {
      case 'Food':       return kGreen;
      case 'Stationary': return kBlue;
      case 'Clothes':    return kPurple;
      default:           return kTeal;
    }
  }
}
