import 'dart:async';

import 'package:bizmatic_solutions/FearureList/Product_feature_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// Your own project imports
import '../Components/Colors.dart';
import '../Components/Fonts.dart';
import 'package:bizmatic_solutions/Models/ProductFeature.dart';

// ==========================
// Feature List Widget
// ==========================
class FeatureList extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerEmail;

  const FeatureList({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
  });

  @override
  State<FeatureList> createState() => _FeatureListState();
}

class _FeatureListState extends State<FeatureList> with SingleTickerProviderStateMixin {
  // ===== Products =====
  final List<ProductFeatureSet> products = [
    butterPOS,
    gofrugalServEasy,
    retailMasterPro
  ];

  int selectedProductIndex = 0;
  late Map<String, bool> _expandedGroups;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;
  
  // Store active features and pending requests
  Map<String, List<String>> activeFeatures = {};
  Map<String, List<String>> pendingRequests = {};
  bool isLoading = true;
  
  // Animation controller for loading dots
  late AnimationController _loadingController;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _initExpandedGroups();
    _setupAnimationController();
    _setupRealTimeUpdates();
  }

  void _setupAnimationController() {
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    
    _dotAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
          parent: _loadingController,
          curve: Interval(
            0.2 * index,
            0.2 * (index + 1),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _loadingController.dispose();
    super.dispose();
  }

  void _initExpandedGroups() {
    final product = products[selectedProductIndex];
    _expandedGroups = {for (var group in product.groups) group.groupName: true};
  }

  void _setupRealTimeUpdates() {
    // Listen for changes in active features
    _subscription = _firestore
        .collection('customers')
        .doc(widget.customerId)
        .collection('activeFeatures')
        .snapshots()
        .listen((snapshot) {
      Map<String, List<String>> updatedFeatures = {};
      for (var doc in snapshot.docs) {
        updatedFeatures[doc.id] = List<String>.from(doc.data()['features'] ?? []);
      }
      if (mounted) {
        setState(() => activeFeatures = updatedFeatures);
      }
    });

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    
    try {
      // Load initial active features
      final activeFeaturesDoc = await _firestore
          .collection('customers')
          .doc(widget.customerId)
          .collection('activeFeatures')
          .get();
      
      Map<String, List<String>> tempActiveFeatures = {};
      for (var doc in activeFeaturesDoc.docs) {
        tempActiveFeatures[doc.id] = List<String>.from(doc.data()['features'] ?? []);
      }
      
      // Load pending requests
      final pendingRequestsQuery = await _firestore
          .collection('featureRequests')
          .where('customerId', isEqualTo: widget.customerId)
          .where('status', whereIn: ['pending', 'approved'])
          .get();
      
      Map<String, List<String>> tempPendingRequests = {};
      for (var doc in pendingRequestsQuery.docs) {
        final product = doc.data()['product'] as String;
        final feature = doc.data()['feature'] as String;
        
        if (!tempPendingRequests.containsKey(product)) {
          tempPendingRequests[product] = [];
        }
        if (!tempPendingRequests[product]!.contains(feature)) {
          tempPendingRequests[product]!.add(feature);
        }
      }
      
      if (mounted) {
        setState(() {
          activeFeatures = tempActiveFeatures;
          pendingRequests = tempPendingRequests;
          isLoading = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnack('Error loading features: ${e.toString()}');
      }
    }
  }

  Future<void> _sendFeatureRequest(FeatureItem feature) async {
    _showLoading();
    try {
      final productName = products[selectedProductIndex].name;
      
      // Check if this feature is already active
      if (activeFeatures[productName]?.contains(feature.name) ?? false) {
        _closeLoading();
        _showSnack('This feature is already active for your account');
        return;
      }
      
      // Check if this feature is already requested
      final existingRequest = await _firestore
          .collection('featureRequests')
          .where('customerId', isEqualTo: widget.customerId)
          .where('product', isEqualTo: productName)
          .where('feature', isEqualTo: feature.name)
          .where('status', whereIn: ['pending', 'approved'])
          .get();
      
      if (existingRequest.docs.isNotEmpty) {
        _closeLoading();
        _showSnack('You already have a pending or approved request for this feature');
        return;
      }
      
      // Create new request
      await _firestore.collection('featureRequests').add({
        'product': productName,
        'feature': feature.name,
        'status': 'pending',
        'customerId': widget.customerId,
        'customerName': widget.customerName,
        'customerEmail': widget.customerEmail,
        'agentId': '',
        'agentName': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      if (mounted) {
        setState(() {
          pendingRequests[productName] ??= [];
          if (!pendingRequests[productName]!.contains(feature.name)) {
            pendingRequests[productName]!.add(feature.name);
          }
        });
      }

      await _sendEmail(
        subject: 'New Feature Request from ${widget.customerName}',
        body: '''
Customer: ${widget.customerName}
Product: $productName
Feature: ${feature.name}
Customer Email: ${widget.customerEmail}
''',
      );

      _closeLoading();
      _showSnack('Feature request sent successfully!');
    } catch (e) {
      _closeLoading();
      _showSnack('Error: ${e.toString()}');
    }
  }

  Future<void> _sendEmail({required String subject, required String body}) async {
    final username = 'bizmaticshaban@gmail.com';
    final password = 'jfhw kkvm azgz vrox';
    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Feature Request System')
      ..recipients.add('bizmaticshaban@gmail.com')
      ..subject = subject
      ..text = body;

    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('Email sending error: $e');
    }
  }

  void _showFeatureDetails(FeatureItem feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(feature.description ?? 'No description available'),
              const SizedBox(height: 16),
              if (feature.specifications != null)
                ...feature.specifications!.map((spec) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('- $spec'),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(FeatureItem feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request ${feature.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to request this feature?'),
            const SizedBox(height: 16),
            Text(
              feature.description ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.Black),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _sendFeatureRequest(feature);
            },
            child: const Text('Confirm Request'),
          ),
        ],
      ),
    );
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLoadingDots(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _closeLoading() {
    Navigator.pop(context);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.Background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLoadingDots(),
              const SizedBox(height: 16),
              Text(
                'Loading features...',
                style: ResponsiveTextStyles.body(context).copyWith(color: AppColors.Black),
              ),
            ],
          ),
        ),
      );
    }

    final product = products[selectedProductIndex];
    final productName = product.name;
    final activeList = activeFeatures[productName] ?? [];
    final pendingList = pendingRequests[productName] ?? [];

    return Scaffold(
      backgroundColor: AppColors.Background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primary,
        title: Text(
          "Feature List",
          style: ResponsiveTextStyles.title(context).copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Refresh features',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductSelector(),
          const Divider(height: 1),
          _buildFeatureStatusLegend(),
          Expanded(
            child: _buildFeatureList(product, activeList, pendingList),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Product",
            style: ResponsiveTextStyles.subtitle(context).copyWith(color: AppColors.Black),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final isSelected = selectedProductIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(
                      products[index].name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedProductIndex = index;
                        _initExpandedGroups();
                      });
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureStatusLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildLegendItem(Icons.check_circle, 'Active', Colors.green),
          const SizedBox(width: 12),
          _buildLegendItem(Icons.access_time, 'Pending', Colors.orange),
          const SizedBox(width: 12),
          _buildLegendItem(Icons.cancel, 'Not Available', Colors.red),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
      ],
    );
  }

  Widget _buildFeatureList(ProductFeatureSet product, List<String> activeList, List<String> pendingList) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: product.groups.map((group) {
        final isExpanded = _expandedGroups[group.groupName] ?? true;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              group.groupName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (val) {
              setState(() {
                _expandedGroups[group.groupName] = val;
              });
            },
            children: group.features.map((feature) {
              final isActive = activeList.contains(feature.name);
              final isPending = pendingList.contains(feature.name);
              
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Icon(
                    isActive ? Icons.check_circle : 
                      isPending ? Icons.access_time : Icons.cancel,
                    color: isActive ? Colors.green : 
                      isPending ? Colors.orange : Colors.red,
                  ),
                  title: Text(
                    feature.name,
                    style: TextStyle(
                      color: isActive ? Colors.black : 
                        isPending ? Colors.orange : Colors.grey,
                      decoration: isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isActive && !isPending)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () => _showPurchaseDialog(feature),
                          child: const Text('Request'),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.blue),
                        onPressed: () => _showFeatureDetails(feature),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _loadingController,
          builder: (context, child) {
            return Opacity(
              opacity: _dotAnimations[index].value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}