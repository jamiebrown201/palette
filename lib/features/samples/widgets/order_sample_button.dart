import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/features/samples/providers/sample_list_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:uuid/uuid.dart';

/// Reusable "Order Sample" button that adds a paint colour to the sample list.
class OrderSampleButton extends ConsumerWidget {
  const OrderSampleButton({
    required this.paintColourId,
    required this.colourName,
    required this.colourCode,
    required this.brand,
    required this.hex,
    this.roomId,
    this.roomName,
    super.key,
  });

  final String paintColourId;
  final String colourName;
  final String colourCode;
  final String brand;
  final String hex;
  final String? roomId;
  final String? roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInList = ref.watch(isInSampleListProvider(paintColourId));

    return isInList.when(
      loading:
          () => OutlinedButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            label: const Text('Sample'),
            style: _buttonStyle(context),
          ),
      error:
          (_, __) => OutlinedButton.icon(
            onPressed: () => _addSample(context, ref),
            icon: const Icon(Icons.color_lens_outlined, size: 16),
            label: const Text('Sample'),
            style: _buttonStyle(context),
          ),
      data:
          (inList) =>
              inList
                  ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Added'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PaletteColours.sageGreenDark,
                      side: const BorderSide(color: PaletteColours.sageGreen),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      textStyle: Theme.of(context).textTheme.labelMedium,
                    ),
                  )
                  : OutlinedButton.icon(
                    onPressed: () => _addSample(context, ref),
                    icon: const Icon(Icons.color_lens_outlined, size: 16),
                    label: const Text('Sample'),
                    style: _buttonStyle(context),
                  ),
    );
  }

  ButtonStyle _buttonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: PaletteColours.softGoldDark,
      side: const BorderSide(color: PaletteColours.softGold),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      textStyle: Theme.of(context).textTheme.labelMedium,
    );
  }

  Future<void> _addSample(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(sampleListRepositoryProvider);
    await repo.addSample(
      SampleListItemsCompanion(
        id: Value(const Uuid().v4()),
        paintColourId: Value(paintColourId),
        colourName: Value(colourName),
        colourCode: Value(colourCode),
        brand: Value(brand),
        hex: Value(hex),
        roomId: Value(roomId),
        roomName: Value(roomName),
        addedAt: Value(DateTime.now()),
      ),
    );

    ref.invalidate(isInSampleListProvider(paintColourId));

    ref.read(analyticsProvider).track(AnalyticsEvents.sampleAdded, {
      'brand': brand,
      'colour': colourName,
      'room_id': roomId,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$colourName added to sample list'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View list',
            onPressed: () {
              context.push('/samples');
            },
          ),
        ),
      );
    }
  }
}
