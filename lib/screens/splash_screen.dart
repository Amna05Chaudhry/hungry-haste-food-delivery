import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Original "Food for Everyone" onboarding screen, kept in the brand orange.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    final state = context.read<AppState>();
    var signedIn = false;
    try {
      signedIn = await state.restoreSession();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, signedIn ? Routes.home : Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Scaffold(
      backgroundColor: brandOrange,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(children: [
              Positioned(
                left: -20,
                bottom: 90,
                height: 380,
                child: Image.asset('assets/images/ToyFaces1.png'),
              ),
              Positioned(
                right: -10,
                bottom: 120,
                height: 290,
                child: Image.asset('assets/images/ToyFaces2.png'),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.55, 0.9],
                      colors: [brandOrange.withValues(alpha: 0), const Color(0xFFFF460A)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      height: 72,
                      width: 72,
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Image.asset('assets/images/Bella.png'),
                    ),
                    const Spacer(),
                    if (state.backend.isDemo)
                      const Chip(
                        avatar: Icon(Icons.science_outlined, size: 16),
                        label: Text('Demo mode'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ]),
                  const SizedBox(height: 28),
                  const Text(
                    'Food for\nEveryone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hungry Haste: order from the menu, track your delivery.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: brandOrange,
                    ),
                    onPressed: _busy ? null : _start,
                    child: _busy
                        ? const SizedBox(
                            height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Text('Get started'),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () => Navigator.pushNamed(context, Routes.admin),
                      child: const Text('Restaurant admin →'),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
