import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'crops_screen.dart';
import 'krushi_doctor.dart';
import 'mandi_price.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  static const _teal = Color(0xFF00897B);

  final List<Widget> _pages = const [
    HomeScreen(),
    CropsScreen(),
    KrushiDoctor(),
    BazaarScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, Icons.home_outlined, 'होम'),
                _navItem(1, Icons.eco_rounded, Icons.eco_outlined, 'पिके'),
                _navItem(2, Icons.medical_services_rounded, Icons.medical_services_outlined, 'डॉक्टर'),
                _navItem(3, Icons.trending_up_rounded, Icons.trending_up_outlined, 'बाजार'),
                _navItem(4, Icons.person_rounded, Icons.person_outlined, 'प्रोफाइल'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _teal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            isActive ? activeIcon : inactiveIcon,
            color: isActive ? _teal : Colors.black38,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                color: isActive ? _teal : Colors.black38,
              )),
        ]),
      ),
    );
  }
}
