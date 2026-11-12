import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'information_page.dart';
import 'notification_settings_page.dart';
import 'prayer_page.dart';
import 'weather_home_page.dart';

/// Kerangka navigasi utama: Cuaca, Jadwal Salat, Notifikasi, Informasi.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.appState});

  final AppState appState;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _openTab(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          WeatherHomePage(
            weatherService: widget.appState.weatherService,
            locationService: widget.appState.locationService,
            onWeatherLoaded: (bundle) {
              widget.appState.updateWeather(bundle);
            },
          ),
          PrayerPage(
            appState: widget.appState,
            onOpenWeatherTab: () => _openTab(0),
          ),
          NotificationSettingsPage(appState: widget.appState),
          const InformationPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _openTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Cuaca',
          ),
          NavigationDestination(
            icon: Icon(Icons.mosque_outlined),
            selectedIcon: Icon(Icons.mosque),
            label: 'Jadwal Salat',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Informasi',
          ),
        ],
      ),
    );
  }
}
