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

  FeatureItem({
    required this.name,
    required this.availableInVersions,
  });
}
