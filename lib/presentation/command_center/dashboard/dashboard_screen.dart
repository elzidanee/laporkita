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
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.policyMaker;
    _detectUserRole();
  }

  void _detectUserRole() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      if (widget.initialRole == null) {
        setState(() {
          _selectedRole = authState.user.role;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRole == UserRole.citizen) {
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

    // Render Dashboard terpisah yang 100% independen sesuai Role
    switch (_selectedRole) {
      case UserRole.operator:
        return const OperatorDashboardScreen();
      case UserRole.admin:
        return const AdminDashboardScreen();
      case UserRole.policyMaker:
      default:
        return const GovernmentDashboardScreen();
    }
  }
}
