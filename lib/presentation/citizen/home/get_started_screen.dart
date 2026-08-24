import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenPrimary,
      body: Stack(
        children: [
          // 1. Vector Map Background Illustration
          Positioned.fill(
            child: CustomPaint(
              painter: MapBackgroundPainter(),
            ),
          ),

          // 2. Main Content Column
          Column(
            children: [
              // Top Section: Title & Subtitle
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Selamat Datang\ndi LaporkanKita!',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mari bersama menjaga fasilitas umum agar kota menjadi tempat yang lebih baik untuk semua.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.95),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Section: White Curved Container with Figma Node 1:4 CTA Buttons
              Expanded(
                flex: 5,
                child: ClipPath(
                  clipper: TopCurveClipper(),
                  child: Container(
                    color: AppColors.white,
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      36,
                      48,
                      36,
                      28 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),

                        // Button 1: "Get Started" (Figma Node 399:3)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.greenDark,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(65),
                            side: const BorderSide(color: AppColors.greenLight, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Button 2: "Login" (Figma Node 399:15)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.greenPrimary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(65),
                            side: const BorderSide(color: AppColors.greenLight, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom Clipper for creating the smooth curved top of the white bottom sheet container
class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start at top left with downward curve
    path.moveTo(0, 45);
    // Quadratic Bezier curve reaching peak control point in center
    path.quadraticBezierTo(
      size.width / 2, -15, 
      size.width, 45,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Custom Painter drawing stylized vector map roads, polygons, and location pins
class MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final darkRoadPaint = Paint()
      ..color = AppColors.greenDark.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final blockFillPaint = Paint()
      ..color = AppColors.greenDark.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final pinPaint = Paint()
      ..color = AppColors.greenDark.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    // 1. Draw Map Polygon Blocks (e.g. river/park area top-right)
    final topPoly = Path()
      ..moveTo(width * 0.5, 0)
      ..lineTo(width * 0.7, height * 0.05)
      ..lineTo(width * 0.65, height * 0.12)
      ..lineTo(width * 0.85, height * 0.17)
      ..lineTo(width, height * 0.1)
      ..lineTo(width, 0)
      ..close();
    canvas.drawPath(topPoly, blockFillPaint);

    final leftPoly = Path()
      ..moveTo(0, height * 0.32)
      ..lineTo(width * 0.28, height * 0.28)
      ..lineTo(width * 0.22, height * 0.4)
      ..lineTo(0, height * 0.42)
      ..close();
    canvas.drawPath(leftPoly, blockFillPaint);

    // 2. Draw Vector Roads (Grid & Curves matching reference)
    // Main vertical road 1 (Left)
    canvas.drawLine(Offset(width * 0.15, 0), Offset(width * 0.15, height * 0.25), darkRoadPaint);
    canvas.drawLine(Offset(width * 0.15, height * 0.25), Offset(width * 0.3, height * 0.25), darkRoadPaint);

    // Main vertical avenue (Right center)
    final mainRoad = Path()
      ..moveTo(width * 0.88, 0)
      ..lineTo(width * 0.88, height * 0.15)
      ..lineTo(width * 0.75, height * 0.32)
      ..lineTo(width * 0.75, height * 0.6);
    canvas.drawPath(mainRoad, darkRoadPaint);

    // Horizontal roads
    canvas.drawLine(Offset(0, height * 0.15), Offset(width * 0.32, height * 0.15), darkRoadPaint);
    canvas.drawLine(Offset(width * 0.5, height * 0.18), Offset(width * 0.88, height * 0.18), darkRoadPaint);
    canvas.drawLine(Offset(width * 0.48, height * 0.24), Offset(width * 0.75, height * 0.24), darkRoadPaint);

    // Connecting grid curves
    final gridPath = Path()
      ..moveTo(0, height * 0.22)
      ..quadraticBezierTo(width * 0.1, height * 0.22, width * 0.15, height * 0.25)
      ..lineTo(width * 0.15, height * 0.45);
    canvas.drawPath(gridPath, darkRoadPaint);

    final sideGrid = Path()
      ..moveTo(width * 0.58, height * 0.24)
      ..lineTo(width * 0.58, height * 0.45)
      ..lineTo(width * 0.75, height * 0.45);
    canvas.drawPath(sideGrid, darkRoadPaint);

    canvas.drawLine(Offset(width * 0.75, height * 0.38), Offset(width * 0.95, height * 0.38), darkRoadPaint);

    // 3. Draw Stylized Map Pin Icons at specific points
    _drawMapPin(canvas, Offset(width * 0.12, height * 0.12), pinPaint);
    _drawMapPin(canvas, Offset(width * 0.52, height * 0.17), pinPaint);
    _drawMapPin(canvas, Offset(width * 0.82, height * 0.11), pinPaint);
    _drawMapPin(canvas, Offset(width * 0.78, height * 0.36), pinPaint);
  }

  void _drawMapPin(Canvas canvas, Offset center, Paint paint) {
    final radius = 6.0;
    canvas.drawCircle(center, radius, paint);
    final pinTail = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..lineTo(center.dx, center.dy + radius * 1.8)
      ..lineTo(center.dx + radius, center.dy)
      ..close();
    canvas.drawPath(pinTail, paint);
    // Hole in pin
    final holePaint = Paint()..color = AppColors.greenPrimary;
    canvas.drawCircle(center, radius * 0.4, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
