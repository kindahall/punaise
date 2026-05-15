import Stripe from "stripe";

let stripe: Stripe | null = null;

export function getStripe() {
  const secretKey = process.env.STRIPE_SECRET_KEY?.trim();

  if (!secretKey) {
    return null;
  }

  if (!stripe) {
    stripe = new Stripe(secretKey, {
      apiVersion: "2026-04-22.dahlia",
      appInfo: {
        name: "Punaise Landing",
        version: "0.1.6",
      },
    });
  }

  return stripe;
}
