import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laporkita/presentation/citizen/home/splash_screen.dart';
import 'package:laporkita/presentation/auth/bloc/auth_bloc.dart';
import 'package:laporkita/data/repositories/auth_repository.dart';

void main() {
  group('SplashScreen Motion & Layout Tests', () {
    late AuthRepository authRepository;
    late AuthBloc authBloc;

    setUp(() {
      authRepository = AuthRepository();
      authBloc = AuthBloc(authRepository: authRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('Renders initial logo and tagline smoothly without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const SplashScreen(),
          ),
        ),
      );

      // Frame 0: Logo LK is visible
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2)); // logoLK + LaporKita text

      // Advance animation partially (Phase 1 -> Phase 2 transition)
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);

      // Advance through text expand & reveal
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);

      // Advance to full animation completion
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);
      expect(find.text('Suaramu untuk kota yang lebih baik.'), findsOneWidget);
    });
  });
}
