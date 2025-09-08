# Paystack to RevenueCat Webhook Bridge

This Node.js service bridges Paystack payments to RevenueCat entitlements, enabling web checkout for iOS users while maintaining centralized subscription management through RevenueCat.

## Features

- **Webhook Verification**: HMAC SHA-512 signature validation
- **Automatic Entitlement Granting**: RevenueCat REST API integration
- **Security**: Rate limiting, CORS, and helmet protection
- **Monitoring**: Comprehensive logging with Winston
- **Error Handling**: Graceful failure handling and retry mechanisms

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
```

Update the following variables:
```env
PAYSTACK_SECRET_KEY=your_paystack_secret_key
WEBHOOK_SECRET=your_webhook_secret
REVENUECAT_REST_API_KEY=your_revenuecat_rest_api_key
```

### 3. Run Development Server
```bash
npm run dev
```

### 4. Test Webhook Endpoint
```bash
curl -X POST http://localhost:3000/webhook/paystack \
  -H "Content-Type: application/json" \
  -H "x-paystack-signature: <signature>" \
  -d '{"event": "charge.success", "data": {...}}'
```

## Deployment

### Heroku
```bash
heroku create quicknote-webhook
heroku config:set PAYSTACK_SECRET_KEY=your_key
heroku config:set WEBHOOK_SECRET=your_secret
heroku config:set REVENUECAT_REST_API_KEY=your_key
git push heroku main
```

### Docker
```bash
docker build -t quicknote-webhook .
docker run -p 3000:3000 --env-file .env quicknote-webhook
```

### AWS Lambda
Use the Serverless framework or AWS CDK for serverless deployment.

## API Endpoints

### Health Check
```
GET /health
```
Returns service health status.

### Paystack Webhook
```
POST /webhook/paystack
```
Handles Paystack webhook events:
- `charge.success`: Grant entitlements
- `charge.failed`: Log failure
- `subscription.create`: Handle subscription
- `subscription.disable`: Revoke entitlements

## Security

### Webhook Signature Verification
The service verifies all incoming webhooks using HMAC SHA-512:

```javascript
const signature = req.headers['x-paystack-signature'];
const isValid = verifySignature(payload, signature, WEBHOOK_SECRET);
```

### Rate Limiting
- 100 requests per 15 minutes per IP
- Configurable via environment variables

### CORS Protection
- Configurable allowed origins
- Credentials support

## Event Handling

### Successful Payment Flow
1. Receive `charge.success` webhook from Paystack
2. Extract metadata (user_id, product_id, entitlement_id)
3. Grant entitlement via RevenueCat REST API
4. Log success/failure

### Subscription Management
1. `subscription.create`: Map subscription to entitlements
2. `subscription.disable`: Revoke entitlements
3. Handle subscription lifecycle events

## Monitoring & Logging

### Log Levels
- `error`: Critical failures
- `warn`: Invalid signatures, missing data
- `info`: Successful operations
- `debug`: Detailed operation logs

### Log Files
- `error.log`: Error-level logs only
- `combined.log`: All log levels
- Console output for development

### Metrics to Monitor
- Webhook processing time
- Success/failure rates
- RevenueCat API response times
- Error frequencies

## Configuration

### Environment Variables
| Variable | Description | Required |
|----------|-------------|----------|
| `PORT` | Server port (default: 3000) | No |
| `PAYSTACK_SECRET_KEY` | Paystack secret key | Yes |
| `WEBHOOK_SECRET` | Webhook verification secret | Yes |
| `REVENUECAT_REST_API_KEY` | RevenueCat REST API key | Yes |
| `ALLOWED_ORIGINS` | CORS allowed origins | No |
| `LOG_LEVEL` | Logging level (default: info) | No |

### Production Considerations
- Use process managers (PM2, systemd)
- Set up SSL/TLS certificates
- Configure reverse proxy (nginx)
- Implement database for persistent logging
- Set up monitoring and alerting

## Testing

### Unit Tests
```bash
npm test
```

### Integration Tests
```bash
npm run test:integration
```

### Manual Testing
Use tools like ngrok for local webhook testing:
```bash
ngrok http 3000
# Update Paystack webhook URL to https://xxx.ngrok.io/webhook/paystack
```

## Troubleshooting

### Common Issues

1. **Invalid Signature**
   - Verify webhook secret matches Paystack configuration
   - Check request body is properly parsed

2. **RevenueCat API Errors**
   - Verify REST API key permissions
   - Check user ID format and entitlement mapping

3. **Missing Metadata**
   - Ensure Paystack payment includes required metadata
   - Validate metadata structure in payment initialization

### Debug Mode
Enable debug logging:
```env
LOG_LEVEL=debug
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit a pull request

## License

MIT License - see LICENSE file for details.