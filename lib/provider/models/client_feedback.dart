class ClientFeedback {
  final String id;
  final String clientName;
  final String clientImage;
  final double rating;
  final String comment;
  final DateTime date;
  final String serviceName;
  bool isExpanded;

  ClientFeedback({
    required this.id,
    required this.clientName,
    required this.clientImage,
    required this.rating,
    required this.comment,
    required this.date,
    required this.serviceName,
    this.isExpanded = false,
  });

  factory ClientFeedback.fromJson(Map<String, dynamic> json) {
    return ClientFeedback(
      id: json['id'] ?? '',
      clientName: '${json['customer']['firstName'] ?? ''} ${json['customer']['lastName'] ?? ''}'.trim(),
      clientImage: json['customer']['profileImage']['url'] ?? '',
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] ?? '',
      date: DateTime.parse(json['createdAt']),
      serviceName: json['serviceName'] ?? '',
    );
  }
}

class ReviewsResponse {
  final List<ClientFeedback> reviews;
  final int currentPage;
  final int totalPages;
  final int totalReviews;
  final double averageRating;

  ReviewsResponse({
    required this.reviews,
    required this.currentPage,
    required this.totalPages,
    required this.totalReviews,
    required this.averageRating,
  });

  factory ReviewsResponse.fromJson(Map<String, dynamic> json) {
    final reviewsData = json['reviews'] as Map<String, dynamic>;
    final list = reviewsData['list'] as List;

    return ReviewsResponse(
      reviews: list.map((item) => ClientFeedback.fromJson(item)).toList(),
      currentPage: reviewsData['pagination']['current'] ?? 1,
      totalPages: reviewsData['pagination']['pages'] ?? 1,
      totalReviews: reviewsData['statistics']['totalReviews'] ?? 0,
      averageRating: (reviewsData['statistics']['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}