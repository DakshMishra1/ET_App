// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/app_data.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'add_expense_screen.dart';
import 'limits_screen.dart';
import 'auth_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;
  UserData? _data;
  bool _loading = true;
  String _error = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final u = await ApiService.getSavedUsername();
      final d = await ApiService.fetchData();
      if (mounted) setState(() { _username = u ?? ''; _data = d; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDataUpdated(UserData updated) {
    if (mounted) setState(() => _data = updated);
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardScreen(data: _data, username: _username, onRefresh: _load),
      ExpensesScreen(data: _data, onDataUpdated: _onDataUpdated),
      LimitsScreen(data: _data, onDataUpdated: _onDataUpdated),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg2,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.account_balance_wallet_rounded, size: 18, color: kBg),
          ),
          const SizedBox(width: 10),
          const Text('ExpenseTracker',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
        ]),
        actions: [
          if (_username.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 16, color: kMuted),
                label: Text(_username,
                    style: const TextStyle(color: kMuted, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : _error.isNotEmpty
              ? _buildError()
              : tabs[_tab],
      floatingActionButton: _tab == 1 && _data != null
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(onDataUpdated: _onDataUpdated),
                  ),
                );
                if (result == true) _load();
              },
              backgroundColor: kGold,
              foregroundColor: kBg,
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kBg2,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: kGold.withOpacity(0.15),
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_rounded, color: kMuted),
              selectedIcon: Icon(Icons.dashboard_rounded, color: kGold),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded, color: kMuted),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: kGold),
              label: 'Expenses',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_rounded, color: kMuted),
              selectedIcon: Icon(Icons.tune_rounded, color: kGold),
              label: 'Limits',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_rounded, color: kRed, size: 52),
        const SizedBox(height: 16),
        Text(_error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kMuted, fontSize: 14)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
              backgroundColor: kGold, foregroundColor: kBg),
        ),
      ]),
    ),
  );
}
