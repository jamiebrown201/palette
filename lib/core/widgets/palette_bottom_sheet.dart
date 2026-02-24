import 'package:flutter/material.dart';

/// Helper for showing consistently styled bottom sheets.
abstract final class PaletteBottomSheet {
  /// Show a modal bottom sheet with the app's standard styling.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: builder(context),
      ),
    );
  }
}
