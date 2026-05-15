"use client";

import { useEffect, useMemo, useState, type KeyboardEvent } from "react";
import {
  Check,
  CreditCard,
  Download,
  Infinity,
  Pin,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import { siteCopy, type SiteLocale, withLocale } from "@/lib/site-i18n";

type PlanId = "gratuit" | "pro";

const proMonthlyPrice =
  process.env.NEXT_PUBLIC_PRO_MONTHLY_PRICE?.trim() || "3,99 €";
const proAnnualPrice =
  process.env.NEXT_PUBLIC_PRO_ANNUAL_PRICE?.trim() || "29,99 €";
const proMonthlyEquivalent =
  process.env.NEXT_PUBLIC_PRO_MONTHLY_EQUIVALENT?.trim() || "2,50 € / mois";

export function PricingTabs({ locale }: { locale: SiteLocale }) {
  const [activePlan, setActivePlan] = useState<PlanId>("gratuit");
  const copy = siteCopy[locale].pricing;
  const plans = useMemo(
    () => ({
      gratuit: {
        title: copy.plans.gratuit.title,
        eyebrow: copy.directDownload,
        price: copy.plans.gratuit.price,
        priceNote: copy.try,
        icon: Pin,
        lines: copy.plans.gratuit.lines,
      },
      pro: {
        title: copy.plans.pro.title,
        eyebrow: copy.stripe,
        price: `${proAnnualPrice} / ${copy.annualPrice}`,
        priceNote: `${siteCopy[locale].home.equivalentPrefix} ${proMonthlyEquivalent}`,
        icon: Infinity,
        lines: copy.plans.pro.lines,
      },
    }),
    [copy, locale],
  );

  useEffect(() => {
    function syncFromHash() {
      if (window.location.hash === "#pro") {
        setActivePlan("pro");
      }

      if (
        window.location.hash === "#gratuit" ||
        window.location.hash === "#tarifs"
      ) {
        setActivePlan("gratuit");
      }
    }

    syncFromHash();
    window.addEventListener("hashchange", syncFromHash);
    return () => window.removeEventListener("hashchange", syncFromHash);
  }, []);

  function selectPlan(plan: PlanId) {
    setActivePlan(plan);
    history.replaceState(
      null,
      "",
      `${window.location.pathname}${window.location.search}#${plan}`,
    );
  }

  function onKeyDown(event: KeyboardEvent<HTMLButtonElement>, plan: PlanId) {
    if (event.key === "ArrowRight" || event.key === "ArrowLeft") {
      event.preventDefault();
      selectPlan(plan === "gratuit" ? "pro" : "gratuit");
    }
  }

  const active = plans[activePlan];
  const ActiveIcon = active.icon;

  return (
    <section aria-label={copy.aria} className="mt-20 max-w-[760px]" id="tarifs">
      <div
        aria-label={copy.choose}
        className="inline-flex rounded-[22px] border border-[#dce8ef] bg-white/84 p-1.5 shadow-[0_18px_45px_rgba(13,42,70,0.08)]"
        role="tablist"
      >
        {(Object.keys(plans) as PlanId[]).map((plan) => {
          const isActive = activePlan === plan;
          return (
            <button
              aria-controls={`panel-${plan}`}
              aria-selected={isActive}
              className={`rounded-2xl px-6 py-3 text-sm font-black ${
                isActive
                  ? "bg-[#0d2a46] text-white shadow-[0_12px_28px_rgba(13,42,70,0.16)]"
                  : "text-[#667581] hover:bg-[#f3f7f9]"
              }`}
              id={`tab-${plan}`}
              key={plan}
              onClick={() => selectPlan(plan)}
              onKeyDown={(event) => onKeyDown(event, plan)}
              role="tab"
              type="button"
            >
              {plans[plan].title}
            </button>
          );
        })}
      </div>

      <div className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-[0.88fr_1.12fr]">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-1">
          {(Object.keys(plans) as PlanId[]).map((plan) => {
            const isActive = activePlan === plan;
            const PlanIcon = plans[plan].icon;
            return (
              <button
                aria-pressed={isActive}
                className={`rounded-[24px] border p-5 text-left ${
                  isActive
                    ? "border-[#0d2a46] bg-white shadow-[0_18px_60px_rgba(13,42,70,0.12)]"
                    : "border-[#dce8ef] bg-white/72 text-[#667581]"
                }`}
                id={plan}
                key={plan}
                onClick={() => selectPlan(plan)}
                type="button"
              >
                <div className="flex items-center justify-between gap-3">
                  <PlanIcon className="size-5" />
                  {isActive ? (
                    <Check className="size-5 text-[#2f9e44]" />
                  ) : null}
                </div>
                <p className="mt-4 text-xl font-black tracking-normal">
                  {plans[plan].title}
                </p>
                <p
                  className={`mt-3 text-2xl font-black tracking-normal ${
                    isActive ? "text-[#0d2a46]" : "text-[#7b8995]"
                  }`}
                >
                  {plans[plan].price}
                </p>
                <p className="mt-2 text-sm font-extrabold text-[#7b8995]">
                  {plan === "pro"
                    ? `${copy.or} ${proMonthlyPrice} / ${copy.monthlyPrice}`
                    : plans[plan].priceNote}
                </p>
              </button>
            );
          })}
        </div>

        <article
          aria-labelledby={`tab-${activePlan}`}
          className={
            activePlan === "pro"
              ? "rounded-[28px] bg-[#0d2a46] p-7 text-white shadow-[0_26px_80px_rgba(13,42,70,0.18)]"
              : "rounded-[28px] border border-[#dce8ef] bg-white/90 p-7 shadow-[0_22px_70px_rgba(13,42,70,0.10)]"
          }
          id={`panel-${activePlan}`}
          role="tabpanel"
        >
          <div className="flex items-start justify-between gap-4">
            <div>
              <p
                className={`text-sm font-black ${
                  activePlan === "pro" ? "text-[#a9bfce]" : "text-[#82909c]"
                }`}
              >
                {active.eyebrow}
              </p>
              <h2 className="mt-2 text-4xl font-black tracking-normal">
                {active.title}
              </h2>
            </div>
            <span
              className={`rounded-2xl p-3 ${
                activePlan === "pro" ? "bg-white/10" : "bg-[#fff2d4]"
              }`}
            >
              <ActiveIcon className="size-6" />
            </span>
          </div>

          <p
            className={`mt-5 text-[2.85rem] font-black leading-none tracking-normal ${
              activePlan === "pro" ? "text-[#dce9f2]" : "text-[#0d2a46]"
            }`}
          >
            {active.price}
          </p>
          <p
            className={`mt-2 text-sm font-black ${
              activePlan === "pro" ? "text-[#a9bfce]" : "text-[#82909c]"
            }`}
          >
            {active.priceNote}
          </p>

          {activePlan === "pro" ? (
            <div className="mt-5 grid grid-cols-1 gap-3 sm:grid-cols-2">
              <div className="rounded-[18px] border border-white/15 bg-white/8 p-4">
                <p className="text-xs font-black uppercase text-[#a9bfce]">
                  {copy.monthly}
                </p>
                <p className="mt-2 text-2xl font-black tracking-normal text-white">
                  {proMonthlyPrice}
                </p>
                <p className="mt-1 text-xs font-extrabold text-[#a9bfce]">
                  {copy.monthlyPrice}
                </p>
              </div>
              <div className="rounded-[18px] border border-[#ffcf58]/50 bg-[#fff2d4] p-4 text-[#0d2a46]">
                <p className="text-xs font-black uppercase text-[#40566b]">
                  {copy.annualRecommended}
                </p>
                <p className="mt-2 text-2xl font-black tracking-normal">
                  {proAnnualPrice}
                </p>
                <p className="mt-1 text-xs font-extrabold text-[#40566b]">
                  {proMonthlyEquivalent}
                </p>
              </div>
            </div>
          ) : null}

          <ul className="mt-6 grid gap-3">
            {active.lines.map((line) => (
              <li
                className={`flex items-center gap-3 text-sm font-extrabold ${
                  activePlan === "pro" ? "text-[#d7e6ef]" : "text-[#607080]"
                }`}
                key={line}
              >
                <ShieldCheck className="size-4 shrink-0 text-[#2f9e44]" />
                {line}
              </li>
            ))}
          </ul>

          <div className="mt-7">
            {activePlan === "pro" ? (
              <a
                className="primary-cta w-full"
                href={withLocale("/licence?plan=annual", locale)}
              >
                <CreditCard className="size-5" />
                {copy.createLicense}
              </a>
            ) : (
              <a className="primary-cta w-full" href="/api/download">
                <Download className="size-5" />
                {copy.download}
              </a>
            )}
          </div>

          {activePlan === "pro" ? (
            <p className="mt-5 flex items-center gap-2 text-sm font-extrabold text-[#a9bfce]">
              <Sparkles className="size-4 text-[#ffcf58]" />
              {copy.securePayment}
            </p>
          ) : (
            <p className="mt-5 text-sm font-extrabold text-[#82909c]">
              {copy.freeNote}
            </p>
          )}
        </article>
      </div>
    </section>
  );
}
