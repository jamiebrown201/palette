import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/auth/widgets/google_sign_in_button.dart';
import 'package:palette/providers/auth_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _googleLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes (e.g. returning from Google OAuth).
    ref.listenManual(authStateProvider, (prev, next) {
      next.whenData((state) async {
        if (state.session != null) {
          await _onAuthenticated(state.session!.user);
        }
      });
    });
  }

  Future<void> _onAuthenticated(User user) async {
    await ref.read(userProfileRepositoryProvider).linkSupabaseUser(user.id);
    if (mounted) context.go('/home');
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      // OAuth opens a browser — the auth state listener handles the return.
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _googleLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _googleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletteColours.warmWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: PaletteColours.sageGreenLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  size: 36,
                  color: PaletteColours.sageGreenDark,
                ),
              ),
              const SizedBox(height: 32),
              // Headline
              Text(
                'Save Your Colour DNA',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: PaletteColours.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Create an account to keep your results, '
                'sync across devices, and unlock your full palette.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PaletteColours.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Google Sign-In
              GoogleSignInButton(
                onPressed: _signInWithGoogle,
                loading: _googleLoading,
              ),
              const SizedBox(height: 16),
              // Divider
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: PaletteColours.warmGrey),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textTertiary,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: PaletteColours.warmGrey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Email option
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.push('/auth/email'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: PaletteColours.warmGrey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue with email',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: PaletteColours.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.statusNeedsWork,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
