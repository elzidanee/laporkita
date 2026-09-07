import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'government_dashboard_screen.dart';
import 'operator_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class CommandCenterDashboard extends StatefulWidget {
  final UserRole? initialRole;

  const CommandCenterDashboard({super.key, this.initialRole});

  @override
  State<CommandCenterDashboard> createState() => _CommandCenterDashboardState();
}

class _CommandCenterDashboardState extends State<CommandCenterDashboard> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // 1. Guard: Check Authentication State
        if (authState is! AuthAuthenticated) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              title: const Text('Autentikasi Diperlukan'),
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.neutral900,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 72,
                      color: AppColors.statusDanger,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sesi Belum Terautentikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan masuk terlebih dahulu dengan akun petugas atau pemerintah untuk mengakses Command Center.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenPrimary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Masuk ke Akun Petugas'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 2. Guard: Check Role Authorization (RBAC)
        final user = authState.user;
        if (!user.role.isCommandCenter) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              title: const Text('Akses Dibatasi'),
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.neutral900,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.gpp_bad_rounded,
                      size: 72,
                      color: AppColors.statusDanger,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Akses Khusus Aparat & Pemerintah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Halaman Command Center hanya dapat diakses oleh Admin, Operator, atau Pembuat Kebijakan.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/citizen', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenPrimary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kembali ke Beranda Warga'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 3. Authorized Staff / Official
        final activeRole = _selectedRole ?? widget.initialRole ?? user.role;
        switch (activeRole) {
          case UserRole.operator:
            return const OperatorDashboardScreen();
          case UserRole.admin:
            return const AdminDashboardScreen();
          case UserRole.policyMaker:
          default:
            return const GovernmentDashboardScreen();
        }
      },
    );
  }
}
