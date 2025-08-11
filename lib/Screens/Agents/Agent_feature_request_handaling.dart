import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:bizmatic_solutions/Components/Fonts.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class AgentFeatureRequests extends StatefulWidget {
  final String agentId;
  final String agentName;

  const AgentFeatureRequests({
    super.key,
    required this.agentId,
    required this.agentName,
  });

  @override
  State<AgentFeatureRequests> createState() => _AgentFeatureRequestsState();
}

class _AgentFeatureRequestsState extends State<AgentFeatureRequests> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? _requestsStream;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (_isDisposed) return;

    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _requestsStream =
          _firestore
              .collection('featureRequests')
              .where('status', isEqualTo: 'pending')
              .snapshots();

      await _requestsStream!.first;

      if (_isDisposed) return;

      _safeSetState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading requests: $e');
      if (_isDisposed) return;

      _safeSetState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load requests. Please try again.';
      });
    }
  }

  Future<void> _processRequest({
    required DocumentSnapshot request,
    required bool isApproved,
  }) async {
    if (_isDisposed) return;

    final confirmed = await _showConfirmationDialog(
      request: request,
      isApproved: isApproved,
    );

    if (!confirmed || _isDisposed) return;

    _showProcessingDialog();

    try {
      await _updateRequestStatus(request: request, isApproved: isApproved);

      if (!_isDisposed && mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackbar(isApproved ? 'approved' : 'rejected');
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        Navigator.of(context).pop();
        _showErrorSnackbar(e.toString());
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required DocumentSnapshot request,
    required bool isApproved,
  }) async {
    final data = request.data() as Map<String, dynamic>;
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(isApproved ? 'Approve Request' : 'Reject Request'),
                content: Text(
                  '${isApproved ? 'Approve' : 'Reject'} feature "${data['feature']}" '
                  'for customer ${data['customerName']}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.Black),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isApproved ? AppColors.primary : Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      isApproved ? 'Approve' : 'Reject',
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLoadingDots(),
                const SizedBox(height: 16),
                const Text('Processing request...'),
              ],
            ),
          ),
    );
  }

  Future<void> _updateRequestStatus({
    required DocumentSnapshot request,
    required bool isApproved,
  }) async {
    final data = request.data() as Map<String, dynamic>;
    final batch = _firestore.batch();

    if (isApproved) {
      final customerFeatureRef = _firestore
          .collection('customers')
          .doc(data['customerId'])
          .collection('activeFeatures')
          .doc(data['product']);

      batch.set(customerFeatureRef, {
        'features': FieldValue.arrayUnion([data['feature']]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    batch.update(request.reference, {
      'status': isApproved ? 'approved' : 'rejected',
      'agentId': widget.agentId,
      'agentName': widget.agentName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await _sendStatusEmail(
      customerEmail: data['customerEmail'],
      customerName: data['customerName'],
      feature: data['feature'],
      product: data['product'],
      isApproved: isApproved,
    );
  }

  Future<void> _sendStatusEmail({
  required String customerEmail,
  required String customerName,
  required String feature,
  required String product,
  required bool isApproved,
}) async {
  final smtpServer = gmail('bizmaticshaban@gmail.com', 'jfhw kkvm azgz vrox');

  // Create the email content
  final status = isApproved ? 'Approved' : 'Rejected';
  final customerMessage = '''
Dear $customerName,

Your request for the "$feature" feature in $product has been 
${isApproved ? 'approved' : 'rejected'} by our support team.

${isApproved ? 'The feature has been activated for your account.' : 'Please contact support if you have any questions.'}

Thank you,
Support Team
''';

  final adminMessage = '''
Feature Request $status

Customer: $customerName
Email: $customerEmail
Product: $product
Feature: $feature
Status: $status
Processed by: ${widget.agentName} (${widget.agentId})
Time: ${DateTime.now()}
''';

  // Send to customer
  final customerEmailMessage = Message()
    ..from = Address('bizmaticshaban@gmail.com', 'Feature Request System')
    ..recipients.add(customerEmail)
    ..subject = 'Feature Request $status'
    ..text = customerMessage;

  // Send to admin (same email)
  final adminEmailMessage = Message()
    ..from = Address('bizmaticshaban@gmail.com', 'Feature Request System')
    ..recipients.add('bizmaticshaban@gmail.com')
    ..subject = 'Feature Request $status - $customerName'
    ..text = adminMessage;

  try {
    // Send both emails
    await Future.wait([
      send(customerEmailMessage, smtpServer),
      send(adminEmailMessage, smtpServer),
    ]);
  } catch (e) {
    debugPrint('Error sending email: $e');
    // You might want to show an error or log this failure
  }
}

  void _showSuccessSnackbar(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request $action successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showErrorSnackbar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
    );
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Feature Requests',
          style: ResponsiveTextStyles.title(
            context,
          ).copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: _buildLoadingDots());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRequests,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: _buildLoadingDots());
        }

        final requests = snapshot.data?.docs ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Text(
              'No pending feature requests',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        requests.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
          final bTime =
              (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) => _buildRequestCard(requests[index]),
        );
      },
    );
  }

  Widget _buildRequestCard(DocumentSnapshot request) {
    final data = request.data() as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp).toDate();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['feature'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    data['product'],
                    style: TextStyle(color: AppColors.white),
                  ),
                  backgroundColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person, data['customerName']),
            _buildDetailRow(Icons.email, data['customerEmail']),
            _buildDetailRow(Icons.calendar_today, _formatDate(createdAt)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed:
                      () =>
                          _processRequest(request: request, isApproved: false),
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed:
                      () => _processRequest(request: request, isApproved: true),
                  child: const Text(
                    'Approve',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_buildDot(0), _buildDot(1), _buildDot(2)],
    );
  }

  Widget _buildDot(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        curve: Curves.easeInOut,
        child: const SizedBox(),
      ),
    );
  }
}
