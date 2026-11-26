import 'package:djajan_mobile/services/map_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OSRM route geometry becomes road-following map points', () {
    final route = MapNavigationService.parseDrivingRoute({
      'code': 'Ok',
      'routes': [
        {
          'distance': 2350.5,
          'geometry': {
            'coordinates': [
              [113.7, -8.1],
              [113.71, -8.11],
              [113.72, -8.12],
            ],
          },
        },
      ],
    });

    expect(route.points, hasLength(3));
    expect(route.points.first.latitude, -8.1);
    expect(route.points.first.longitude, 113.7);
    expect(route.distanceKm, 2.3505);
  });

  test('invalid and unavailable routes are rejected', () {
    expect(
      () => MapNavigationService.parseDrivingRoute({'code': 'NoRoute'}),
      throwsFormatException,
    );
    expect(
      () => MapNavigationService.parseDrivingRoute({
        'code': 'Ok',
        'routes': [
          {'distance': 100, 'geometry': {'coordinates': [[1, 2]]}},
        ],
      }),
      throwsFormatException,
    );
  });
}
