/// An item on the user's shopping list.
///
/// Items are added from product recommendations and grouped by room/retailer.
class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.productId,
    required this.roomId,
    required this.roomName,
    required this.productName,
    required this.brand,
    required this.retailer,
    required this.priceGbp,
    required this.affiliateUrl,
    required this.primaryColourHex,
    required this.categoryName,
    required this.addedAt,
  });

  final String id;
  final String productId;
  final String roomId;
  final String roomName;
  final String productName;
  final String brand;
  final String retailer;
  final double priceGbp;
  final String affiliateUrl;
  final String primaryColourHex;
  final String categoryName;
  final DateTime addedAt;
}
