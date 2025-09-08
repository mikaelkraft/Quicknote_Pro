# Cloudflare Worker Deployment Guide

This guide explains how to deploy the Paystack webhook handler to Cloudflare Workers.

## Prerequisites

- Cloudflare account
- Node.js 16+ installed
- Wrangler CLI installed
- Paystack account with API keys
- RevenueCat account with API keys

## Installation

### 1. Install Wrangler CLI

```bash
npm install -g wrangler
```

### 2. Authenticate with Cloudflare

```bash
wrangler login
```

This will open a browser window to authenticate with your Cloudflare account.

### 3. Configure the Worker

Navigate to the cloudflare-worker directory:

```bash
cd cloudflare-worker
```

### 4. Update wrangler.toml

Edit `wrangler.toml` to match your domain and environment:

```toml
name = "quicknote-paystack-webhook"
main = "paystack-webhook.js"
compatibility_date = "2023-10-30"

# Update with your actual domain
routes = [
  { pattern = "*.yourdomain.com/webhooks/*", zone_name = "yourdomain.com" }
]
```

## Environment Setup

### 1. Set Production Secrets

```bash
# Paystack secret key for webhook verification
wrangler secret put PAYSTACK_SECRET_KEY
# Enter your Paystack secret key when prompted

# RevenueCat API key for subscription updates
wrangler secret put REVENUECAT_API_KEY
# Enter your RevenueCat secret API key when prompted

# Additional webhook secret for extra security
wrangler secret put WEBHOOK_SECRET
# Enter a random string for webhook verification
```

### 2. Set Staging Secrets (Optional)

```bash
wrangler secret put PAYSTACK_SECRET_KEY --env staging
wrangler secret put REVENUECAT_API_KEY --env staging
wrangler secret put WEBHOOK_SECRET --env staging
```

## Deployment

### 1. Deploy to Production

```bash
wrangler publish
```

### 2. Deploy to Staging (Optional)

```bash
wrangler publish --env staging
```

## Verification

### 1. Test Health Endpoint

```bash
curl https://your-worker.your-subdomain.workers.dev/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2023-10-30T10:00:00.000Z",
  "version": "1.0.0"
}
```

### 2. Test Webhook Endpoint

```bash
curl -X POST https://your-worker.your-subdomain.workers.dev/webhooks/paystack \
  -H "Content-Type: application/json" \
  -H "x-paystack-signature: test" \
  -d '{"event": "test", "data": {}}'
```

## Monitoring

### 1. View Logs

```bash
wrangler tail
```

### 2. View Analytics

Visit the Cloudflare dashboard to view worker analytics and performance metrics.

### 3. Set Up Alerts

Configure alerts in Cloudflare dashboard for:
- High error rates
- Slow response times
- Request volume spikes

## Updating the Worker

### 1. Make Changes

Edit `paystack-webhook.js` with your changes.

### 2. Test Locally (Optional)

```bash
wrangler dev
```

### 3. Deploy Updates

```bash
wrangler publish
```

## Custom Domain Setup

### 1. Add Route in wrangler.toml

```toml
routes = [
  { pattern = "api.yourdomain.com/webhooks/*", zone_name = "yourdomain.com" }
]
```

### 2. Update DNS

Add an A record pointing to Cloudflare's IP addresses:
- Name: `api`
- Type: `A`
- Value: `192.0.2.1` (example)

### 3. Update Paystack Webhook URL

In your Paystack dashboard, update the webhook URL to:
`https://api.yourdomain.com/webhooks/paystack`

## Security Considerations

### 1. Signature Verification

The worker automatically verifies Paystack webhook signatures. Never disable this verification.

### 2. Rate Limiting

Consider adding rate limiting:

```javascript
// Add to worker if needed
const rateLimiter = new Map();

function checkRateLimit(ip) {
  const now = Date.now();
  const requests = rateLimiter.get(ip) || [];
  
  // Allow 10 requests per minute
  const validRequests = requests.filter(time => now - time < 60000);
  
  if (validRequests.length >= 10) {
    return false;
  }
  
  validRequests.push(now);
  rateLimiter.set(ip, validRequests);
  return true;
}
```

### 3. IP Whitelisting

Optionally whitelist Paystack's IP ranges:

```javascript
const PAYSTACK_IPS = [
  '52.31.139.75',
  '52.49.173.169',
  '52.214.14.220'
];

function isValidIP(ip) {
  return PAYSTACK_IPS.includes(ip);
}
```

## Troubleshooting

### Common Issues

1. **Worker not receiving webhooks**
   - Check webhook URL in Paystack dashboard
   - Verify route configuration in wrangler.toml
   - Check Cloudflare DNS settings

2. **Signature verification fails**
   - Verify PAYSTACK_SECRET_KEY is correct
   - Check webhook secret in Paystack dashboard
   - Ensure raw body is used for verification

3. **RevenueCat API calls fail**
   - Verify REVENUECAT_API_KEY is correct
   - Check RevenueCat API documentation for changes
   - Review worker logs for specific error messages

### Debugging

1. **Enable detailed logging**
```javascript
console.log('Webhook body:', body);
console.log('Signature:', signature);
console.log('Event data:', JSON.stringify(data, null, 2));
```

2. **Test webhook locally**
```bash
wrangler dev --local
curl -X POST http://localhost:8787/webhooks/paystack -d '...'
```

3. **Check worker logs**
```bash
wrangler tail --format pretty
```

## Maintenance

### Regular Tasks

1. **Monitor error rates** - Check Cloudflare dashboard weekly
2. **Review logs** - Look for unusual patterns or errors
3. **Update dependencies** - Keep worker code updated
4. **Rotate secrets** - Update API keys quarterly

### Performance Optimization

1. **Enable compression** - Cloudflare handles this automatically
2. **Use caching** - Cache static responses where appropriate
3. **Minimize external API calls** - Batch operations when possible

## Support

For issues with:
- **Cloudflare Workers**: Cloudflare support or community forums
- **Paystack Integration**: Paystack documentation and support
- **RevenueCat Integration**: RevenueCat documentation and support