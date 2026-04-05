import 'package:flutter_test/flutter_test.dart';
import 'package:palette/data/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('redirect URL matches AndroidManifest scheme and host', () {
      // This must match:
      // 1. android/app/src/main/AndroidManifest.xml intent filter
      // 2. Supabase Dashboard > Auth > URL Configuration > Redirect URLs
      expect(AuthService.redirectUrl, 'com.paletteapp.palette://login-callback');
    });

    test('redirect URL uses app package name as scheme', () {
      expect(
        AuthService.redirectUrl,
        startsWith('com.paletteapp.palette://'),
      );
    });
  });
}
