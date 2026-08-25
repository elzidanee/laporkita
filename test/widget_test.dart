// Smoke test & Business Logic Unit Tests untuk LaporKita

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:laporkita/main.dart';
import 'package:laporkita/data/models/report_model.dart';
import 'package:laporkita/data/models/notification_model.dart';
import 'package:laporkita/data/models/category_model.dart';
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
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('SplashScreen atau navigasi awal ter-render', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    test('AuthBloc dapat diinstansiasi', () {
      final repo = AuthRepository();
      final bloc = AuthBloc(authRepository: repo);
      expect(bloc, isNotNull);
      expect(bloc.state, isA<AuthInitial>());
      bloc.close();
    });

    test('ReportBloc dapat diinstansiasi', () {
      final repo = ReportRepository();
      final bloc = ReportBloc(reportRepository: repo);
      expect(bloc, isNotNull);
      expect(bloc.state, isA<ReportInitial>());
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

  group('LaporKita Business Logic & Model Parsing Unit Tests', () {
    test('ReportModel.fromJson mengurai JSON backend dengan tepat', () {
      final json = {
        'id': 'rpt-123',
        'report_code': '#LP-2026-001',
        'reporter_id': 'usr-001',
        'category_id': 'cat-001',
        'status': 'in_progress',
        'latitude': -7.9827,
        'longitude': 112.6304,
        'address_text': 'Jl. Danau Ranau, Malang',
        'description': 'Jalan berlubang cukup dalam',
        'support_count': 15,
        'view_count': 120,
        'urgency_score': 88.5,
        'needs_manual_review': false,
        'created_at': '2026-08-25T11:46:00.000Z',
        'updated_at': '2026-08-25T11:46:00.000Z',
        'category': {'name': 'Jalan Berlubang'},
      };

      final model = ReportModel.fromJson(json);

      expect(model.id, equals('rpt-123'));
      expect(model.reportCode, equals('#LP-2026-001'));
      expect(model.status, equals(ReportStatus.inProgress));
      expect(model.status.displayName, equals('Sedang Diproses'));
      expect(model.latitude, equals(-7.9827));
      expect(model.categoryName, equals('Jalan Berlubang'));
    });

    test('NotificationModel.fromJson mengurai JSON notifikasi backend', () {
      final json = {
        'id': 'notif-001',
        'title': 'Perbaikan Selesai',
        'message': 'Laporan jalan berlubang telah selesai diperbaiki.',
        'is_read': false,
        'created_at': '2026-08-25T12:00:00.000Z',
        'type': 'status_change',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, equals('notif-001'));
      expect(model.title, equals('Perbaikan Selesai'));
      expect(model.isRead, isFalse);
      expect(model.type, equals('status_change'));
    });

    test('CategoryModel.fromJson mengurai JSON kategori dengan tepat', () {
      final json = {
        'id': 'cat-001',
        'name': 'Fasilitas Rusak',
        'description': 'Kerusakan fasilitas umum',
        'icon': 'build',
      };

      final model = CategoryModel.fromJson(json);

      expect(model.id, equals('cat-001'));
      expect(model.name, equals('Fasilitas Rusak'));
      expect(model.description, equals('Kerusakan fasilitas umum'));
    });

    test('ReportStatus.fromString mengonversi berbagai string status dengan benar', () {
      expect(ReportStatus.fromString('verified'), equals(ReportStatus.verified));
      expect(ReportStatus.fromString('in_progress'), equals(ReportStatus.inProgress));
      expect(ReportStatus.fromString('completed'), equals(ReportStatus.completed));
      expect(ReportStatus.fromString('invalid_status'), equals(ReportStatus.pendingVerification));
    });
  });
}
