import { NextRequest, NextResponse } from "next/server";
import Stripe from "stripe";
import { getStripe, getStripeRequestOptions } from "@/lib/stripe";

export async function POST(request: NextRequest) {
  const origin = (
    process.env.NEXT_PUBLIC_SITE_URL?.trim() || new URL(request.url).origin
  ).replace(/\/$/, "");
  const unavailableUrl = new URL("/pro-indisponible", origin);
  let formData = new FormData();

  try {
    formData = await request.formData();
  } catch {
    formData = new FormData();
  }
  const plan = formData.get("plan") === "monthly" ? "monthly" : "annual";
  const lang = formData.get("lang") === "en" ? "en" : "";
  const email = String(formData.get("email") || "").trim();
  const licenseRequestId = String(
    formData.get("licenseRequestId") || "",
  ).trim();
  const source = String(formData.get("source") || "landing").trim();

  const stripe = getStripe();
  const priceId =
    plan === "monthly"
      ? process.env.STRIPE_MONTHLY_PRICE_ID?.trim() ||
        process.env.STRIPE_PRICE_ID?.trim()
      : process.env.STRIPE_ANNUAL_PRICE_ID?.trim() ||
        process.env.STRIPE_PRICE_ID?.trim();

  if (!stripe || !priceId) {
    if (lang) {
      unavailableUrl.searchParams.set("lang", lang);
    }
    return NextResponse.redirect(unavailableUrl, {
      status: 303,
    });
  }

  const mode =
    process.env.STRIPE_CHECKOUT_MODE?.trim() === "payment"
      ? "payment"
      : "subscription";
  const metadata = {
    product: "punaise_pro",
    plan,
    license_request_id: licenseRequestId,
    source,
  };
  const successUrl = new URL("/merci", origin);
  successUrl.searchParams.set("session_id", "{CHECKOUT_SESSION_ID}");

  if (plan) {
    successUrl.searchParams.set("plan", plan);
  }

  if (lang) {
    successUrl.searchParams.set("lang", lang);
  }

  const cancelUrl = new URL("/licence", origin);
  cancelUrl.searchParams.set("plan", plan);
  if (lang) {
    cancelUrl.searchParams.set("lang", lang);
  }

  const sessionParams: Stripe.Checkout.SessionCreateParams = {
    mode,
    line_items: [{ price: priceId, quantity: 1 }],
    allow_promotion_codes: true,
    success_url: successUrl.toString(),
    cancel_url: cancelUrl.toString(),
    metadata,
  };

  if (email) {
    sessionParams.customer_email = email;
  }

  if (mode === "subscription") {
    sessionParams.subscription_data = { metadata };
  }

  const session = await stripe.checkout.sessions.create(
    sessionParams,
    getStripeRequestOptions(),
  );

  if (!session.url) {
    if (lang) {
      unavailableUrl.searchParams.set("lang", lang);
    }
    return NextResponse.redirect(unavailableUrl, {
      status: 303,
    });
  }

  return NextResponse.redirect(session.url, { status: 303 });
}
