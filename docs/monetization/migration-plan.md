# Monetization v1 Migration and Backfill Plan

## Overview

This document outlines the migration strategy for consolidating monetization features into a single cohesive system while maintaining backwards compatibility and data integrity.

## Migration Strategy

### Phase 1: Feature Flag Rollout (Week 1)
- Deploy feature flags configuration system
- Enable flags gradually for different user cohorts
- Monitor system stability and performance
- Rollback capability through environment variables

### Phase 2: A/B Testing Infrastructure (Week 2)
- Deploy A/B testing service alongside existing systems
- Run parallel experiments to validate new infrastructure
- Migrate existing experiments to new framework
- Validate experiment assignment consistency

### Phase 3: Service Integration (Week 3-4)
- Integrate feature flags with existing monetization services
- Update analytics tracking to use new event schema
- Consolidate ad management through centralized service
- Migrate trial and subscription management

### Phase 4: Data Consolidation (Week 5)
- Migrate user preferences and settings
- Consolidate usage tracking data
- Update billing and subscription records
- Validate data integrity across all systems

## Data Model Changes

### New Storage Keys
```
# Feature Flags
- monetization_config_version: int
- monetization_migration_status: bool

# A/B Testing
- ab_experiments: string (JSON)
- ab_user_groups: string (comma-separated)

# Enhanced Analytics
- analytics_event_queue: string (JSON array)
- analytics_user_consent: bool

# Consolidated Settings
- monetization_settings_v2: string (JSON)
```

### Legacy Key Migration
```
# Old → New
user_tier → monetization_user_tier
upgrade_prompt_count → monetization_upgrade_prompts
ads_enabled → monetization_ads_enabled
trial_data → monetization_trial_info
```

## Backwards Compatibility

### Data Access Layer
```dart
class MigrationHelper {
  static Future<T?> getLegacyValue<T>(String legacyKey, String newKey) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try new key first
    final newValue = prefs.get(newKey);
    if (newValue != null) return newValue as T;
    
    // Fall back to legacy key
    final legacyValue = prefs.get(legacyKey);
    if (legacyValue != null) {
      // Migrate to new key
      await _migrateLegacyValue(legacyKey, newKey, legacyValue);
      return legacyValue as T;
    }
    
    return null;
  }
}
```

### API Compatibility
- Maintain existing method signatures for 2 release cycles
- Add `@deprecated` annotations with migration instructions
- Provide wrapper methods that delegate to new implementations

## Backfill Procedures

### User Tier Migration
```sql
-- Example SQL for backend data migration
UPDATE users 
SET subscription_tier_v2 = 
  CASE subscription_tier
    WHEN 'basic' THEN 'free'
    WHEN 'plus' THEN 'premium'
    WHEN 'professional' THEN 'pro'
    ELSE subscription_tier
  END
WHERE subscription_tier_v2 IS NULL;
```

### Usage Analytics Backfill
```dart
Future<void> backfillUsageData() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Migrate old usage counters
  final legacyKeys = prefs.getKeys()
    .where((key) => key.startsWith('usage_'))
    .toList();
    
  for (final legacyKey in legacyKeys) {
    final value = prefs.getInt(legacyKey);
    if (value != null) {
      final newKey = 'usage_count_${legacyKey.substring(6)}';
      await prefs.setInt(newKey, value);
    }
  }
}
```

### Trial Data Migration
```dart
Future<void> migrateTrialData() async {
  final prefs = await SharedPreferences.getInstance();
  final legacyTrialData = prefs.getString('trial_data');
  
  if (legacyTrialData != null) {
    try {
      final oldTrial = json.decode(legacyTrialData);
      
      // Convert to new format
      final newTrial = TrialInfo(
        tier: UserTier.values.firstWhere(
          (t) => t.name == oldTrial['tier'],
          orElse: () => UserTier.premium,
        ),
        type: TrialType.standard,
        startedAt: DateTime.parse(oldTrial['started_at']),
        expiresAt: DateTime.parse(oldTrial['expires_at']),
        originalDurationDays: oldTrial['duration'] ?? 7,
      );
      
      await prefs.setString('current_trial', json.encode(newTrial.toJson()));
      await prefs.remove('trial_data'); // Clean up legacy
    } catch (e) {
      // Log error but don't fail migration
      print('Trial migration error: $e');
    }
  }
}
```

