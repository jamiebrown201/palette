import 'package:flutter_test/flutter_test.dart';
import 'package:palette/data/services/seed_data_service.dart';

void main() {
  group('RetailerConfig.buildUrl', () {
    test('uses product URL template when available', () {
      const config = RetailerConfig(
        homepageUrl: 'https://example.com',
        productUrlTemplate: 'https://example.com/paint/{code}',
        searchUrlTemplate: 'https://example.com/search?q={name}',
      );

      final url = config.buildUrl(
        colourCode: 'FB-001',
        colourName: 'Hague Blue',
      );

      expect(url, 'https://example.com/paint/FB-001');
    });

    test('falls back to search URL when no product template', () {
      const config = RetailerConfig(
        homepageUrl: 'https://example.com',
        searchUrlTemplate: 'https://example.com/search?q={name}',
      );

      final url = config.buildUrl(
        colourCode: 'FB-001',
        colourName: 'Hague Blue',
      );

      expect(url, 'https://example.com/search?q=Hague%20Blue');
    });

    test('falls back to homepage when no templates', () {
      const config = RetailerConfig(
        homepageUrl: 'https://example.com',
      );

      final url = config.buildUrl(
        colourCode: 'FB-001',
        colourName: 'Hague Blue',
      );

      expect(url, 'https://example.com');
    });

    test('applies affiliate prefix to product URL', () {
      const config = RetailerConfig(
        homepageUrl: 'https://example.com',
        productUrlTemplate: 'https://example.com/paint/{code}',
        affiliatePrefix: 'ref=palette',
      );

      final url = config.buildUrl(
        colourCode: 'FB-001',
        colourName: 'Hague Blue',
      );

      expect(url, 'https://example.com/paint/FB-001?ref=palette');
    });

    test('uses & separator when URL already has query params', () {
      const config = RetailerConfig(
        homepageUrl: 'https://example.com',
        searchUrlTemplate: 'https://example.com/search?q={name}',
        affiliatePrefix: 'ref=palette',
      );

      final url = config.buildUrl(
        colourCode: 'FB-001',
        colourName: 'Hague Blue',
      );

      expect(
        url,
        'https://example.com/search?q=Hague%20Blue&ref=palette',
      );
    });

    test('URL-encodes colour names with special characters', () {
      const config = RetailerConfig(
        homepageUrl: 'https://example.com',
        searchUrlTemplate: 'https://example.com/search?q={name}',
      );

      final url = config.buildUrl(
        colourCode: 'FB-002',
        colourName: "Elephant's Breath",
      );

      expect(
        url,
        "https://example.com/search?q=Elephant's%20Breath",
      );
    });
  });
}
