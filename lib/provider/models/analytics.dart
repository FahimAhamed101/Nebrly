class Analytics {
  final int todayOrders;
  final int monthlyOrders;
  final double todayEarnings;
  final double monthlyEarnings;
  final bool isDemoData; // Add this flag to track if using demo data

  const Analytics({
    required this.todayOrders,
    required this.monthlyOrders,
    required this.todayEarnings,
    required this.monthlyEarnings,
    this.isDemoData = false,
  });

  factory Analytics.demo() {
    return const Analytics(
      todayOrders: 5,
      monthlyOrders: 82,
      todayEarnings: 223.0,
      monthlyEarnings: 2586.0,
      isDemoData: true,
    );
  }

  // Factory constructor for API response
  factory Analytics.fromApiResponse(Map<String, dynamic> data) {
    final todayData = data['today'] ?? {};
    final monthData = data['month'] ?? {};

    final todayOrders = (todayData['orders'] ?? 0).toInt();
    final monthlyOrders = (monthData['orders'] ?? 0).toInt();
    final todayEarnings = (todayData['earnings'] ?? 0).toDouble();
    final monthlyEarnings = (monthData['earnings'] ?? 0).toDouble();

    // Check if data is all zeros (likely no actual data yet)
    final hasNoData = todayOrders == 0 && monthlyOrders == 0 &&
        todayEarnings == 0 && monthlyEarnings == 0;

    return Analytics(
      todayOrders: todayOrders,
      monthlyOrders: monthlyOrders,
      todayEarnings: todayEarnings,
      monthlyEarnings: monthlyEarnings,
      isDemoData: hasNoData, // Mark as demo data if all zeros
    );
  }

  // Helper method to check if there's actual data
  bool get hasData => todayOrders > 0 || monthlyOrders > 0 ||
      todayEarnings > 0 || monthlyEarnings > 0;
}