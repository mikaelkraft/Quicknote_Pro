/// Pricing models and structures for the monetization system.
/// 
/// Provides comprehensive pricing support for multiple regions, plan terms,
/// and tiers according to the finalized pricing strategy.

import 'monetization_service.dart';

/// Regions for pricing localization
enum Region {
  base,   // Base market (USD): Premium $1.99, Pro $2.99, Enterprise $2.00/user
  africa, // Africa region: Premium $0.99, Pro $1.99, Enterprise $1.00/user
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

  // Africa region monthly prices in USD
  static const Map<UserTier, double> _africaPrices = {
    UserTier.free: 0.0,
    UserTier.premium: 0.99,
    UserTier.pro: 1.99, // Recalculated from $2.00 to $1.99
    UserTier.enterprise: 1.00, // per user
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
    final monthlyPrice = region == Region.africa 
        ? _africaPrices[tier]! 
        : _basePrices[tier]!;

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
    
    // Round to .99 endings based on the calculated values from requirements
    if (discountedPrice <= 10) {
      return 9.99; // Africa Premium
    } else if (discountedPrice <= 20) {
      return 19.99; // Premium, Africa Pro, Enterprise per-user
    } else if (discountedPrice <= 30) {
      return 29.99; // Pro
    }
    
    // Fallback to calculated value for edge cases
    return double.parse(discountedPrice.toStringAsFixed(2));
  }

  /// Calculate lifetime price (~3.2x monthly*12) with psychological endings
  static double _calculateLifetimePrice(double monthlyPrice) {
    final baseLifetime = monthlyPrice * 12 * 3.2;
    
    // Specific values from requirements
    if (monthlyPrice == 1.99) { // Premium base
      return 74.99;
    } else if (monthlyPrice == 2.99) { // Pro base
      return 114.99;
    } else if (monthlyPrice == 0.99) { // Africa Premium
      return 37.99;
    } else if (monthlyPrice == 1.99 && monthlyPrice == 1.99) { // Africa Pro (also $1.99)
      return 74.99;
    }
    
    // Fallback calculation with .99 or .49 endings
    if (baseLifetime < 50) {
      return 37.99;
    } else if (baseLifetime < 80) {
      return 74.99;
    } else if (baseLifetime < 120) {
      return 114.99;
    }
    
    // Round to nearest .99
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
          '5 voice recordings',
          '3 folders',
          'Basic sync',
        ],
      ),
      const LegacyPricingInfo(
        tier: UserTier.premium,
        displayName: 'Premium',
        price: '\$1.99',
        billingPeriod: 'month',
        features: [
          'Unlimited notes',
          '100 voice recordings',
          'Advanced drawing tools',
          'Premium export formats',
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
          'Unlimited voice recordings',
          'Priority support',
          'Advanced analytics',
          'Extended storage',
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
          'Admin dashboard',
          'SSO integration',
          'Audit logs & compliance',
          'Custom branding',
          'Dedicated support',
        ],
      ),
    ];
  }
}