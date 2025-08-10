
// ==========================
// Product Feature Data
// ==========================

import 'package:bizmatic_solutions/Models/ProductFeature.dart';

final ProductFeatureSet butterPOS = ProductFeatureSet(
  name: "Butter POS",
  versions: ["Basic", "Pro"],
  groups: [
    FeatureGroup(
      groupName: "Sales",
      features: [
        FeatureItem(name: "POS Billing", availableInVersions: ["Basic", "Pro"], description: "Fast and reliable billing system."),
        FeatureItem(name: "Daily Sales", availableInVersions: ["Basic", "Pro"], description: "Track sales on a daily basis."),
        FeatureItem(name: "Discount Management", availableInVersions: ["Pro"], description: "Advanced discount settings."),
      ],
    ),
    FeatureGroup(
      groupName: "Inventory",
      features: [
        FeatureItem(name: "Stock Alerts", availableInVersions: ["Pro"], description: "Get notified when stock is low."),
      ],
    ),
  ],
);

final ProductFeatureSet gofrugalServEasy = ProductFeatureSet(
  name: "Gofrugal ServEasy",
  versions: ["Basic", "Pro"],
  groups: [
    FeatureGroup(
      groupName: "Core Features",
      features: [
        FeatureItem(name: "Billing", availableInVersions: ["Basic", "Pro"], description: "Quick billing process."),
        FeatureItem(name: "Inventory Tracking", availableInVersions: ["Pro"], description: "Monitor inventory in real-time."),
        FeatureItem(name: "Reports", availableInVersions: ["Pro"], description: "Generate business reports instantly."),
      ],
    ),
    FeatureGroup(
      groupName: "Communication",
      features: [
        FeatureItem(name: "SMS Integration", availableInVersions: ["Pro"], description: "Send SMS notifications to customers."),
      ],
    ),
  ],
);

final ProductFeatureSet retailMasterPro = ProductFeatureSet(
  name: "Retail Master Pro",
  versions: ["Standard", "Premium"],
  groups: [
    FeatureGroup(
      groupName: "Management",
      features: [
        FeatureItem(name: "Customer Loyalty", availableInVersions: ["Premium"], description: "Reward and retain customers."),
        FeatureItem(name: "Multi-Store Management", availableInVersions: ["Premium"], description: "Control multiple stores from one dashboard."),
      ],
    ),
    FeatureGroup(
      groupName: "Analytics",
      features: [
        FeatureItem(name: "Sales Forecasting", availableInVersions: ["Premium"], description: "Predict future sales."),
        FeatureItem(name: "Purchase Reports", availableInVersions: ["Standard", "Premium"], description: "Track purchases over time."),
      ],
    ),
  ],
);
