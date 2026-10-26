import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/home'))         return 0;
    if (loc.startsWith('/medications'))  return 1;
    if (loc.startsWith('/pharmacies'))   return 2;
    if (loc.startsWith('/assistant'))    return 3;
    if (loc.startsWith('/prescription')) return 4;
    if (loc.startsWith('/orders'))       return 5;
    if (loc.startsWith('/health-tips'))  return 6;
    if (loc.startsWith('/profile'))      return 7;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.accentGreen.withValues(alpha: 0.3),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/home');         break;
            case 1: context.go('/medications');  break;
            case 2: context.go('/pharmacies');   break;
            case 3: context.go('/assistant');    break;
            case 4: context.go('/prescription'); break;
            case 5: context.go('/orders');       break;
            case 6: context.go('/health-tips');  break;
            case 7: context.go('/profile');      break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label:        'Início',
          ),
          NavigationDestination(
            icon:         Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label:        'Remédios',
          ),
          NavigationDestination(
            icon:         Icon(Icons.local_pharmacy_outlined),
            selectedIcon: Icon(Icons.local_pharmacy),
            label:        'Farmácias',
          ),
          NavigationDestination(
            icon:         Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label:        'Assistente',
          ),
          NavigationDestination(
            icon:         Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label:        'Receita',
          ),
          NavigationDestination(
            icon:         Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label:        'Pedidos',
          ),
          NavigationDestination(
            icon:         Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label:        'Dicas',
          ),
          NavigationDestination(
            icon:         Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label:        'Perfil',
          ),
        ],
      ),
    );
  }
}
