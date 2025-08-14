/// Pricing models and structures for the monetization system.
/// 
/// Provides comprehensive pricing support for multiple regions, plan terms,
/// and tiers according to the finalized pricing strategy.

import 'monetization_service.dart';
import '../../l10n/localization.dart';

/// Regions for pricing localization
enum Region {
  base,       // Base market (USD): Premium $1.99, Pro $2.99, Enterprise $2.00/user
  africa,     // Africa region: Premium $0.99, Pro $1.99, Enterprise $1.00/user  
  asia,       // Asia region: Premium $1.49, Pro $2.49, Enterprise $1.50/user
  europe,     // Europe region: Premium $2.49, Pro $3.49, Enterprise $2.50/user
  latinAmerica, // Latin America: Premium $1.29, Pro $2.29, Enterprise $1.30/user
  india,      // India region: Premium $0.79, Pro $1.49, Enterprise $0.80/user
  eastEurope, // Eastern Europe: Premium $1.19, Pro $1.99, Enterprise $1.20/user
}

/// Plan terms for different subscription periods
enum PlanTerm {
  monthly,  // Monthly billing
  annual,   // Annual billing (20% discount)
  lifetime, // One-time lifetime purchase (Premium and Pro only)
}

/// Complete pricing plan with tier, term, and region
class PricingPlan {
  final UserTier tier;
  final PlanTerm term;
  final Region region;
  final double basePrice;
  final bool perUser;

  const PricingPlan({
    required this.tier,
    required this.term,
    required this.region,
    required this.basePrice,
    this.perUser = false,
  });

  /// Display price with proper formatting
  String get displayPrice {
    final price = basePrice.toStringAsFixed(2);
    if (perUser) {
      return '\$$price/user';
    }
    return '\$$price';
  }

  /// Get monthly anchor price (used for calculations)
  double get monthlyAnchor {
    switch (term) {
      case PlanTerm.monthly:
        return basePrice;
      case PlanTerm.annual:
        // Annual is 20% off monthly * 12, so monthly = annual / (12 * 0.8)
        return basePrice / (12 * 0.8);
      case PlanTerm.lifetime:
        // Lifetime is ~3.2x monthly * 12, so monthly = lifetime / (12 * 3.2)
        return basePrice / (12 * 3.2);
    }
  }

  /// Get metadata about the pricing calculation
  Map<String, dynamic> get metadata {
    final monthlyBase = monthlyAnchor;
    
    switch (term) {
      case PlanTerm.monthly:
        return {
          'monthly_anchor': monthlyBase,
          'discount_pct': 0,
        };
      case PlanTerm.annual:
        return {
          'monthly_anchor': monthlyBase,
          'discount_pct': 20,
          'annual_savings': (monthlyBase * 12) - basePrice,
        };
      case PlanTerm.lifetime:
        return {
          'monthly_anchor': monthlyBase,
          'break_even_years': basePrice / (monthlyBase * 12),
        };
    }
  }
}

/// Pricing service for retrieving pricing information
class PricingService {
  // Base monthly prices for each tier in USD
  static const Map<UserTier, double> _basePrices = {
    UserTier.free: 0.0,
    UserTier.premium: 1.99,
    UserTier.pro: 2.99,
    UserTier.enterprise: 2.00, // per user
  };

  // Regional pricing maps in USD
  static const Map<Region, Map<UserTier, double>> _regionalPrices = {
    Region.base: {
      UserTier.free: 0.0,
      UserTier.premium: 1.99,
      UserTier.pro: 2.99,
      UserTier.enterprise: 2.00,
    },
    Region.africa: {
      UserTier.free: 0.0,
      UserTier.premium: 0.99,
      UserTier.pro: 1.99,
      UserTier.enterprise: 1.00,
    },
    Region.asia: {
      UserTier.free: 0.0,
      UserTier.premium: 1.49,
      UserTier.pro: 2.49,
      UserTier.enterprise: 1.50,
    },
    Region.europe: {
      UserTier.free: 0.0,
      UserTier.premium: 2.49,
      UserTier.pro: 3.49,
      UserTier.enterprise: 2.50,
    },
    Region.latinAmerica: {
      UserTier.free: 0.0,
      UserTier.premium: 1.29,
      UserTier.pro: 2.29,
      UserTier.enterprise: 1.30,
    },
    Region.india: {
      UserTier.free: 0.0,
      UserTier.premium: 0.79,
      UserTier.pro: 1.49,
      UserTier.enterprise: 0.80,
    },
    Region.eastEurope: {
      UserTier.free: 0.0,
      UserTier.premium: 1.19,
      UserTier.pro: 1.99,
      UserTier.enterprise: 1.20,
    },
  };

