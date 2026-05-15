import Link from "next/link";
import { CheckCircle2, Download, KeyRound } from "lucide-react";
import { issueSignedLicense, type LicensePlan } from "@/lib/license";
import { getStripe, getStripeRequestOptions } from "@/lib/stripe";
import { getSiteLocale, siteCopy, withLocale } from "@/lib/site-i18n";

type MerciPageProps = {
  searchParams: Promise<{
    plan?: string;
    session_id?: string;
    lang?: string;
  }>;
};

export default async function MerciPage({ searchParams }: MerciPageProps) {
  const params = await searchParams;
  const locale = getSiteLocale(params.lang);
  const copy = siteCopy[locale];
  const planLabel =
    params.plan === "monthly" ? copy.merci.planMonthly : copy.merci.planAnnual;
  const licenseKey = await licenseKeyForCheckoutSession(params.session_id);

  return (
    <main className="flex min-h-screen items-center justify-center px-6 py-16">
      <section className="w-full max-w-2xl rounded-[32px] border border-[#dce8ef] bg-white/88 p-8 text-center shadow-[0_28px_80px_rgba(13,42,70,0.10)] sm:p-12">
        <CheckCircle2 className="mx-auto size-14 text-[#2f9e44]" />
        <h1 className="mt-8 text-4xl font-black tracking-normal text-[#0d2a46]">
          {copy.merci.title}
        </h1>
        <p className="mx-auto mt-5 max-w-lg text-lg font-bold leading-8 text-[#657481]">
          {copy.merci.intro.replace("{plan}", planLabel)}
        </p>

        {licenseKey ? (
          <div className="mx-auto mt-7 max-w-lg rounded-[22px] border border-[#dce8ef] bg-[#fbfaf6] p-5 text-left">
            <p className="flex items-center gap-2 text-sm font-black text-[#82909c]">
              <KeyRound className="size-4 text-[#f05a22]" />
              {copy.merci.keyTitle}
            </p>
            <p className="mt-3 break-all font-mono text-lg font-black text-[#0d2a46]">
              {licenseKey}
            </p>
            <p className="mt-3 text-sm font-bold leading-6 text-[#657481]">
              {copy.merci.keyText}
            </p>
          </div>
        ) : null}

        <div className="mt-8 flex flex-col justify-center gap-4 sm:flex-row">
          <a className="primary-cta" href="/api/download">
            <Download className="size-5" />
            {copy.merci.download}
          </a>
          <Link className="secondary-cta" href={withLocale("/", locale)}>
            {copy.merci.back}
          </Link>
        </div>
      </section>
    </main>
  );
}

async function licenseKeyForCheckoutSession(sessionId?: string) {
  const stripe = getStripe();

  if (!stripe || !sessionId) {
    return null;
  }

  try {
    const session = await stripe.checkout.sessions.retrieve(
      sessionId,
      undefined,
      getStripeRequestOptions(),
    );
    const isPaid =
      session.payment_status === "paid" ||
      session.payment_status === "no_payment_required";

    if (!isPaid || session.metadata?.product !== "punaise_pro") {
      return null;
    }

    const plan: LicensePlan =
      session.metadata?.plan === "monthly" ? "monthly" : "annual";

    return issueSignedLicense({
      email: session.customer_details?.email,
      plan,
      requestId: session.metadata?.license_request_id,
      sessionId: session.id,
    });
  } catch {
    return null;
  }
}
