import 'dart:math';
import 'package:palette/core/colour/lab_colour.dart';

/// CIEDE2000 colour difference calculation.
///
/// Implements the CIE 142-2001 standard for perceptually uniform
/// colour difference measurement.
///
/// Reference: Sharma, Wu, Dalal (2005) "The CIEDE2000 color-difference formula"
/// Using reference conditions: kL = kC = kH = 1.
double deltaE2000(LabColour lab1, LabColour lab2) {
  const kL = 1.0;
  const kC = 1.0;
  const kH = 1.0;

  final l1 = lab1.l;
  final a1 = lab1.a;
  final b1 = lab1.b;
  final l2 = lab2.l;
  final a2 = lab2.a;
  final b2 = lab2.b;

  // Step 1: Calculate C'ab, h'ab
  final cab1 = sqrt(a1 * a1 + b1 * b1);
  final cab2 = sqrt(a2 * a2 + b2 * b2);
  final cabMean = (cab1 + cab2) / 2.0;

  final cabMean7 = pow(cabMean, 7).toDouble();
  final g = 0.5 * (1 - sqrt(cabMean7 / (cabMean7 + pow(25, 7).toDouble())));

  final a1Prime = a1 * (1 + g);
  final a2Prime = a2 * (1 + g);

  final c1Prime = sqrt(a1Prime * a1Prime + b1 * b1);
  final c2Prime = sqrt(a2Prime * a2Prime + b2 * b2);

  double computeHPrime(double bVal, double aPrime) {
    if (bVal.abs() < 1e-10 && aPrime.abs() < 1e-10) return 0;
    final h = atan2(bVal, aPrime) * 180 / pi;
    return h < 0 ? h + 360 : h;
  }

  final h1Prime = computeHPrime(b1, a1Prime);
  final h2Prime = computeHPrime(b2, a2Prime);

  // Step 2: Calculate delta-L', delta-C'ab, delta-H'ab
  final deltaLPrime = l2 - l1;
  final deltaCPrime = c2Prime - c1Prime;

  double deltaHPrime;
  if (c1Prime * c2Prime < 1e-10) {
    deltaHPrime = 0;
  } else {
    var dhp = h2Prime - h1Prime;
    if (dhp > 180) {
      dhp -= 360;
    } else if (dhp < -180) {
      dhp += 360;
    }
    deltaHPrime = dhp;
  }

  final deltaHHPrime =
      2 * sqrt(c1Prime * c2Prime) * sin(deltaHPrime * pi / 360);

  // Step 3: Calculate CIEDE2000
  final lMean = (l1 + l2) / 2.0;
  final cMean = (c1Prime + c2Prime) / 2.0;

  double hMean;
  if (c1Prime * c2Prime < 1e-10) {
    hMean = h1Prime + h2Prime;
  } else if ((h1Prime - h2Prime).abs() <= 180) {
    hMean = (h1Prime + h2Prime) / 2.0;
  } else if (h1Prime + h2Prime < 360) {
    hMean = (h1Prime + h2Prime + 360) / 2.0;
  } else {
    hMean = (h1Prime + h2Prime - 360) / 2.0;
  }

  final t = 1 -
      0.17 * cos((hMean - 30) * pi / 180) +
      0.24 * cos(2 * hMean * pi / 180) +
      0.32 * cos((3 * hMean + 6) * pi / 180) -
      0.20 * cos((4 * hMean - 63) * pi / 180);

  final lMeanMinus50Sq = (lMean - 50) * (lMean - 50);
  final sl = 1 + 0.015 * lMeanMinus50Sq / sqrt(20 + lMeanMinus50Sq);

  final sc = 1 + 0.045 * cMean;
  final sh = 1 + 0.015 * cMean * t;

  final cMean7 = pow(cMean, 7).toDouble();
  final rc = 2 * sqrt(cMean7 / (cMean7 + pow(25, 7).toDouble()));
  final dTheta =
      30 * exp(-pow((hMean - 275) / 25, 2));
  final rt = -sin(2 * dTheta * pi / 180) * rc;

  final dlTerm = deltaLPrime / (kL * sl);
  final dcTerm = deltaCPrime / (kC * sc);
  final dhTerm = deltaHHPrime / (kH * sh);

  return sqrt(
    dlTerm * dlTerm +
        dcTerm * dcTerm +
        dhTerm * dhTerm +
        rt * dcTerm * dhTerm,
  );
}

/// Convert a delta-E value to a percentage match (0-100).
///
/// Uses an empirical sigmoid-like curve:
/// - dE = 0 -> 100%
/// - dE = 5 -> ~92% (cross-brand match threshold)
/// - dE = 25 -> ~50%
/// - dE >= 100 -> 0%
double deltaEToMatchPercentage(double deltaE) {
  if (deltaE <= 0) return 100;
  if (deltaE >= 100) return 0;
  return 100 * exp(-0.03 * deltaE * deltaE / 10);
}
