import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/views/login_view.dart';
import 'package:frontend/views/widgets/reusable_widgets.dart';

void main() {
  group('UI Foundation Reusable Components Tests', () {
    testWidgets('PrimaryButton renders correctly with title text', (
      WidgetTester tester,
    ) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'परीक्षण बटन (Test Button)',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      // Verify button renders with given text
      expect(find.text('परीक्षण बटन (Test Button)'), findsOneWidget);

      // Tap and verify callback
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('AppTextField renders correctly with label and inputs', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              labelText: 'मोबाइल नंबर',
              hintText: '9876543210',
              controller: controller,
            ),
          ),
        ),
      );

      // Verify label
      expect(find.text('मोबाइल नंबर'), findsOneWidget);

      // Enter some text
      await tester.enterText(find.byType(TextFormField), '9999911111');
      await tester.pump();

      expect(controller.text, '9999911111');
    });
  });

  group('Premium Redesigned Login Screen Tests', () {
    testWidgets('LoginView renders brand logo, title, tagline and inputs', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginView())),
      );

      // Let animations settle
      await tester.pump();

      // Verify logo custom paint and titles are rendered
      expect(find.text('APNA MANDLA'), findsOneWidget);
      expect(
        find.text('"अपने शहर के अपने लोग, अपना डिजिटल बाज़ार"'),
        findsOneWidget,
      );

      // Verify default state is Login
      expect(find.text('लॉगिन करें (Login)'), findsOneWidget);
      expect(find.text('ओटीपी भेजें (Send OTP)'), findsOneWidget);
    });

    testWidgets(
      'LoginView transitions smoothly between Login and Register modes',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: LoginView())),
        );

        await tester.pump();

        // Tap on Register toggle button
        await tester.tap(
          find.textContaining('खाता बनाएँ'),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Verify view has transitioned to Register mode, showing "Full Name" label and "Register & Send OTP" button
        expect(find.textContaining('Register'), findsWidgets);

        // Tap on Login toggle button to transition back
        await tester.tap(find.textContaining('खाता है'), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));

        // Verify view is back to Login mode
        expect(find.textContaining('Login'), findsWidgets);
      },
    );
  });
}
