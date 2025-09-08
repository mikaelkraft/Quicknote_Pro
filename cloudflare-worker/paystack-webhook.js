/**
 * Cloudflare Worker for handling Paystack webhooks
 * 
 * This worker processes webhook events from Paystack payment provider
 * and integrates with RevenueCat for subscription management.
 */

// Environment variables needed:
// PAYSTACK_SECRET_KEY - Paystack secret key for verification
// REVENUECAT_API_KEY - RevenueCat API key for subscription updates
// WEBHOOK_SECRET - Secret for webhook verification

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

/**
 * Handle incoming requests
 */
async function handleRequest(request) {
  // Only allow POST requests to webhook endpoint
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { 
      status: 405,
      headers: { 'Allow': 'POST' }
    })
  }

  const url = new URL(request.url)
  
  // Route to appropriate handler
  switch (url.pathname) {
    case '/webhooks/paystack':
      return handlePaystackWebhook(request)
    case '/health':
      return handleHealthCheck()
    default:
      return new Response('Not found', { status: 404 })
  }
}

/**
 * Handle Paystack webhook events
 */
async function handlePaystackWebhook(request) {
  try {
    // Verify webhook signature
    const signature = request.headers.get('x-paystack-signature')
    if (!signature) {
      return new Response('Missing signature', { status: 400 })
    }

    const body = await request.text()
    if (!await verifyPaystackSignature(body, signature)) {
      return new Response('Invalid signature', { status: 401 })
    }

    // Parse webhook data
    const data = JSON.parse(body)
    const { event, data: eventData } = data

    console.log(`Received Paystack webhook: ${event}`)

    // Process based on event type
    switch (event) {
      case 'subscription.create':
        await handleSubscriptionCreated(eventData)
        break
      case 'subscription.disable':
        await handleSubscriptionCancelled(eventData)
        break
      case 'invoice.payment_failed':
        await handlePaymentFailed(eventData)
        break
      case 'charge.success':
        await handleChargeSuccess(eventData)
        break
      case 'subscription.not_renew':
        await handleSubscriptionWillNotRenew(eventData)
        break
      default:
        console.log(`Unhandled event type: ${event}`)
    }

    // Log successful processing
    await logWebhookEvent({
      event,
      customer_code: eventData.customer?.customer_code,
      subscription_code: eventData.subscription_code,
      status: 'processed',
      timestamp: new Date().toISOString()
    })

    return new Response('OK', { status: 200 })

  } catch (error) {
    console.error('Webhook processing error:', error)
    
    // Log error
    await logWebhookEvent({
      event: 'error',
      error: error.message,
      status: 'failed',
      timestamp: new Date().toISOString()
    })

    return new Response('Internal server error', { status: 500 })
  }
}

/**
 * Verify Paystack webhook signature
 */
async function verifyPaystackSignature(body, signature) {
  const secretKey = PAYSTACK_SECRET_KEY
  if (!secretKey) {
    throw new Error('PAYSTACK_SECRET_KEY not configured')
  }

  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secretKey),
    { name: 'HMAC', hash: 'SHA-512' },
    false,
    ['sign']
  )

  const signatureBytes = await crypto.subtle.sign('HMAC', key, encoder.encode(body))
  const computedSignature = Array.from(new Uint8Array(signatureBytes))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')

  return computedSignature === signature
}

/**
 * Handle subscription creation
 */
async function handleSubscriptionCreated(data) {
  const { customer, plan, subscription_code, status } = data
  
  console.log(`Subscription created: ${subscription_code} for customer ${customer.customer_code}`)

  // Map Paystack plan to RevenueCat entitlement
  const entitlement = mapPlanToEntitlement(plan.plan_code)
  
  if (entitlement) {
    await updateRevenueCatSubscription({
      customer_id: customer.customer_code,
      subscription_id: subscription_code,
      entitlement,
      status: 'active',
      expires_at: data.next_payment_date
    })
  }

  // Send confirmation email or notification
  await sendSubscriptionConfirmation(customer, plan)
}

/**
 * Handle subscription cancellation
 */
