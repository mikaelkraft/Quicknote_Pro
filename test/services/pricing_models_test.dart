import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/monetization/pricing_models.dart';
import 'package:quicknote_pro/services/monetization/monetization_service.dart';

void main() {
  group('PricingService', () {
    test('should return correct base monthly prices', () {
      final premiumPlan = PricingService.getPlan(
        tier: UserTier.premium, 
        term: PlanTerm.monthly,
      );
      expect(premiumPlan.basePrice, 1.99);
      
      final proPlan = PricingService.getPlan(
        tier: UserTier.pro, 
        term: PlanTerm.monthly,
      );
      expect(proPlan.basePrice, 2.99);
      
      final enterprisePlan = PricingService.getPlan(
        tier: UserTier.enterprise, 
        term: PlanTerm.monthly,
      );
      expect(enterprisePlan.basePrice, 2.00);
      expect(enterprisePlan.perUser, true);
    });

    test('should return correct Africa region monthly prices', () {
      final premiumPlan = PricingService.getPlan(
        tier: UserTier.premium, 
        term: PlanTerm.monthly,
        region: Region.africa,
      );
      expect(premiumPlan.basePrice, 0.99);
      
      final proPlan = PricingService.getPlan(
        tier: UserTier.pro, 
        term: PlanTerm.monthly,
        region: Region.africa,
      );
      expect(proPlan.basePrice, 1.99); // Recalculated from $2.00
      
      final enterprisePlan = PricingService.getPlan(
        tier: UserTier.enterprise, 
        term: PlanTerm.monthly,
        region: Region.africa,
      );
      expect(enterprisePlan.basePrice, 1.00);
    });

    test('should calculate correct annual prices with 20% discount', () {
      // Premium base: 1.99*12*0.8=19.10 → $19.99
      final premiumAnnual = PricingService.getPlan(
        tier: UserTier.premium, 
        term: PlanTerm.annual,
      );
      expect(premiumAnnual.basePrice, 19.99);
      
      // Pro base: 2.99*12*0.8=28.70 → $29.99
      final proAnnual = PricingService.getPlan(
        tier: UserTier.pro, 
        term: PlanTerm.annual,
      );
      expect(proAnnual.basePrice, 29.99);
      
      // Enterprise per-user: 2.00*12*0.8=19.20 → $19.99/user
      final enterpriseAnnual = PricingService.getPlan(
        tier: UserTier.enterprise, 
        term: PlanTerm.annual,
      );
      expect(enterpriseAnnual.basePrice, 19.99);
    });

    test('should calculate correct Africa annual prices', () {
      // Africa Premium: 0.99*12*0.8=9.50 → $9.99
      final africaPremiumAnnual = PricingService.getPlan(
        tier: UserTier.premium, 
        term: PlanTerm.annual,
        region: Region.africa,
      );
      expect(africaPremiumAnnual.basePrice, 9.99);
      
      // Africa Pro: 1.99*12*0.8=19.10 → $19.99
      final africaProAnnual = PricingService.getPlan(
        tier: UserTier.pro, 
        term: PlanTerm.annual,
        region: Region.africa,
      );
      expect(africaProAnnual.basePrice, 19.99);
      
      // Africa Enterprise: 1.00*12*0.8=9.60 → $9.99/user
      final africaEnterpriseAnnual = PricingService.getPlan(
        tier: UserTier.enterprise, 
        term: PlanTerm.annual,
        region: Region.africa,
      );
      expect(africaEnterpriseAnnual.basePrice, 9.99);
    });

    test('should calculate correct lifetime prices', () {
      // Premium base: 1.99*12*3.2=76.42 → $74.99
      final premiumLifetime = PricingService.getPlan(
        tier: UserTier.premium, 
        term: PlanTerm.lifetime,
      );
      expect(premiumLifetime.basePrice, 74.99);
      
      // Pro base: 2.99*12*3.2=114.82 → $114.99
      final proLifetime = PricingService.getPlan(
        tier: UserTier.pro, 
        term: PlanTerm.lifetime,
      );
      expect(proLifetime.basePrice, 114.99);
      
      // Africa Premium: 0.99*12*3.2=38.02 → $37.99
      final africaPremiumLifetime = PricingService.getPlan(
        tier: UserTier.premium, 
        term: PlanTerm.lifetime,
        region: Region.africa,
      );
      expect(africaPremiumLifetime.basePrice, 37.99);
      
      // Africa Pro: 1.99*12*3.2=76.42 → $74.99
      final africaProLifetime = PricingService.getPlan(
        tier: UserTier.pro, 
        term: PlanTerm.lifetime,
        region: Region.africa,
      );
      expect(africaProLifetime.basePrice, 74.99);
    });

    test('should not allow lifetime plans for enterprise tier', () {
      expect(
        () => PricingService.getPlan(
          tier: UserTier.enterprise, 
          term: PlanTerm.lifetime,
        ),
        throwsArgumentError,
      );
    });

    test('should provide correct display prices', () {
      final regularPlan = PricingService.getPlan(
        tier: UserTier.premium, 
        term: PlanTerm.monthly,
      );
      expect(regularPlan.displayPrice, '\$1.99');
      
      final enterprisePlan = PricingService.getPlan(
        tier: UserTier.enterprise, 
        term: PlanTerm.monthly,
      );
      expect(enterprisePlan.displayPrice, '\$2.00/user');
    });

    test('should return correct analytics data', () {
      final analyticsData = PricingService.getPricingForAnalytics(
        tier: UserTier.premium,
        term: PlanTerm.annual,
        region: Region.africa,
      );
      
      expect(analyticsData['tier'], 'premium');
      expect(analyticsData['plan_term'], 'annual');
      expect(analyticsData['region'], 'africa');
      expect(analyticsData['per_user'], false);
      expect(analyticsData['base_price'], 9.99);
      expect(analyticsData['display_price'], '\$9.99');
    });
  });

  group('PricingPlan', () {
    test('should calculate metadata correctly for annual plans', () {
      final plan = PricingService.getPlan(
        tier: UserTier.premium, 
        term: PlanTerm.annual,
      );
      
      final metadata = plan.metadata;
      expect(metadata['discount_pct'], 20);
      expect(metadata['monthly_anchor'], closeTo(1.99, 0.01));
    });

    test('should calculate metadata correctly for lifetime plans', () {
      final plan = PricingService.getPlan(
        tier: UserTier.premium, 
        term: PlanTerm.lifetime,
      );
      
      final metadata = plan.metadata;
      expect(metadata['break_even_years'], closeTo(3.2, 0.1));
    });
  });
}