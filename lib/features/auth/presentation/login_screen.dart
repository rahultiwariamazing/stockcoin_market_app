// File: lib/features/auth/presentation/login_screen.dart
// MAUI note: Keep UI in screens/widgets and logic in providers/services.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/styles/app_text_styles.dart';
import '../../../core/utils/validators.dart';

import '../../../shared/widgets/app_loader.dart' show AppLoader;
import 'providers/environment_provider.dart';
import 'providers/auth_provider.dart';

// MAUI map: ConsumerStatefulWidget = page with local state + provider access.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {

  /// ✅ Form key
  final _formKey = GlobalKey<FormState>();

  /// ✅ Controllers
  final _emailController =
      TextEditingController(text: "test@gmail.com");

  final _passwordController =
      TextEditingController(text: "123456");

  /// ✅ Local loader state
  bool _isLoading = false;

  String _loaderMessage = "Please wait...";

  /// ✅ Login logic (UI-trigger only)
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // MAUI map: local busy state update (like IsBusy + OnPropertyChanged).
    setState(() {
      _loaderMessage = "Checking authorization...";
      _isLoading = true;
    });

    final selectedEnv = ref.read(environmentProvider);

    await ref.read(authProvider.notifier).login(
          email: _emailController.text,
          environment: selectedEnv,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.error != null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.error!)),
      );
      return;
    }

    setState(() {
      _loaderMessage = "Login successful...";
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {

    /// MAUI map: ref.watch() is similar to UI binding to ViewModel state.
    final selectedEnv = ref.watch(environmentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: Stack(
        children: [

          /// MAUI map: Stack lets us overlay loader on top of page content.
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  const SizedBox(height: 40),

                  /// ✅ LOGO
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.currency_bitcoin,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ✅ TITLE
                  Text(
                    "Crypto Tracker",
                    style: AppTextStyles.heading.copyWith(fontSize: 26),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Login to continue",
                    style: AppTextStyles.subText,
                  ),

                  const SizedBox(height: 30),

                  /// ✅ ENVIRONMENT SELECTOR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ["DEV", "QA", "PROD"].map((env) {

                      final isSelected = selectedEnv == env;

                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(environmentProvider.notifier)
                              .state = env;
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            env,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  /// ✅ FORM CARD
                  Container(
                    padding: const EdgeInsets.all(AppSizes.padding),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                          BorderRadius.circular(AppSizes.cardRadius),
                    ),

                    child: Form(
                      key: _formKey,

                      child: Column(
                        children: [

                          /// ✅ EMAIL (REUSED VALIDATOR)
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: Validators.validateEmail,
                          ),

                          const SizedBox(height: AppSizes.gapMedium),

                          /// ✅ PASSWORD (REUSED VALIDATOR)
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: Validators.validatePassword,
                          ),

                          const SizedBox(height: 20),

                          /// ✅ LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: AppSizes.buttonHeight,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              child: const Text("Login"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ✅ LOADER
          if (_isLoading)
            AppLoader(message: _loaderMessage),
        ],
      ),
    );
  }
}