async function handleSubscriptionCancelled(data) {
  const { customer, subscription_code } = data
  
  console.log(`Subscription cancelled: ${subscription_code}`)

  await updateRevenueCatSubscription({
    customer_id: customer.customer_code,
    subscription_id: subscription_code,
    status: 'cancelled'
  })

  // Send cancellation notification
  await sendSubscriptionCancellation(customer)
}

/**
 * Handle payment failure
 */
async function handlePaymentFailed(data) {
  const { customer, subscription } = data
  
  console.log(`Payment failed for subscription: ${subscription.subscription_code}`)

  // Update subscription status
  await updateRevenueCatSubscription({
    customer_id: customer.customer_code,
    subscription_id: subscription.subscription_code,
    status: 'past_due'
  })

  // Send payment retry notification
  await sendPaymentFailedNotification(customer, subscription)
}

/**
 * Handle successful charge
 */
async function handleChargeSuccess(data) {
  const { customer, plan } = data
  
  console.log(`Charge successful for customer: ${customer.customer_code}`)

  // For one-time purchases (lifetime plans)
  if (plan && plan.plan_code.includes('lifetime')) {
    const entitlement = mapPlanToEntitlement(plan.plan_code)
    
    await updateRevenueCatSubscription({
      customer_id: customer.customer_code,
      entitlement,
      status: 'active',
      expires_at: null // Lifetime access
    })
  }
}

/**
 * Handle subscription will not renew
 */
async function handleSubscriptionWillNotRenew(data) {
  const { customer, subscription_code } = data
  
  console.log(`Subscription will not renew: ${subscription_code}`)

  await updateRevenueCatSubscription({
    customer_id: customer.customer_code,
    subscription_id: subscription_code,
    status: 'will_not_renew'
  })
}

/**
 * Map Paystack plan code to RevenueCat entitlement
 */
function mapPlanToEntitlement(planCode) {
  const entitlementMap = {
    'quicknote_premium_monthly': 'premium',
    'quicknote_premium_annual': 'premium',
    'quicknote_premium_lifetime': 'premium',
    'quicknote_pro_monthly': 'pro',
    'quicknote_pro_annual': 'pro', 
    'quicknote_pro_lifetime': 'pro',
    'quicknote_enterprise_monthly': 'enterprise',
    'quicknote_enterprise_annual': 'enterprise'
  }
  
  return entitlementMap[planCode] || null
}

/**
 * Update RevenueCat subscription status
 */
async function updateRevenueCatSubscription(params) {
  const { customer_id, subscription_id, entitlement, status, expires_at } = params
  
  // RevenueCat API integration
  const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${customer_id}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${REVENUECAT_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      subscriber_id: customer_id,
      subscription_id,
      entitlement,
      status,
      expires_at
    })
  })

  if (!response.ok) {
    throw new Error(`RevenueCat API error: ${response.status}`)
  }

  console.log(`Updated RevenueCat subscription for customer: ${customer_id}`)
}

/**
 * Send subscription confirmation
 */
async function sendSubscriptionConfirmation(customer, plan) {
  // Implementation depends on your email service
  console.log(`Sending confirmation to ${customer.email} for plan ${plan.name}`)
  
  // TODO: Integrate with email service (SendGrid, Mailgun, etc.)
}

/**
 * Send subscription cancellation notification
 */
async function sendSubscriptionCancellation(customer) {
  console.log(`Sending cancellation notice to ${customer.email}`)
  
  // TODO: Integrate with email service
}

/**
 * Send payment failed notification
 */
async function sendPaymentFailedNotification(customer, subscription) {
  console.log(`Sending payment failed notice to ${customer.email}`)
  
  // TODO: Integrate with email service
}

/**
 * Log webhook events for monitoring
 */
async function logWebhookEvent(eventData) {
  // Log to KV storage, analytics service, or external logging
  console.log('Webhook event:', JSON.stringify(eventData))
  
  // TODO: Store in KV storage for monitoring dashboard
  // await WEBHOOK_LOGS.put(
  //   `${Date.now()}-${eventData.event}`,
  //   JSON.stringify(eventData),
  //   { expirationTtl: 86400 * 30 } // 30 days
  // )
}

/**
 * Health check endpoint
 */
function handleHealthCheck() {
  return new Response(JSON.stringify({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  }), {
    headers: { 'Content-Type': 'application/json' }
  })
}