## Rollback Strategy

### Immediate Rollback (< 5 minutes)
1. Set kill switch environment variable: `FEATURE_FLAG_KILL_SWITCH_ACTIVE=true`
2. Restart application servers
3. Monitor error rates and user impact

### Partial Rollback (5-30 minutes)
1. Disable specific features via feature flags
2. Revert percentage rollouts to 0%
3. Switch A/B experiments to control groups

### Full Rollback (30+ minutes)
1. Deploy previous application version
2. Restore database from backup if needed
3. Run data consistency checks

## Testing Strategy

### Pre-Migration Testing
- [ ] Unit tests for all migration functions
- [ ] Integration tests for data compatibility
- [ ] Load testing with migration scenarios
- [ ] Manual testing of upgrade/downgrade flows

### Migration Validation
- [ ] Data integrity checks after each phase
- [ ] User experience validation
- [ ] Performance impact assessment
- [ ] Analytics data continuity verification

### Post-Migration Monitoring
- [ ] Error rate monitoring for 48 hours
- [ ] User engagement metrics comparison
- [ ] Revenue impact analysis
- [ ] Support ticket volume tracking

## Risk Mitigation

### High-Risk Scenarios
1. **Data Loss**: Complete database backups before migration
2. **Performance Degradation**: Gradual rollout with performance monitoring
3. **Revenue Impact**: Quick rollback procedures for billing issues
4. **User Experience**: Canary deployments to limited user base

### Monitoring Alerts
```yaml
# Example alert configuration
alerts:
  - name: "Migration Error Rate"
    condition: "error_rate > 1%"
    action: "trigger_rollback"
  
  - name: "Revenue Drop"
    condition: "revenue < 90% of baseline"
    action: "notify_team"
  
  - name: "Performance Degradation"
    condition: "response_time > 2x baseline"
    action: "scale_infrastructure"
```

## Success Metrics

### Technical Metrics
- Migration completion rate: > 99.5%
- Data integrity validation: 100% pass rate
- System availability: > 99.9% during migration
- Performance impact: < 10% degradation

### Business Metrics
- Revenue continuity: < 5% impact during migration week
- User retention: No significant drop in DAU/MAU
- Support ticket volume: < 20% increase
- Feature adoption: Baseline maintained or improved

## Timeline

### Week 1: Infrastructure Deployment
- Monday: Deploy feature flags system
- Tuesday: Enable for 10% of users
- Wednesday: Scale to 50% of users
- Thursday: Full rollout if stable
- Friday: Monitoring and optimization

### Week 2: A/B Testing Rollout
- Monday: Deploy A/B testing infrastructure
- Tuesday: Migrate first experiment (paywall headlines)
- Wednesday: Migrate ad timing experiments
- Thursday: Migrate pricing experiments
- Friday: Validate all experiments running

### Week 3-4: Service Integration
- Week 3: Analytics and monetization service updates
- Week 4: Ads service integration and data migration

### Week 5: Data Consolidation
- Monday-Tuesday: User data migration
- Wednesday-Thursday: Analytics data backfill
- Friday: Final validation and cleanup

## Communication Plan

### Internal Communication
- Daily standup updates during migration week
- Slack alerts for all migration milestones
- Post-migration retrospective meeting

### User Communication
- No user-facing communication needed (transparent migration)
- Support team briefing on potential issues
- Documentation updates for any changed behaviors

## Contingency Plans

### Plan A: Delayed Migration
If issues arise, delay next phase by 1 week and investigate

### Plan B: Partial Feature Rollback
Disable problematic features while keeping stable ones active

### Plan C: Full System Rollback
Complete rollback to previous version with data restoration

## Post-Migration Cleanup

### Phase 1 (1 week after migration)
- Remove deprecated code paths
- Clean up legacy storage keys
- Update documentation

### Phase 2 (1 month after migration)
- Remove compatibility layers
- Optimize new system performance
- Conduct full system audit

### Phase 3 (3 months after migration)
- Remove all legacy code
- Finalize new architecture
- Plan next iteration improvements