enum ReactionVideoSegment {
  sourceVideo(label: 'Source Video', value: 1),
  reactionVideo(label: 'Reaction Video', value: 2),
  combinedVideo(label: 'Combined Video', value: 3);

  // Get all available segments as a list (useful for dropdowns)
  static List<ReactionVideoSegment> get allSegments =>
      ReactionVideoSegment.values;

  // Get segments for display (useful for UI lists)
  static List<Map<String, dynamic>> get asMap =>
      ReactionVideoSegment.values
          .map((segment) => {'label': segment.label, 'value': segment.value})
          .toList();
  final String label;

  final int value;

  const ReactionVideoSegment({required this.label, required this.value});

  // Check if is combined video
  bool get isCombinedVideo => this == ReactionVideoSegment.combinedVideo;

  // Check if is reaction video
  bool get isReactionVideo => this == ReactionVideoSegment.reactionVideo;

  // Check if is source video
  bool get isSourceVideo => this == ReactionVideoSegment.sourceVideo;

  // Get segment from value
  static ReactionVideoSegment fromValue(int value) {
    return ReactionVideoSegment.values.firstWhere(
      (segment) => segment.value == value,
      orElse: () => ReactionVideoSegment.sourceVideo,
    );
  }
}
