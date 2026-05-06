import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ReceptionApp()));
}

final _supabaseInitProvider = FutureProvider<void>((ref) async {
  await SupabaseService.initialize();
});

class ReceptionApp extends ConsumerWidget {
  const ReceptionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(_supabaseInitProvider);
    return init.when(
      loading: () => MaterialApp(
        title: 'Reception App',
        theme: AppTheme.lightTheme,
        home: const _SplashScreen(),
      ),
      error: (error, _) => MaterialApp(
        title: 'Reception App',
        theme: AppTheme.lightTheme,
        home: _StartupErrorScreen(error: error),
      ),
      data: (_) {
    final router = ref.watch(appRouterProvider);
        return MaterialApp.router(
          title: 'Reception App',
          theme: AppTheme.lightTheme,
          routerConfig: router,
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Startup error')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The app failed to start.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(error.toString()),
            const SizedBox(height: 12),
            const Text(
              'Fix: update SUPABASE_URL and SUPABASE_ANON_KEY in .env, then hot restart.',
            ),
          ],
        ),
      ),
    );
  }
}
