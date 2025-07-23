import 'package:bizmatic_solutions/Models/ProductFeature.dart';


final ProductFeatureSet gofrugalServEasy = ProductFeatureSet(
  name: "Butter POS",
  versions: ["Basic", "Pro"],
  groups: [
    FeatureGroup(
      groupName: "Basic",
      features: [
        FeatureItem(name: "POS Billing", availableInVersions: ["Basic", "Pro"]),
        FeatureItem(name: "Daily Sales", availableInVersions: ["Basic", "Pro"]),
      ],
    ),
    FeatureGroup(
      groupName: "Advanced",
      features: [
        FeatureItem(name: "SMS Integration", availableInVersions: ["Pro"]),
      ],
    ),
  ],
);
