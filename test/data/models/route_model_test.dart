import 'package:flutter_test/flutter_test.dart';
import 'package:laporkita/data/models/route_model.dart';

void main() {
  group('RouteModel OSRM Parsing', () {
    test('berhasil mem-parsing JSON OSRM GeoJSON dengan koordinat yang dibalik ke LatLng(lat, lon)', () {
      final sampleJson = {
        "code": "Ok",
        "routes": [
          {
            "geometry": {
              "coordinates": [
                [112.6304, -7.9827],
                [112.6310, -7.9820],
                [112.6412, -7.9701]
              ],
              "type": "LineString"
            },
            "distance": 1520.4,
            "duration": 245.8,
            "legs": []
          }
        ],
        "waypoints": []
      };

      final route = RouteModel.fromOsrmJson(sampleJson);

      expect(route.points.length, 3);
      // Titik pertama: [112.6304, -7.9827] -> LatLng(lat: -7.9827, lon: 112.6304)
      expect(route.points[0].latitude, -7.9827);
      expect(route.points[0].longitude, 112.6304);

      // Titik terakhir: [112.6412, -7.9701] -> LatLng(lat: -7.9701, lon: 112.6412)
      expect(route.points[2].latitude, -7.9701);
      expect(route.points[2].longitude, 112.6412);

      // Jarak dan estimasi waktu
      expect(route.distanceMeters, 1520.4);
      expect(route.durationSeconds, 245.8);
      expect(route.distanceKm, '1.5 km');
      expect(route.durationMinutes, '4 menit');
    });

    test('melempar RouteNotFoundException jika code bukan "Ok"', () {
      final errorJson = {
        "code": "NoRoute",
        "message": "Impossible route between points"
      };

      expect(
        () => RouteModel.fromOsrmJson(errorJson),
        throwsA(
          isA<RouteNotFoundException>().having(
            (e) => e.message,
            'message',
            contains('Impossible route'),
          ),
        ),
      );
    });

    test('melempar RouteNotFoundException jika routes kosong', () {
      final emptyJson = {
        "code": "Ok",
        "routes": [],
      };

      expect(
        () => RouteModel.fromOsrmJson(emptyJson),
        throwsA(isA<RouteNotFoundException>()),
      );
    });

    test('format durasi kurang dari 1 menit menghasilkan "< 1 menit"', () {
      const route = RouteModel(
        points: [],
        distanceMeters: 50.0,
        durationSeconds: 25.0,
      );

      expect(route.durationMinutes, '< 1 menit');
      expect(route.distanceKm, '0.1 km');
    });

    test('berhasil mem-parsing steps instruksi manuver jalan dan multi-routes', () {
      final sampleMultiJson = {
        "code": "Ok",
        "routes": [
          {
            "geometry": {
              "coordinates": [
                [112.6304, -7.9827],
                [112.6412, -7.9701]
              ],
              "type": "LineString"
            },
            "distance": 3450.2,
            "duration": 236.7,
            "summary": "Jalan Pasar Besar, Jalan Panglima Sudirman",
            "legs": [
              {
                "steps": [
                  {
                    "distance": 150.0,
                    "duration": 25.0,
                    "name": "Jl. Ahmad Habibi",
                    "maneuver": {"type": "turn", "modifier": "left"}
                  },
                  {
                    "distance": 1200.0,
                    "duration": 180.0,
                    "name": "Jl. Soekarno Hatta",
                    "maneuver": {"type": "new name", "modifier": "straight"}
                  }
                ]
              }
            ]
          },
          {
            "geometry": {
              "coordinates": [
                [112.6304, -7.9827],
                [112.6350, -7.9750],
                [112.6412, -7.9701]
              ],
              "type": "LineString"
            },
            "distance": 4100.0,
            "duration": 310.0,
            "summary": "Jalan Hamid Rusdi",
            "legs": []
          }
        ]
      };

      final routes = RouteModel.fromOsrmJsonList(sampleMultiJson);

      expect(routes.length, 2);
      expect(routes[0].distanceKm, '3.5 km');
      expect(routes[0].steps.length, 2);
      expect(routes[0].steps[0].name, 'Jl. Ahmad Habibi');
      expect(routes[0].steps[0].instructionText, 'Belok kiri ke Jl. Ahmad Habibi');
      expect(routes[1].distanceKm, '4.1 km');
    });
  });
}
