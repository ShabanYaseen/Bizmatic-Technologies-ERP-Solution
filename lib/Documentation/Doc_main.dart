import 'package:bizmatic_solutions/Components/Colors.dart';
import 'package:bizmatic_solutions/Components/Fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class Doc_mainScreen extends StatefulWidget {
  final String customerId;
  final String restaurantName;

  const Doc_mainScreen({
    super.key,
    required this.customerId,
    required this.restaurantName,
  });

  @override
  State<Doc_mainScreen> createState() => _Doc_mainScreenState();
}

class _Doc_mainScreenState extends State<Doc_mainScreen> {
  int selectedProductIndex = 0;

  final List<ProductDocumentation> products = [
    ProductDocumentation(
      name: "Butter POS",
      documents: [
        Document(name: "User Manual", url: "https://www.google.com"),
        Document(
          name: "Installation Guide",
          url: "https://docs.google.com/document/d/1crBn-Q2ehyDFcl-HQ1SMv85QniJXuQwu/view",
        ),
      ],
    ),
    ProductDocumentation(
      name: "Gofrugal ServEasy",
      documents: [
        Document(
          name: "Admin Guide",
          url: "https://docs.google.com/document/d/1crBn-Q2ehyDFcl-HQ1SMv85QniJXuQwu/view",
        ),
      ],
    ),
    ProductDocumentation(
      name: "Gofrugal RetailEasy",
      documents: [
        Document(
          name: "Quick Start Guide",
          url: "https://docs.google.com/document/d/1KuiY9PZLcq0yKXPmKSGOp1X_KPXlnBSL/view",
        ),
      ],
    ),
    ProductDocumentation(
      name: "Odoo",
      documents: [
        Document(
          name: "Quick Start Guide",
          url: "https://docs.google.com/document/d/1KuiY9PZLcq0yKXPmKSGOp1X_KPXlnBSL/view",
        ),
      ],
    ),
  ];

  Future<void> _launchURL(String url) async {
    try {
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }

      final Uri uri = Uri.parse(formattedUrl);
      bool launched = await _tryLaunch(uri);

      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      }

      if (!launched) {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(url, e.toString());
      }
    }
  }

  Future<bool> _tryLaunch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  void _showErrorDialog(String url, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Could not open link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error),
            const SizedBox(height: 16),
            const Text('Would you like to copy the URL to clipboard?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedProduct = products[selectedProductIndex];

    return Scaffold(
      backgroundColor: AppColors.Background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: AppColors.white),
        title: Text(
          "Documentation",
          style: ResponsiveTextStyles.title(context).copyWith(color: AppColors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Select Product", style: ResponsiveTextStyles.subtitle(context).copyWith(color: AppColors.Black)),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final bool isSelected = selectedProductIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(
                      products[index].name,
                      style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.Black,
                      ),
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey[300],
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedProductIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Documents", style: ResponsiveTextStyles.subtitle(context).copyWith(color: AppColors.Black)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: selectedProduct.documents.length,
              itemBuilder: (context, index) {
                final document = selectedProduct.documents[index];
                return Card(
                  color: AppColors.white,
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      document.name,
                      style: ResponsiveTextStyles.body(context).copyWith(color: AppColors.Black),
                    ),
                    trailing: const Icon(Icons.open_in_new, color: AppColors.primary),
                    onTap: () => _launchURL(document.url),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDocumentation {
  final String name;
  final List<Document> documents;

  ProductDocumentation({
    required this.name,
    required this.documents,
  });
}

class Document {
  final String name;
  final String url;

  Document({
    required this.name,
    required this.url,
  });
}
