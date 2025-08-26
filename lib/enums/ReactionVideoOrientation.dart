enum ReactionVideoOrientation {
  portrait(label: 'Portrait', value: 1),
  landscape(label: 'Landscape', value: 2);

  final String label;

  final int value;
  const ReactionVideoOrientation({required this.label, required this.value});

  // Check if is landscape
  bool get isLandscape => this == ReactionVideoOrientation.landscape;

  // Check if is portrait
  bool get isPortrait => this == ReactionVideoOrientation.portrait;

  // Get orientation from dimensions
  static ReactionVideoOrientation fromDimensions(int width, int height) {
    return width > height
        ? ReactionVideoOrientation.landscape
        : ReactionVideoOrientation.portrait;
  }

  // Get orientation from boolean
  static ReactionVideoOrientation fromIsLandscape(bool isLandscape) {
    return isLandscape
        ? ReactionVideoOrientation.landscape
        : ReactionVideoOrientation.portrait;
  }

  // Get orientation from value
  static ReactionVideoOrientation fromValue(int value) {
    return ReactionVideoOrientation.values.firstWhere(
      (orientation) => orientation.value == value,
      orElse: () => ReactionVideoOrientation.portrait,
    );
  }
}
