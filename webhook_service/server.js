const express = require('express');
const crypto = require('crypto');
const axios = require('axios');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const winston = require('winston');
require('dotenv').config();

// Configuration
const PORT = process.env.PORT || 3000;
const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET;
const REVENUECAT_REST_API_KEY = process.env.REVENUECAT_REST_API_KEY;
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

// Validate required environment variables
if (!PAYSTACK_SECRET_KEY || !WEBHOOK_SECRET || !REVENUECAT_REST_API_KEY) {
    console.error('Missing required environment variables');
    process.exit(1);
}

// Logger configuration
const logger = winston.createLogger({
    level: LOG_LEVEL,
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'paystack-webhook' },
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' }),
        new winston.transports.Console({
            format: winston.format.simple()
        })
    ]
});

// Express app setup
const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || [],
    credentials: true
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP'
});
app.use('/webhook', limiter);

// Raw body parser for webhook signature verification
app.use('/webhook/paystack', express.raw({ type: 'application/json' }));
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        service: 'paystack-webhook'
    });
});

// Paystack webhook handler
app.post('/webhook/paystack', async (req, res) => {
    try {
        const signature = req.headers['x-paystack-signature'];
        const payload = req.body;

        // Verify webhook signature
        if (!verifySignature(payload, signature, WEBHOOK_SECRET)) {
            logger.warn('Invalid webhook signature', { 
                signature: signature?.substring(0, 10) + '...' 
            });
            return res.status(401).json({ error: 'Invalid signature' });
        }

        const event = JSON.parse(payload.toString());
        logger.info('Received Paystack webhook', { 
            event: event.event,
            reference: event.data?.reference 
        });

        // Handle different event types
        switch (event.event) {
            case 'charge.success':
                await handleSuccessfulPayment(event.data);
                break;
            case 'charge.failed':
                await handleFailedPayment(event.data);
                break;
            case 'subscription.create':
                await handleSubscriptionCreated(event.data);
                break;
            case 'subscription.disable':
                await handleSubscriptionDisabled(event.data);
                break;
            default:
                logger.info('Unhandled webhook event', { event: event.event });
        }

        res.status(200).json({ message: 'Webhook processed successfully' });

    } catch (error) {
        logger.error('Webhook processing error', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Verify Paystack webhook signature
function verifySignature(payload, signature, secret) {
    const hash = crypto
        .createHmac('sha512', secret)
        .update(payload)
        .digest('hex');
    return hash === signature;
}

// Handle successful payment
async function handleSuccessfulPayment(paymentData) {
    try {
        const { reference, metadata, amount, currency } = paymentData;
        
        if (!metadata || !metadata.user_id || !metadata.entitlement_id) {
            logger.warn('Missing required metadata in payment', { reference });
            return;
        }

        const { user_id, product_id, entitlement_id } = metadata;

        logger.info('Processing successful payment', {
            reference,
            user_id,
            product_id,
            entitlement_id,
            amount
        });

        // Grant entitlement via RevenueCat
        await grantRevenueCatEntitlement({
            userId: user_id,
            entitlementId: entitlement_id,
            productId: product_id,
            transactionId: reference,
            amount: amount,
            currency: currency
        });

        logger.info('Entitlement granted successfully', {
            reference,
            user_id,
            entitlement_id
        });

    } catch (error) {
        logger.error('Error handling successful payment', error);
        throw error;
    }
}

// Handle failed payment
async function handleFailedPayment(paymentData) {
    const { reference, metadata } = paymentData;
    
    logger.info('Payment failed', {
        reference,
        user_id: metadata?.user_id,
        product_id: metadata?.product_id
    });

    // Could implement retry logic or user notification here
}

// Handle subscription creation
async function handleSubscriptionCreated(subscriptionData) {
    try {
        const { subscription_code, customer, plan } = subscriptionData;
        
        logger.info('Subscription created', {
            subscription_code,
            customer_email: customer.email,
            plan_name: plan.name
        });

        // Handle subscription-specific entitlement logic
        // This would map subscription plans to entitlements

    } catch (error) {
        logger.error('Error handling subscription creation', error);
    }
}

// Handle subscription disabled
async function handleSubscriptionDisabled(subscriptionData) {
    try {
        const { subscription_code, customer } = subscriptionData;
        
        logger.info('Subscription disabled', {
            subscription_code,
            customer_email: customer.email
        });

        // Handle subscription cancellation logic
        // This would revoke entitlements via RevenueCat

    } catch (error) {
        logger.error('Error handling subscription disabled', error);
    }
}

// Grant entitlement via RevenueCat REST API
async function grantRevenueCatEntitlement({ 
    userId, 
    entitlementId, 
    productId, 
    transactionId, 
    amount, 
    currency 
}) {
    try {
        const revenueCatEndpoint = `https://api.revenuecat.com/v1/subscribers/${userId}/entitlements/${entitlementId}/promotional`;
        
        const payload = {
            duration: 'unlimited', // For lifetime purchases
            start_time_ms: Date.now()
        };

        // For subscriptions, we'd use a different approach
        if (productId.includes('monthly')) {
            payload.duration = 'monthly';
        }

        const response = await axios.post(revenueCatEndpoint, payload, {
            headers: {
                'Authorization': `Bearer ${REVENUECAT_REST_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        logger.info('RevenueCat entitlement granted', {
            userId,
            entitlementId,
            status: response.status
        });

        return response.data;

    } catch (error) {
        logger.error('Error granting RevenueCat entitlement', {
            userId,
            entitlementId,
            error: error.response?.data || error.message
        });
        throw error;
    }
}

// Revoke entitlement via RevenueCat REST API
async function revokeRevenueCatEntitlement({ userId, entitlementId }) {
    try {
        const revenueCatEndpoint = `https://api.revenuecat.com/v1/subscribers/${userId}/entitlements/${entitlementId}/revoke_promotional`;
        
        const response = await axios.post(revenueCatEndpoint, {}, {
            headers: {
                'Authorization': `Bearer ${REVENUECAT_REST_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        logger.info('RevenueCat entitlement revoked', {
            userId,
            entitlementId,
            status: response.status
        });

        return response.data;

    } catch (error) {
        logger.error('Error revoking RevenueCat entitlement', {
            userId,
            entitlementId,
            error: error.response?.data || error.message
        });
        throw error;
    }
}

// Error handling middleware
app.use((error, req, res, next) => {
    logger.error('Unhandled error', error);
    res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});

// Start server
const server = app.listen(PORT, () => {
    logger.info(`Webhook service started on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    server.close(() => {
        logger.info('Process terminated');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, shutting down gracefully');
    server.close(() => {
        logger.info('Process terminated');
        process.exit(0);
    });
});

module.exports = app;