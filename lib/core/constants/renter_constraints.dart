/// Home-level renter constraints captured during onboarding.
///
/// These describe what a renter can and can't change in their home,
/// and drive the [RoomModeConfig] strategy pattern.
class RenterConstraints {
  const RenterConstraints({
    required this.isRenter,
    this.canPaint,
    this.canDrill,
    this.keepingFlooring,
    this.isTemporaryHome,
    this.reversibleOnly,
  });

  final bool isRenter;
  final bool? canPaint;
  final bool? canDrill;
  final bool? keepingFlooring;
  final bool? isTemporaryHome;
  final bool? reversibleOnly;

  /// Walls can't be changed — entire design canvas shifts to textiles.
  bool get wallsAreLocked => isRenter && canPaint == false;

  /// Default for owners or users who haven't answered constraint questions.
  static const none = RenterConstraints(isRenter: false);

  RenterConstraints copyWith({
    bool? isRenter,
    bool? canPaint,
    bool? canDrill,
    bool? keepingFlooring,
    bool? isTemporaryHome,
    bool? reversibleOnly,
  }) {
    return RenterConstraints(
      isRenter: isRenter ?? this.isRenter,
      canPaint: canPaint ?? this.canPaint,
      canDrill: canDrill ?? this.canDrill,
      keepingFlooring: keepingFlooring ?? this.keepingFlooring,
      isTemporaryHome: isTemporaryHome ?? this.isTemporaryHome,
      reversibleOnly: reversibleOnly ?? this.reversibleOnly,
    );
  }
}
