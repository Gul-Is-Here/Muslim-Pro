import 'package:flutter_test/flutter_test.dart';
import 'package:quran_pro/core/utils/compass_math.dart';

void main() {
  test('turn takes the shortest way round, positive = right', () {
    expect(CompassMath.turn(0, 90), 90);
    expect(CompassMath.turn(90, 0), -90);
    expect(CompassMath.turn(350, 10), 20); // across north, right
    expect(CompassMath.turn(10, 350), -20); // across north, left
    expect(CompassMath.turn(0, 180), 180);
    expect(CompassMath.turn(273, 267), closeTo(-6, 1e-9));
  });

  test('smoothing never swings the long way across north', () {
    final s = CompassMath.smooth(355, 5, alpha: 0.5);
    expect(s, closeTo(0, 1e-9)); // halfway along the 10° arc, not 180°
    expect(CompassMath.smooth(null, 370), closeTo(10, 1e-9));
  });

  test('16-point compass labels', () {
    expect(CompassMath.cardinal(0), 'N');
    expect(CompassMath.cardinal(359), 'N');
    expect(CompassMath.cardinal(119), 'ESE');
    expect(CompassMath.cardinal(267), 'W');
    expect(CompassMath.cardinal(-90), 'W');
  });
}
