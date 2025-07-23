import 'package:bizmatic_solutions/Models/ProductFeature.dart';


final ProductFeatureSet gofrugalServEasy = ProductFeatureSet(
  name: "Gofrugal ServEasy",
  versions: ["Starter", "Standard", "Professional"],
  groups: [
    FeatureGroup(
      groupName: "Sales",
      features: [
        FeatureItem(name: "Billing", availableInVersions: ["Starter", "Standard", "Professional"]),
        FeatureItem(name: "Inventory Tracking", availableInVersions: ["Starter", "Standard", "Professional"]),
      ],
    ),
    FeatureGroup(
      groupName: "Purchase",
      features: [
        FeatureItem(name: "Reports", availableInVersions: ["Starter", "Standard", "Professional"]),
        FeatureItem(name: "User Roles", availableInVersions: ["Standard", "Professional"]),
      ],
    ),
    FeatureGroup(
      groupName: "Inventory",
      features: [
        FeatureItem(name: "CRM", availableInVersions: ["Professional"]),
        FeatureItem(name: "Integration with Online Orders", availableInVersions: ["Professional"]),
      ],
    ),
  ],
);
