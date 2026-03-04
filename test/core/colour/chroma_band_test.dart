import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/chroma_band.dart';
import 'package:palette/core/constants/enums.dart';

void main() {
  group('classifyChromaBand', () {
    test('values below 25 are muted', () {
      expect(classifyChromaBand(0), ChromaBand.muted);
      expect(classifyChromaBand(10), ChromaBand.muted);
      expect(classifyChromaBand(24.9), ChromaBand.muted);
    });

    test('boundary at 25 is mid', () {
      expect(classifyChromaBand(25.0), ChromaBand.mid);
    });

    test('values 25-50 are mid', () {
      expect(classifyChromaBand(30), ChromaBand.mid);
      expect(classifyChromaBand(40), ChromaBand.mid);
      expect(classifyChromaBand(50.0), ChromaBand.mid);
    });

    test('values above 50 are bold', () {
      expect(classifyChromaBand(50.1), ChromaBand.bold);
      expect(classifyChromaBand(75), ChromaBand.bold);
      expect(classifyChromaBand(100), ChromaBand.bold);
    });
  });
}