  /// Get pricing plan for specific tier, term, and region
  static PricingPlan getPlan({
    required UserTier tier,
    required PlanTerm term,
    Region region = Region.base,
  }) {
    if (tier == UserTier.free) {
      return PricingPlan(
        tier: tier,
        term: term,
        region: region,
        basePrice: 0.0,
      );
    }

    // Get base monthly price for region
    final monthlyPrice = _regionalPrices[region]?[tier] ?? _basePrices[tier]!;

    // Calculate price based on term
    double finalPrice;
    switch (term) {
      case PlanTerm.monthly:
        finalPrice = monthlyPrice;
        break;
      case PlanTerm.annual:
        // 20% discount off 12 months, rounded to .99 endings
        finalPrice = _calculateAnnualPrice(monthlyPrice);
        break;
      case PlanTerm.lifetime:
        // Only available for Premium and Pro tiers
        if (tier == UserTier.enterprise) {
          throw ArgumentError('Lifetime plans not available for Enterprise tier');
        }
        finalPrice = _calculateLifetimePrice(monthlyPrice);
        break;
    }

    return PricingPlan(
      tier: tier,
      term: term,
      region: region,
      basePrice: finalPrice,
      perUser: tier == UserTier.enterprise,
    );
  }

  /// Calculate annual price with 20% discount and .99 endings
  static double _calculateAnnualPrice(double monthlyPrice) {
    final discountedPrice = monthlyPrice * 12 * 0.8;
    
    // Regional-aware pricing with .99 endings
    if (discountedPrice <= 7.5) {        // India, Very low-tier regions
      return 7.99;
    } else if (discountedPrice <= 10) {   // Africa Premium, India Pro
      return 9.99;
    } else if (discountedPrice <= 14) {   // East Europe Premium, Latin America Pro
      return 11.99;
    } else if (discountedPrice <= 20) {   // Premium base/asia, Africa/India Pro, Enterprise per-user
      return 19.99;
    } else if (discountedPrice <= 24) {   // Asia Pro
      return 23.99;
    } else if (discountedPrice <= 30) {   // Pro base
      return 29.99;
    } else if (discountedPrice <= 34) {   // Europe Pro
      return 33.99;
    }
    
    // For higher prices, round to nearest .99
    return (discountedPrice / 5).round() * 5 - 0.01;
  }

  /// Calculate lifetime price (~3.2x monthly*12) with psychological endings
  static double _calculateLifetimePrice(double monthlyPrice) {
    final baseLifetime = monthlyPrice * 12 * 3.2;
    
    // Regional-aware lifetime pricing with psychological endings
    if (monthlyPrice <= 0.8) {           // India Premium
      return 29.99;
    } else if (monthlyPrice <= 1.0) {    // Africa Premium  
      return 37.99;
    } else if (monthlyPrice <= 1.2) {    // East Europe Premium
      return 45.99;
    } else if (monthlyPrice <= 1.3) {    // Latin America Premium
      return 49.99;
    } else if (monthlyPrice <= 1.5) {    // Asia Premium, India Pro
      return 59.99;
    } else if (monthlyPrice <= 2.0) {    // Premium base, Africa/East Europe Pro
      return 74.99;
    } else if (monthlyPrice <= 2.3) {    // Latin America Pro
      return 87.99;
    } else if (monthlyPrice <= 2.5) {    // Asia Pro
      return 94.99;
    } else if (monthlyPrice <= 3.0) {    // Pro base
      return 114.99;
    } else if (monthlyPrice <= 3.5) {    // Europe Pro
      return 134.99;
    }
    
    // For edge cases, use calculated value with .99 ending
    return (baseLifetime / 10).round() * 10 - 0.01;
  }

  /// Get all available plans for a specific tier
  static List<PricingPlan> getPlansForTier(UserTier tier, {Region region = Region.base}) {
    if (tier == UserTier.free) {
      return [getPlan(tier: tier, term: PlanTerm.monthly, region: region)];
    }

    final plans = <PricingPlan>[
      getPlan(tier: tier, term: PlanTerm.monthly, region: region),
      getPlan(tier: tier, term: PlanTerm.annual, region: region),
    ];

    // Add lifetime for individual tiers only
    if (tier != UserTier.enterprise) {
      plans.add(getPlan(tier: tier, term: PlanTerm.lifetime, region: region));
    }

    return plans;
  }

  /// Get display pricing for a region with all tiers and terms
  static Map<UserTier, List<PricingPlan>> getDisplayPricing({
    Region region = Region.base,
    bool includeLifetime = true,
  }) {
    final result = <UserTier, List<PricingPlan>>{};
    
    for (final tier in UserTier.values) {
      final plans = getPlansForTier(tier, region: region);
      if (!includeLifetime) {
        result[tier] = plans.where((p) => p.term != PlanTerm.lifetime).toList();
      } else {
        result[tier] = plans;
      }
    }
    
    return result;
  }

  /// Get pricing for analytics (with region and term info)
  static Map<String, dynamic> getPricingForAnalytics({
    required UserTier tier,
    required PlanTerm term,
    Region region = Region.base,
  }) {
    final plan = getPlan(tier: tier, term: term, region: region);
    
    return {
      'tier': tier.name,
      'plan_term': term.name,
      'region': region.name,
      'per_user': plan.perUser,
      'base_price': plan.basePrice,
      'localized_price': plan.basePrice, // Same as base_price for now
      'display_price': plan.displayPrice,
      'metadata': plan.metadata,
    };
  }
}

