import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
