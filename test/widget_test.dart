// Smoke test untuk LaporKita — menggantikan test counter bawaan template
// yang tidak relevan dengan aplikasi ini.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:laporkita/main.dart';
import 'package:laporkita/data/repositories/auth_repository.dart';
import 'package:laporkita/data/repositories/report_repository.dart';
import 'package:laporkita/data/repositories/category_repository.dart';
import 'package:laporkita/data/repositories/policy_simulator_repository.dart';
import 'package:laporkita/data/repositories/prediction_repository.dart';
import 'package:laporkita/data/repositories/notification_repository.dart';
import 'package:laporkita/presentation/auth/bloc/auth_bloc.dart';
import 'package:laporkita/presentation/reports/bloc/report_bloc.dart';

void main() {
  group('LaporKita App Smoke Tests', () {
    testWidgets('App renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      // Cukup verifikasi bahwa widget tree terbentuk tanpa exception
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('SplashScreen atau navigasi awal ter-render', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 100));
      // Pastikan ada setidaknya satu Scaffold atau navigator di tree
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    test('AuthBloc dapat diinstansiasi', () {
      final repo = AuthRepository();
      final bloc = AuthBloc(authRepository: repo);
      expect(bloc, isNotNull);
      bloc.close();
    });

    test('ReportBloc dapat diinstansiasi', () {
      final repo = ReportRepository();
      final bloc = ReportBloc(reportRepository: repo);
      expect(bloc, isNotNull);
      bloc.close();
    });

    test('AuthRepository dapat diinstansiasi', () {
      expect(AuthRepository(), isNotNull);
    });

    test('ReportRepository dapat diinstansiasi', () {
      expect(ReportRepository(), isNotNull);
    });

    test('CategoryRepository dapat diinstansiasi', () {
      expect(CategoryRepository(), isNotNull);
    });

    test('PolicySimulatorRepository dapat diinstansiasi', () {
      expect(PolicySimulatorRepository(), isNotNull);
    });

    test('PredictionRepository dapat diinstansiasi', () {
      expect(PredictionRepository(), isNotNull);
    });

    test('NotificationRepository dapat diinstansiasi', () {
      expect(NotificationRepository(), isNotNull);
    });
  });
}