/// Legacy PricingInfo class - updated with new pricing but maintaining API compatibility
class LegacyPricingInfo {
  final UserTier tier;
  final String displayName;
  final String price;
  final String billingPeriod;
  final List<String> features;

  const LegacyPricingInfo({
    required this.tier,
    required this.displayName,
    required this.price,
    required this.billingPeriod,
    required this.features,
  });

  /// Get pricing info for all tiers (updated with new pricing)
  static List<LegacyPricingInfo> getAllTiers() {
    return [
      const LegacyPricingInfo(
        tier: UserTier.free,
        displayName: 'Free',
        price: '\$0',
        billingPeriod: 'forever',
        features: [
          '50 notes per month',
          '5 voice recordings (2min each)',
          '3 folders maximum',
          '10 attachments per month',
          'Basic doodling and canvas',
          'Local export/import only',
        ],
      ),
      const LegacyPricingInfo(
        tier: UserTier.premium,
        displayName: 'Premium',
        price: '\$1.99',
        billingPeriod: 'month',
        features: [
          'Unlimited notes and folders',
          '100 voice recordings (10min each)',
          'Voice note transcription',
          'Advanced drawing tools & layers',
          'OCR text extraction',
          'All export formats (PDF, DOCX)',
          'Cloud sync capabilities',
          'No ads',
        ],
      ),
      const LegacyPricingInfo(
        tier: UserTier.pro,
        displayName: 'Pro',
        price: '\$2.99',
        billingPeriod: 'month',
        features: [
          'Everything in Premium',
          'Unlimited voice recordings (30min each)',
          'Advanced search with OCR',
          'Usage analytics & insights',
          'Automated backup scheduling',
          'Custom export templates',
          'Advanced encryption options',
          'API access for integrations',
          'Enhanced cloud sync capabilities',
          'Priority support',
        ],
      ),
      const LegacyPricingInfo(
        tier: UserTier.enterprise,
        displayName: 'Enterprise',
        price: '\$2.00',
        billingPeriod: 'per user/month',
        features: [
          'Everything in Pro',
          'Team workspace management',
          'Admin dashboard & user management',
          'Advanced sharing & permissions',
          'SSO integration',
          'Audit logs & compliance features',
          'Custom branding options',
          'Enterprise cloud sync capabilities',
          'Dedicated account manager',
          'SLA guarantees',
        ],
      ),
    ];
  }

  /// Get pricing info for all tiers with localized strings
  /// This version uses localized display names and feature descriptions
  static List<LegacyPricingInfo> getAllTiersLocalized([LocalizationService? localization]) {
    final l10n = localization ?? LocalizationService.instance;
    
    return [
      LegacyPricingInfo(
        tier: UserTier.free,
        displayName: l10n.pricingFree,
        price: '\$0',
        billingPeriod: 'forever',
        features: [
          '50 notes per month',
          '5 voice recordings (2min each)',
          '3 folders maximum',
          '10 attachments per month',
          'Basic doodling and canvas',
          'Local export/import only',
        ],
      ),
      LegacyPricingInfo(
        tier: UserTier.premium,
        displayName: l10n.pricingPremium,
        price: '\$1.99',
        billingPeriod: l10n.planTermMonthly.toLowerCase(),
        features: [
          l10n.featureUnlimitedNotes,
          '100 voice recordings (10min each)',
          l10n.featureVoiceTranscription,
          l10n.featureAdvancedDrawingTools,
          'OCR text extraction',
          'All export formats (PDF, DOCX)',
          'Cloud sync capabilities',
          l10n.featureNoAds,
        ],
      ),
      LegacyPricingInfo(
        tier: UserTier.pro,
        displayName: l10n.pricingPro,
        price: '\$2.99',
        billingPeriod: l10n.planTermMonthly.toLowerCase(),
        features: [
          'Everything in ${l10n.pricingPremium}',
          'Unlimited voice recordings (30min each)',
          'Advanced search with OCR',
          'Usage analytics & insights',
          'Automated backup scheduling',
          'Custom export templates',
          'Advanced encryption options',
          'API access for integrations',
          'Enhanced cloud sync capabilities',
          l10n.featurePrioritySupport,
        ],
      ),
      LegacyPricingInfo(
        tier: UserTier.enterprise,
        displayName: l10n.pricingEnterprise,
        price: '\$2.00',
        billingPeriod: '${l10n.planTermPerUser.toLowerCase()}/${l10n.planTermMonthly.toLowerCase()}',
        features: [
          'Everything in ${l10n.pricingPro}',
          'Team workspace management',
          l10n.featureAdminControls,
          'Advanced sharing & permissions',
          'SSO integration',
          'Audit logs & compliance features',
          'Custom branding options',
          'Enterprise cloud sync capabilities',
          'Dedicated account manager',
          'SLA guarantees',
        ],
      ),
    ];
  }
}