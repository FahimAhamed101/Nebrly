// screens/service_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/service_request.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceRequest request;

  const ServiceDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(request.clientImage),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.serviceName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Avg. price: \$${request.pricePerHour.toInt()}/hr',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (request.isTeamService)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.people, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  'Team Service',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Service details
            _buildDetailSection(
              title: 'Service Information',
              children: [
                _buildDetailRow('Service Type', _getServiceTypeName(request.serviceType)),
                _buildDetailRow('Status', _getStatusText(request.status)),
                _buildDetailRow('Date', '${_formatDate(request.date)}'),
                _buildDetailRow('Time', request.time),
                if (request.problemNote != null)
                  _buildDetailRow('Problem Note', request.problemNote!),
              ],
            ),

            SizedBox(height: 24),

            // Client details
            _buildDetailSection(
              title: 'Client Information',
              children: [
                _buildDetailRow('Client Name', request.clientName),
                _buildDetailRow('Rating', '${request.clientRating} ⭐ (${request.clientReviewCount} reviews)'),
                _buildDetailRow('Address', request.address),
              ],
            ),

            if (request.isTeamService && request.teamMembers != null && request.teamMembers!.isNotEmpty)
              Column(
                children: [
                  SizedBox(height: 24),
                  _buildDetailSection(
                    title: 'Team Members',
                    children: request.teamMembers!.map((member) =>
                        _buildDetailRow('Member', member)
                    ).toList(),
                  ),
                ],
              ),

            if (request.bundleType != null)
              Column(
                children: [
                  SizedBox(height: 24),
                  _buildDetailSection(
                    title: 'Bundle Information',
                    children: [
                      _buildDetailRow('Bundle Type', request.bundleType!),
                    ],
                  ),
                ],
              ),

            SizedBox(height: 32),

            // Action buttons
            if (request.status == RequestStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle accept
                        Get.back();
                        // Call your accept method here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Accept Request'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Handle decline
                        Get.back();
                        // Call your decline method here
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.red),
                      ),
                      child: Text(
                        'Decline',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceTypeName(ServiceType type) {
    switch (type) {
      case ServiceType.applianceRepairs:
        return 'Appliance Repairs';
      case ServiceType.windowWashing:
        return 'Window Washing';
      case ServiceType.plumbing:
        return 'Plumbing';
      case ServiceType.electrical:
        return 'Electrical';
      case ServiceType.cleaning:
        return 'Cleaning';
    }
  }

  String _getStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.cancelled:
        return 'Cancelled';
      case RequestStatus.completed:
        return 'Completed';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}