import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/models/shopping_list_item.dart';
import 'package:palette/providers/database_providers.dart';

/// Stream of all shopping list items, auto-updates on changes.
final shoppingListProvider = StreamProvider<List<ShoppingListItem>>((ref) {
  return ref.watch(shoppingListRepositoryProvider).watchAll();
});

/// Whether a specific product is already in the list for a given room.
final isInShoppingListProvider =
    FutureProvider.family<bool, ({String productId, String roomId})>((
      ref,
      params,
    ) {
      return ref
          .watch(shoppingListRepositoryProvider)
          .isInList(params.productId, params.roomId);
    });
