# Payment Setup and Integration Guide

This guide provides comprehensive instructions for setting up payment processing using Paystack and RevenueCat for Quicknote Pro's monetization system.

## Overview

Quicknote Pro uses a dual payment provider setup:
- **Paystack**: Primary payment processor for African markets
- **RevenueCat**: Subscription management and entitlement system
- **Cloudflare Workers**: Webhook processing for payment events

## Architecture

```
User Purchase Flow:
Mobile App → RevenueCat SDK → App Store/Google Play → RevenueCat
Web App → Paystack → Cloudflare Worker → RevenueCat

Entitlement Flow:
App → RevenueCat → Subscription Status → Feature Access
```

## Prerequisites

Before setting up payment processing, ensure you have:

1. **Paystack Account** (for African/international payments)
2. **RevenueCat Account** (for subscription management)
3. **Cloudflare Account** (for webhook processing)
4. **Apple Developer Account** (for iOS App Store)
5. **Google Play Console Account** (for Android Play Store)

## 1. Paystack Setup

### 1.1 Create Paystack Account

1. Visit [Paystack](https://paystack.com) and create an account
2. Complete business verification process
3. Get your API keys from the dashboard

### 1.2 Configure Payment Plans

Create the following plans in your Paystack dashboard:

```json
{
  "plans": [
    {
      "name": "Premium Monthly",
      "plan_code": "quicknote_premium_monthly",
      "amount": 199900,
      "interval": "monthly",
      "currency": "NGN"
    },
    {
      "name": "Premium Annual",
      "plan_code": "quicknote_premium_annual", 
      "amount": 1999900,
      "interval": "annually",
      "currency": "NGN"
    },
    {
      "name": "Pro Monthly",
      "plan_code": "quicknote_pro_monthly",
      "amount": 299900,
      "interval": "monthly", 
      "currency": "NGN"
    },
    {
      "name": "Pro Annual",
      "plan_code": "quicknote_pro_annual",
      "amount": 2999900,
      "interval": "annually",
      "currency": "NGN"
    },
    {
      "name": "Enterprise Monthly",
      "plan_code": "quicknote_enterprise_monthly",
      "amount": 200000,
      "interval": "monthly",
      "currency": "NGN"
    },
    {
      "name": "Enterprise Annual", 
      "plan_code": "quicknote_enterprise_annual",
      "amount": 2000000,
      "interval": "annually",
      "currency": "NGN"
    }
  ]
}
```

### 1.3 Set Up Webhooks

1. In Paystack dashboard, go to Settings → Webhooks
2. Add webhook URL: `https://your-worker.your-subdomain.workers.dev/webhooks/paystack`
3. Select these events:
   - `subscription.create`
   - `subscription.disable` 
   - `invoice.payment_failed`
   - `charge.success`
   - `subscription.not_renew`

### 1.4 API Keys

Store these securely:
- **Public Key**: `pk_test_...` (test) / `pk_live_...` (live)
- **Secret Key**: `sk_test_...` (test) / `sk_live_...` (live)

## 2. RevenueCat Setup

### 2.1 Create RevenueCat Project

1. Visit [RevenueCat](https://revenuecat.com) and create account
2. Create new project for Quicknote Pro
3. Configure your platforms (iOS, Android, Web)

### 2.2 Configure Products

Create these products in RevenueCat:

```json
{
  "products": [
    {
      "identifier": "quicknote_premium_monthly",
      "type": "subscription",
      "duration": "P1M"
    },
    {
      "identifier": "quicknote_premium_annual", 
      "type": "subscription",
      "duration": "P1Y"
    },
    {
      "identifier": "quicknote_premium_lifetime",
      "type": "non_consumable"
    },
    {
      "identifier": "quicknote_pro_monthly",
      "type": "subscription", 
      "duration": "P1M"
    },
    {
      "identifier": "quicknote_pro_annual",
      "type": "subscription",
      "duration": "P1Y" 
    },
    {
      "identifier": "quicknote_pro_lifetime",
      "type": "non_consumable"
    },
    {
      "identifier": "quicknote_enterprise_monthly",
      "type": "subscription",
      "duration": "P1M"
    },
    {
      "identifier": "quicknote_enterprise_annual",
      "type": "subscription", 
      "duration": "P1Y"
    }
  ]
}
```

### 2.3 Configure Entitlements

Set up these entitlements:

```json
{
  "entitlements": [
    {
      "identifier": "premium",
      "products": [
        "quicknote_premium_monthly",
        "quicknote_premium_annual", 
        "quicknote_premium_lifetime"
      ]
    },
    {
      "identifier": "pro",
      "products": [
        "quicknote_pro_monthly",
        "quicknote_pro_annual",
        "quicknote_pro_lifetime"
      ]
    },
    {
      "identifier": "enterprise", 
      "products": [
        "quicknote_enterprise_monthly",
        "quicknote_enterprise_annual"
      ]
    }
  ]
}
```

### 2.4 API Keys

Get your RevenueCat API keys:
- **Public SDK Key**: For mobile/web SDK
- **Secret API Key**: For server-side operations

## 3. Cloudflare Worker Setup

### 3.1 Deploy Worker

1. Install Wrangler CLI:
```bash
npm install -g wrangler
```

2. Authenticate with Cloudflare:
```bash
wrangler login
```

3. Deploy the worker:
```bash
cd cloudflare-worker
wrangler publish
```

### 3.2 Configure Environment Variables

Set these in Cloudflare dashboard:

```bash
# Production
wrangler secret put PAYSTACK_SECRET_KEY
wrangler secret put REVENUECAT_API_KEY
wrangler secret put WEBHOOK_SECRET

# Staging  
wrangler secret put PAYSTACK_SECRET_KEY --env staging
wrangler secret put REVENUECAT_API_KEY --env staging
wrangler secret put WEBHOOK_SECRET --env staging
```

### 3.3 Custom Domain (Optional)

1. Add custom domain in Cloudflare dashboard
2. Update webhook URL in Paystack to use custom domain
3. Update wrangler.toml routes configuration

## 4. Mobile App Integration

### 4.1 iOS Setup

1. Add RevenueCat SDK to iOS project:
```swift
import RevenueCat

// Configure in AppDelegate
Purchases.configure(withAPIKey: "your_public_sdk_key")
```

2. Configure App Store Connect:
   - Create in-app purchases matching product IDs
   - Set up subscription groups
   - Configure pricing for different regions

### 4.2 Android Setup

1. Add RevenueCat SDK to Android project:
```kotlin
import com.revenuecat.purchases.Purchases

// Configure in Application class
Purchases.configure(this, "your_public_sdk_key")
```

2. Configure Google Play Console:
   - Create subscription products
   - Set up billing
   - Configure regional pricing

### 4.3 Flutter Integration

Update your Flutter app:

```yaml
# pubspec.yaml
dependencies:
  purchases_flutter: ^4.0.0
```

```dart
// Initialize RevenueCat
await Purchases.configure(PurchasesConfiguration("your_public_sdk_key"));

// Make purchase
try {
  CustomerInfo customerInfo = await Purchases.purchaseProduct(product);
  // Handle successful purchase
} catch (e) {
  // Handle error
}
```

## 5. Web Integration

### 5.1 Paystack Integration

```javascript
// Initialize Paystack
const paystack = PaystackPop.setup({
  key: 'your_public_key',
  email: 'customer@email.com',
  amount: 199900, // Amount in kobo
  plan: 'quicknote_premium_monthly',
  callback: function(response) {
    // Handle successful payment
    console.log('Payment complete! Reference: ' + response.reference);
  },
  onClose: function() {
    // Handle payment closure
    console.log('Payment window closed.');
  }
});

paystack.openIframe();
```

### 5.2 RevenueCat Web SDK

```javascript
// Configure RevenueCat for web
import Purchases from '@revenuecat/purchases-js';

await Purchases.configure({
  apiKey: "your_public_sdk_key",
});

// Check subscription status
const customerInfo = await Purchases.getCustomerInfo();
if (customerInfo.entitlements.active.premium) {
  // User has premium access
}
```

## 6. Testing

### 6.1 Test Environment Setup

1. **Paystack Test Mode**:
   - Use test API keys
   - Use test card numbers: `4084084084084081`

2. **RevenueCat Sandbox**:
   - Enable sandbox mode in dashboard
   - Use sandbox builds for testing

3. **Cloudflare Worker Testing**:
   - Deploy to staging environment
   - Test webhook endpoints using curl or Postman

### 6.2 Test Scenarios

Test these scenarios:

1. **Successful Subscription**:
   - Subscribe via mobile app
   - Verify entitlement activation
   - Check webhook processing

2. **Failed Payment**:
   - Simulate failed payment
   - Verify grace period handling
   - Test retry notifications

3. **Subscription Cancellation**:
   - Cancel subscription
   - Verify access revocation
   - Test cancellation notifications

4. **Webhook Failures**:
   - Simulate webhook endpoint downtime
   - Verify retry mechanisms
   - Check error logging

## 7. Monitoring and Analytics

### 7.1 Key Metrics to Track

- **Conversion Rates**: Free to paid conversion
- **Churn Rate**: Monthly/annual subscription cancellations
- **Revenue**: Monthly recurring revenue (MRR)
- **Geographic Distribution**: Revenue by region
- **Plan Popularity**: Most/least popular subscription tiers

### 7.2 Monitoring Setup

1. **RevenueCat Dashboard**: Monitor subscription metrics
2. **Paystack Dashboard**: Track payment success rates
3. **Cloudflare Analytics**: Monitor worker performance
4. **Custom Analytics**: Integrate with your analytics platform

### 7.3 Alerting

Set up alerts for:
- High webhook failure rates
- Significant drop in conversion rates
- Payment processor downtime
- Unusual churn patterns

## 8. Security Considerations

### 8.1 API Key Management

- Store API keys securely (environment variables)
- Rotate keys regularly
- Use different keys for different environments
- Never commit keys to version control

### 8.2 Webhook Security

- Always verify webhook signatures
- Use HTTPS endpoints only
- Implement rate limiting
- Log all webhook events for auditing

### 8.3 Customer Data

- Comply with GDPR/local privacy laws
- Encrypt sensitive customer data
- Implement data retention policies
- Provide customer data export/deletion

## 9. Troubleshooting

### 9.1 Common Issues

**Issue**: Webhook not receiving events
- Check webhook URL configuration
- Verify SSL certificate
- Check Cloudflare Worker logs

**Issue**: Subscription not activating
- Verify product ID mapping
- Check RevenueCat entitlement configuration
- Review webhook processing logs

**Issue**: Payment failures
- Check Paystack dashboard for error details
- Verify customer payment method
- Review regional payment restrictions

### 9.2 Support Contacts

- **Paystack Support**: support@paystack.com
- **RevenueCat Support**: support@revenuecat.com
- **Cloudflare Support**: Via dashboard support tickets

## 10. Deployment Checklist

### Pre-Production

- [ ] All test scenarios pass
- [ ] Webhook endpoints tested
- [ ] API keys configured for production
- [ ] Monitoring and alerting set up
- [ ] Documentation reviewed and updated

### Production Deployment

- [ ] Switch to production API keys
- [ ] Update webhook URLs to production
- [ ] Deploy Cloudflare Worker to production
- [ ] Update mobile app store configurations
- [ ] Monitor initial transactions closely

### Post-Deployment

- [ ] Verify first production transactions
- [ ] Check webhook processing
- [ ] Monitor error rates
- [ ] Validate entitlement flows
- [ ] Customer support ready for payment issues

## Conclusion

This payment setup provides a robust foundation for Quicknote Pro's monetization strategy. The combination of Paystack, RevenueCat, and Cloudflare Workers ensures reliable payment processing, subscription management, and webhook handling across all platforms.

For additional support or questions, refer to the individual service documentation or contact the respective support teams.