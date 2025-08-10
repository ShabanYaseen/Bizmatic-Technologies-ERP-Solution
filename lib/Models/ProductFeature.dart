// Models

class ProductFeatureSet {
  final String name;
  final List<String> versions;
  final List<FeatureGroup> groups;

  ProductFeatureSet({
    required this.name,
    required this.versions,
    required this.groups,
  });
}

class FeatureGroup {
  final String groupName;
  final List<FeatureItem> features;

  FeatureGroup({
    required this.groupName,
    required this.features,
  });
}

class FeatureItem {
  final String name;
  final List<String> availableInVersions;
  final String? description;       // Optional field for extra info
  final List<String>? specifications; // Optional field for detailed specs

  FeatureItem({
    required this.name,
    required this.availableInVersions,
    this.description,
    this.specifications,
  });
}
