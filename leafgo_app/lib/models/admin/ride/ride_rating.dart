class RideRating {
  final double rating;
  final String? comment;

  const RideRating({required this.rating, this.comment});

  factory RideRating.fromJson(Map<String, dynamic> json) {
    return RideRating(
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String?,
    );
  }
}
