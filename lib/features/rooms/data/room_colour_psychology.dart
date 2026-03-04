/// Room-specific colour psychology guidance.
///
/// Each room type has an insight about what colours work well
/// and what to avoid, grounded in colour psychology research.
class RoomGuidance {
  const RoomGuidance({
    required this.insight,
    required this.avoid,
  });

  /// Positive guidance — what colours/approaches work well.
  final String insight;

  /// What to avoid in this room type.
  final String avoid;
}

/// Colour psychology guidance keyed by room type keywords.
const Map<String, RoomGuidance> roomColourGuidance = {
  'bedroom': RoomGuidance(
    insight:
        'Calming, muted tones promote restful sleep. Warm neutrals and soft '
        'blues are popular choices for bedrooms.',
    avoid: 'Highly saturated brights or energising reds near the bed — '
        'they can interfere with relaxation.',
  ),
  'kitchen': RoomGuidance(
    insight:
        'Warm whites and earthy tones create an inviting space for cooking '
        'and gathering. Appetite-friendly colours like warm neutrals work well.',
    avoid: 'Cool greys or blues can feel clinical in a kitchen — '
        'balance them with warm wood tones.',
  ),
  'living': RoomGuidance(
    insight:
        'Versatile neutrals let furnishings shine while setting a welcoming '
        'tone. Layer your 70/20/10 split to create visual interest.',
    avoid: 'Very dark walls in a small living room can feel oppressive — '
        'save bold darks for accent walls or larger spaces.',
  ),
  'office': RoomGuidance(
    insight:
        'Soft greens and blue-greens boost focus and reduce eye strain. '
        'A muted background helps you concentrate.',
    avoid: 'Overly warm or bright colours can be distracting during '
        'focused work — keep the dominant colour calm.',
  ),
  'dining': RoomGuidance(
    insight:
        'Warm, deeper tones create an intimate atmosphere for meals. '
        'Earth tones and jewel tones both work well for dining spaces.',
    avoid: 'Very cool or sterile colours can make a dining room feel '
        'unwelcoming — add warmth through your colour plan.',
  ),
  'bathroom': RoomGuidance(
    insight:
        'Light, fresh tones make bathrooms feel clean and spacious. '
        'Soft aquas, whites, and pale greens are classic choices.',
    avoid: 'Very dark colours in a small windowless bathroom can feel '
        'claustrophobic — use darks as accents instead.',
  ),
  'hallway': RoomGuidance(
    insight:
        'Your hallway sets the tone for the whole home. Lighter neutrals '
        'create flow between rooms and make the space feel open.',
    avoid: 'Busy patterns or too many accent colours in a narrow '
        'hallway can feel overwhelming — keep it simple.',
  ),
  'nursery': RoomGuidance(
    insight:
        'Soft pastels and muted tones create a soothing environment. '
        'Gentle greens and warm neutrals are calming for little ones.',
    avoid: 'Highly stimulating brights or bold contrasts — '
        'they can overstimulate rather than soothe.',
  ),
};

/// Find colour psychology guidance for a room by matching keywords
/// in the room name.
RoomGuidance? getGuidanceForRoom(String roomName) {
  final lower = roomName.toLowerCase();
  for (final entry in roomColourGuidance.entries) {
    if (lower.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}
