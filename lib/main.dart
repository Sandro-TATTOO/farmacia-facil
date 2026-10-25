import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/theme.dart';
import 'app/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: FarmaciaFacilApp(),
    ),
  );
}

class FarmaciaFacilApp extends ConsumerStatefulWidget {
  const FarmaciaFacilApp({super.key});

  @override
  ConsumerState<FarmaciaFacilApp> createState() => _FarmaciaFacilAppState();
}

class _FarmaciaFacilAppState extends ConsumerState<FarmaciaFacilApp> {
  // Router criado uma única vez — não recria a cada rebuild
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(ref as Ref);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Farmácia Fácil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
