"use client";

import { useEffect, useMemo, useState } from "react";
import { Check, CreditCard, KeyRound, ShieldCheck } from "lucide-react";
import { siteCopy, type SiteLocale } from "@/lib/site-i18n";

type PlanId = "monthly" | "annual";

const proMonthlyPrice =
  process.env.NEXT_PUBLIC_PRO_MONTHLY_PRICE?.trim() || "3,99 €";
const proAnnualPrice =
  process.env.NEXT_PUBLIC_PRO_ANNUAL_PRICE?.trim() || "29,99 €";
const proMonthlyEquivalent =
  process.env.NEXT_PUBLIC_PRO_MONTHLY_EQUIVALENT?.trim() || "2,50 € / mois";

export function LicenseCheckout({
  initialPlan,
  locale,
}: {
  initialPlan: PlanId;
  locale: SiteLocale;
}) {
  const [plan, setPlan] = useState<PlanId>(initialPlan);
  const [licenseRequestId, setLicenseRequestId] = useState("");
  const copy = siteCopy[locale].license;
  const planLabels = useMemo(
    () => ({
      monthly: {
        title: copy.monthly,
        price: proMonthlyPrice,
        note: copy.monthlyNote,
      },
      annual: {
        title: copy.annual,
        price: proAnnualPrice,
        note: `${copy.recommended} - ${proMonthlyEquivalent}`,
      },
    }),
    [copy],
  );

  useEffect(() => {
    const storedRequestId = localStorage.getItem("punaise_license_request_id");
    const requestId = storedRequestId || crypto.randomUUID();
    localStorage.setItem("punaise_license_request_id", requestId);

    const frame = requestAnimationFrame(() => setLicenseRequestId(requestId));
    return () => cancelAnimationFrame(frame);
  }, []);

  return (
    <section className="grid gap-5 lg:grid-cols-[0.92fr_1.08fr]">
      <div className="rounded-[28px] border border-[#dce8ef] bg-white/88 p-6 shadow-[0_22px_70px_rgba(13,42,70,0.09)] sm:p-8">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-sm font-black text-[#82909c]">{copy.step1}</p>
            <h1 className="mt-2 text-4xl font-black leading-tight tracking-normal text-[#0d2a46]">
              {copy.title}
            </h1>
          </div>
          <span className="rounded-2xl bg-[#fff2d4] p-3 text-[#0d2a46]">
            <KeyRound className="size-6" />
          </span>
        </div>

        <p className="mt-5 text-base font-bold leading-7 text-[#657481]">
          {copy.intro}
        </p>

        <div className="mt-7 rounded-[22px] border border-[#dce8ef] bg-[#fbfaf6] p-4">
          <p className="text-xs font-black uppercase text-[#82909c]">
            {copy.yourKey}
          </p>
          <p className="mt-3 break-all font-mono text-xl font-black tracking-normal text-[#0d2a46]">
            {licenseRequestId
              ? `REQ-${licenseRequestId.slice(0, 8).toUpperCase()}`
              : copy.creating}
          </p>
        </div>

        <ul className="mt-6 grid gap-3 text-sm font-extrabold text-[#607080]">
          {copy.bullets.map((item) => (
            <li className="flex gap-3" key={item}>
              <ShieldCheck className="mt-0.5 size-4 shrink-0 text-[#2f9e44]" />
              {item}
            </li>
          ))}
        </ul>
      </div>

      <form
        action="/api/checkout"
        className="rounded-[28px] bg-[#0d2a46] p-6 text-white shadow-[0_28px_80px_rgba(13,42,70,0.18)] sm:p-8"
        method="post"
      >
        <input name="source" type="hidden" value="license_page" />
        <input name="plan" type="hidden" value={plan} />
        <input name="licenseRequestId" type="hidden" value={licenseRequestId} />
        <input name="lang" type="hidden" value={locale} />

        <p className="text-sm font-black text-[#a9bfce]">{copy.step2}</p>
        <h2 className="mt-2 text-4xl font-black tracking-normal">
          {copy.accessTitle}
        </h2>

        <label className="mt-7 block">
          <span className="text-sm font-black text-[#d7e6ef]">
            {copy.email}
          </span>
          <input
            className="mt-3 min-h-14 w-full rounded-2xl border border-white/15 bg-white px-4 text-base font-bold text-[#0d2a46] outline-none"
            name="email"
            placeholder={copy.emailPlaceholder}
            required
            type="email"
          />
        </label>

        <div className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
          {(Object.keys(planLabels) as PlanId[]).map((planId) => {
            const option = planLabels[planId];
            const isActive = plan === planId;

            return (
              <button
                className={`rounded-[20px] border p-5 text-left ${
                  isActive
                    ? "border-[#ffcf58] bg-[#fff2d4] text-[#0d2a46]"
                    : "border-white/15 bg-white/8 text-white"
                }`}
                key={planId}
                onClick={() => setPlan(planId)}
                type="button"
              >
                <div className="flex items-center justify-between gap-3">
                  <p className="text-sm font-black uppercase">
                    {option.title}
                  </p>
                  {isActive ? <Check className="size-5" /> : null}
                </div>
                <p className="mt-4 text-3xl font-black tracking-normal">
                  {option.price}
                </p>
                <p
                  className={`mt-2 text-xs font-extrabold ${
                    isActive ? "text-[#40566b]" : "text-[#a9bfce]"
                  }`}
                >
                  {option.note}
                </p>
              </button>
            );
          })}
        </div>

        <button className="primary-cta mt-7 w-full" type="submit">
          <CreditCard className="size-5" />
          {copy.submit}
        </button>

        <p className="mt-5 text-sm font-extrabold leading-6 text-[#a9bfce]">
          {copy.stripeNote}
        </p>
      </form>
    </section>
  );
}
