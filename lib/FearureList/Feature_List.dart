import 'package:bizmatic_solutions/FearureList/ButterPOS_Feature.dart';
import 'package:bizmatic_solutions/FearureList/ServEasy_Feature.dart';
import 'package:bizmatic_solutions/Models/ProductFeature.dart';
import 'package:flutter/material.dart';
import '../Components/Colors.dart';
import '../Components/Fonts.dart';

class FeatureList extends StatefulWidget {
  const FeatureList({super.key});

  @override
  State<FeatureList> createState() => _FeatureListState();
}

class _FeatureListState extends State<FeatureList> {
  final List<ProductFeatureSet> products = [ butterPOS, gofrugalServEasy, gofrugalServEasy];
  int selectedProductIndex = 0;
  int selectedVersionIndex = 0;

  late Map<String, bool> _expandedGroups;

  @override
  void initState() {
    super.initState();
    _initExpandedGroups();
  }

  void _initExpandedGroups() {
    final product = products[selectedProductIndex];
    _expandedGroups = {for (var group in product.groups) group.groupName: true};
  }

  @override
  Widget build(BuildContext context) {
    final product = products[selectedProductIndex];
    final selectedVersion = product.versions[selectedVersionIndex];

    return Scaffold(
      backgroundColor: AppColors.Background,
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primary,
        title: Text(
          "Feature List",
          style: ResponsiveTextStyles.title(context).copyWith(color: AppColors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelector(
            title: "Select Product",
            items: products.map((e) => e.name).toList(),
            selectedIndex: selectedProductIndex,
            onSelected: (index) {
              setState(() {
                selectedProductIndex = index;
                selectedVersionIndex = 0;
                _initExpandedGroups();
              });
            },
          ),
          _buildSelector(
            title: "Select Version",
            items: product.versions,
            selectedIndex: selectedVersionIndex,
            onSelected: (index) {
              setState(() {
                selectedVersionIndex = index;
              });
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Features",
              style: ResponsiveTextStyles.subtitle(context).copyWith(color: AppColors.Black),
            ),
          ),
          Expanded(
            child: ListView(
              children: product.groups.map((group) {
                final isExpanded = _expandedGroups[group.groupName] ?? true;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    title: Text(
                      group.groupName,
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (val) {
                      setState(() {
                        _expandedGroups[group.groupName] = val;
                      });
                    },
                    children: group.features.map((feature) {
                      final isAvailable = feature.availableInVersions.contains(selectedVersion);
                      return ListTile(
                        leading: Icon(
                          isAvailable ? Icons.check_circle : Icons.cancel,
                          color: isAvailable ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          feature.name,
                          style: TextStyle(
                            color: isAvailable ? Colors.black : Colors.grey,
                            decoration: isAvailable ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required String title,
    required List<String> items,
    required int selectedIndex,
    required void Function(int) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: ResponsiveTextStyles.subtitle(context).copyWith(color: AppColors.Black),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final isSelected = selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text(
                    items[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onSelected(index),
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
    );
  }
}
