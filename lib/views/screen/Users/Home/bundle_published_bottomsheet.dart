import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:naibrly/services/api_service.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/Ios_effect/iosTapEffect.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class BundleShareInfo {
  final String shareToken;
  final String shareUrl;
  final String bundleTitle;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  BundleShareInfo({
    required this.shareToken,
    required this.shareUrl,
    required this.bundleTitle,
    this.createdAt,
    this.expiresAt,
  });

  factory BundleShareInfo.fromResponse(String token, Map<String, dynamic> payload) {
    final bundleData = payload['bundle'] as Map<String, dynamic>? ?? {};
    final rawLink = payload['shareUrl'] ?? payload['url'] ?? payload['link'];
    final shareUrl = _resolveShareUrl(token, rawLink);
    final createdAt = DateTime.tryParse(
      payload['createdAt']?.toString() ?? bundleData['createdAt']?.toString() ?? '',
    );
    final expiresAt = DateTime.tryParse(
      payload['expiresAt']?.toString() ?? bundleData['expiresAt']?.toString() ?? '',
    );
    final title = bundleData['title'] ??
        payload['title'] ??
        'Your Naibrly bundle';

    return BundleShareInfo(
      shareToken: token,
      shareUrl: shareUrl,
      bundleTitle: title,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  static String _resolveShareUrl(String token, Object? rawLink) {
    final link = rawLink?.toString().trim();
    if (link != null && link.isNotEmpty) {
      return link;
    }

    final apiBase = Uri.tryParse(MainApiService.baseUrl);
    if (apiBase == null) {
      return 'https://naibrly-backend-main.onrender.com/join-bundle/$token';
    }

    final segments = apiBase.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty && segments.last.toLowerCase() == 'api') {
      segments.removeLast();
    }

    final base = apiBase.replace(pathSegments: segments).toString();
    final normalizedBase = base.endsWith('/') ? base : '$base/';
    return '${normalizedBase}join-bundle/$token';
  }
}

class BundlePublishedBottomSheet extends StatefulWidget {
  final String shareToken;

  const BundlePublishedBottomSheet({super.key, required this.shareToken});

  @override
  State<BundlePublishedBottomSheet> createState() => _BundlePublishedBottomSheetState();
}

class _BundlePublishedBottomSheetState extends State<BundlePublishedBottomSheet> {
  late final MainApiService _apiService;
  late Future<BundleShareInfo> _shareInfoFuture;

  @override
  void initState() {
    super.initState();
    _apiService = Get.find<MainApiService>();
    _shareInfoFuture = _fetchShareInfo();
  }

  Future<BundleShareInfo> _fetchShareInfo() async {
    final response = await _apiService.get(
      'bundles/share/${widget.shareToken}',
      includeAuth: true,
    );

    if (response is Map<String, dynamic> && response['success'] == true) {
      final payload = response['data'] as Map<String, dynamic>? ?? {};
      return BundleShareInfo.fromResponse(widget.shareToken, payload);
    }

    final message = (response is Map<String, dynamic> && response['message'] != null)
        ? response['message'].toString()
        : 'Unable to load bundle share link';
    throw ApiException(message: message);
  }

  void _copyShareLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share link copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _shareViaText(String link, {String? bundleTitle}) {
    final title = (bundleTitle ?? '').trim();
    final message = title.isNotEmpty
        ? 'Join my Naibrly bundle "$title": $link'
        : 'Join my Naibrly bundle: $link';
    Share.share(message, subject: 'Naibrly Bundle Invite');
  }

  void _showQrModal(String shareUrl, {String? bundleTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText(
                  "Share with QR",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                const SizedBox(height: 8),
                const AppText(
                  "Others can scan this code to jump straight to the shared bundle.",
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textcolor,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: shareUrl,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                AppText(
                  shareUrl,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textcolor,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  label: "Copy Link",
                  onTap: () {
                    _copyShareLink(shareUrl);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  label: "Share via text/email",
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareViaText(shareUrl, bundleTitle: bundleTitle);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: IosTapEffect(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0E7A60),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareContent(BundleShareInfo info) {
    return Column(
      children: [
        const SizedBox(height: 8),
        AppText(
          info.bundleTitle,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  info.shareUrl,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => _copyShareLink(info.shareUrl),
                icon: const Icon(Icons.copy, color: AppColors.primary),
                tooltip: 'Copy link',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: "Share with text/email",
          onTap: () => _shareViaText(info.shareUrl, bundleTitle: info.bundleTitle),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: "Share with QR",
          onTap: () => _showQrModal(info.shareUrl, bundleTitle: info.bundleTitle),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Image.asset(
                'assets/images/tickMark.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            const AppText(
              "Your Bundle has been Published",
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const AppText(
              "Share your bundle with friends and neighbors.",
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textcolor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FutureBuilder<BundleShareInfo>(
              future: _shareInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Column(
                    children: [
                      AppText(
                        snapshot.error.toString(),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.red.shade700,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        label: "Retry",
                        onTap: () {
                          setState(() {
                            _shareInfoFuture = _fetchShareInfo();
                          });
                        },
                      ),
                    ],
                  );
                }

                final info = snapshot.data!;
                return _buildShareContent(info);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
