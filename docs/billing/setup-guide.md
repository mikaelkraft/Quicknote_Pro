# RevenueCat & Paystack Integration Setup Guide

This guide covers the setup and configuration of RevenueCat for Android in-app purchases and Paystack for web checkout integration.

## Overview

The billing system is designed with the following architecture:

- **RevenueCat**: Primary billing provider for Android/iOS in-app purchases
- **Paystack**: Web checkout provider for iOS users accessing via web
- **Unified Billing Service**: Coordinator that manages both providers
- **Webhook Service**: Node.js service that bridges Paystack payments to RevenueCat entitlements

## Prerequisites

1. RevenueCat account with configured products
2. Paystack account with API keys
3. Android/iOS app configured in respective stores
4. Node.js environment for webhook service

## 1. RevenueCat Setup

### 1.1 Account Configuration

1. Create a RevenueCat account at [https://app.revenuecat.com](https://app.revenuecat.com)
2. Create a new project for Quicknote Pro
3. Configure Android app:
   - Add your Android package name (`com.quicknote_pro.app`)
   - Upload your Google Play Console service account key
4. Configure iOS app (for future use):
   - Add your iOS bundle ID
   - Configure App Store Connect integration

### 1.2 Product Configuration

Create the following products in RevenueCat:

| Product ID | Type | Description | Price |
|------------|------|-------------|-------|
| `quicknote_premium_monthly` | Subscription | Premium Monthly | $0.99/month |
| `quicknote_pro_monthly` | Subscription | Pro Monthly | $1.99/month |
| `quicknote_premium_lifetime` | Non-consumable | Premium Lifetime | $9.99 |
| `quicknote_pro_lifetime` | Non-consumable | Pro Lifetime | $19.99 |

### 1.3 Entitlements Configuration

Create entitlements in RevenueCat:

- `premium`: Maps to Premium tier features
- `pro`: Maps to Pro tier features  
- `enterprise`: Maps to Enterprise tier features (future)

### 1.4 API Keys

Obtain the following API keys from RevenueCat:

- **Android API Key**: For SDK initialization
- **iOS API Key**: For future iOS implementation
- **REST API Key**: For webhook service integration

## 2. Paystack Setup

### 2.1 Account Configuration

1. Create a Paystack account at [https://paystack.com](https://paystack.com)
2. Complete business verification
3. Configure webhook endpoint

### 2.2 API Keys

Obtain the following keys from Paystack:

- **Public Key**: For frontend payment initialization
- **Secret Key**: For backend webhook verification

### 2.3 Webhook Configuration

Set up webhook endpoint in Paystack dashboard:

- **URL**: `https://your-domain.com/webhook/paystack`
- **Events**: `charge.success`, `charge.failed`, `subscription.create`, `subscription.disable`

## 3. Environment Configuration

### 3.1 Flutter App Configuration

Create environment configuration files:

**Development (.env.dev)**
```env
FEATURE_FLAG_REVENUECAT_ENABLED=true
FEATURE_FLAG_PAYSTACK_ENABLED=true
FEATURE_FLAG_WEB_CHECKOUT_ENABLED=true
FEATURE_FLAG_MOCK_PURCHASES_ENABLED=true
REVENUECAT_API_KEY_ANDROID=your_dev_android_key
PAYSTACK_PUBLIC_KEY=your_dev_public_key
```

**Production (.env.prod)**
```env
FEATURE_FLAG_REVENUECAT_ENABLED=true
FEATURE_FLAG_PAYSTACK_ENABLED=true
FEATURE_FLAG_WEB_CHECKOUT_ENABLED=true
FEATURE_FLAG_MOCK_PURCHASES_ENABLED=false
REVENUECAT_API_KEY_ANDROID=your_prod_android_key
PAYSTACK_PUBLIC_KEY=your_prod_public_key
```

### 3.2 Webhook Service Configuration

Configure the webhook service environment:

```env
PORT=3000
PAYSTACK_SECRET_KEY=your_paystack_secret_key
WEBHOOK_SECRET=your_webhook_secret
REVENUECAT_REST_API_KEY=your_revenuecat_rest_api_key
ALLOWED_ORIGINS=https://yourdomain.com
```

## 4. Implementation Integration

### 4.1 Initialize Billing Service

```dart
import 'package:quicknote_pro/services/billing/unified_billing_service.dart';

// Initialize during app startup
final billingService = UnifiedBillingService.instance;
await billingService.initialize(userId: currentUserId);
```

### 4.2 Purchase Flow

```dart
// Purchase a product
final result = await billingService.purchaseProduct(
  productId: ProductIds.premiumMonthly,
  userEmail: userEmail, // Required for Paystack
);

if (result.success) {
  if (result.provider == BillingProvider.paystack) {
    // Open checkout URL
    final checkoutUrl = result.metadata?['checkout_url'];
    // Handle web checkout flow
  } else {
    // RevenueCat purchase completed
    // Update UI accordingly
  }
}
```

### 4.3 Restore Purchases

```dart
final result = await billingService.restorePurchases();
if (result.success) {
  // Update entitlements in UI
}
```

## 5. Webhook Service Deployment

### 5.1 Local Development

```bash
cd webhook_service
npm install
npm run dev
```

### 5.2 Production Deployment

Deploy to your preferred hosting platform (Heroku, AWS, Google Cloud, etc.):

```bash
# Build and deploy
npm run start
```

### 5.3 SSL Configuration

Ensure your webhook endpoint uses HTTPS for security.

## 6. Testing

### 6.1 Development Testing

1. Enable mock purchases for development:
   ```dart
   FEATURE_FLAG_MOCK_PURCHASES_ENABLED=true
   ```

2. Use RevenueCat sandbox environment

3. Test Paystack with test API keys

### 6.2 Production Testing

1. Test RevenueCat purchases with real Google Play account
2. Test Paystack payments with real payment methods
3. Verify webhook delivery and entitlement granting

## 7. Monitoring and Analytics

### 7.1 RevenueCat Analytics

Monitor subscription metrics in RevenueCat dashboard:
- Active subscriptions
- Churn rate
- Revenue trends

### 7.2 Webhook Monitoring

Monitor webhook service health:
- Response times
- Error rates
- Successful entitlement grants

### 7.3 App Analytics

Track billing events:
- Purchase attempts
- Success/failure rates
- User conversion funnels

## 8. Security Considerations

### 8.1 API Key Management

- Store API keys securely (environment variables, not in code)
- Use different keys for development/production
- Rotate keys regularly

### 8.2 Webhook Security

- Verify webhook signatures
- Use HTTPS for all webhook endpoints
- Implement rate limiting

### 8.3 User Data Protection

- Minimize data collection
- Comply with GDPR/CCPA requirements
- Implement proper data retention policies

## 9. Troubleshooting

### 9.1 Common Issues

**RevenueCat initialization fails**
- Check API key configuration
- Verify package name matches RevenueCat configuration
- Check network connectivity

**Paystack payments fail**
- Verify API keys
- Check webhook endpoint accessibility
- Validate request signatures

**Entitlements not granted**
- Check webhook service logs
- Verify RevenueCat REST API key permissions
- Check user ID mapping

### 9.2 Debug Mode

Enable debug logging:

```dart
BILLING_ENABLE_LOGGING=true
```

### 9.3 Support Contacts

- RevenueCat: [support@revenuecat.com](mailto:support@revenuecat.com)
- Paystack: [support@paystack.com](mailto:support@paystack.com)

## 10. Compliance and Legal

### 10.1 App Store Guidelines

- Follow Google Play billing requirements
- Implement proper subscription management
- Provide clear pricing information

### 10.2 Payment Processing

- Comply with PCI DSS requirements (handled by Paystack)
- Implement proper tax handling
- Follow regional payment regulations

### 10.3 Privacy

- Update privacy policy to include billing data usage
- Implement user consent mechanisms
- Provide data deletion capabilities