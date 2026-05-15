import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { LicenseCheckout } from "@/components/license-checkout";
import { SiteLogo } from "@/components/site-logo";
import { getSiteLocale, siteCopy, withLocale } from "@/lib/site-i18n";

type LicensePageProps = {
  searchParams: Promise<{
    plan?: string;
    lang?: string;
  }>;
};

export default async function LicensePage({ searchParams }: LicensePageProps) {
  const params = await searchParams;
  const initialPlan = params.plan === "monthly" ? "monthly" : "annual";
  const locale = getSiteLocale(params.lang);
  const copy = siteCopy[locale];

  return (
    <main className="min-h-screen bg-[#fbfaf6] px-6 py-8 text-[#0d2a46] sm:px-10 lg:px-14">
      <header className="mx-auto flex max-w-[1400px] items-center justify-between">
        <Link className="flex items-center gap-3" href={withLocale("/", locale)}>
          <SiteLogo />
          <span className="text-2xl font-black tracking-normal">Punaise</span>
        </Link>

        <Link
          className="inline-flex items-center gap-2 rounded-2xl border border-[#dce8ef] bg-white/80 px-5 py-3 text-sm font-black text-[#40566b]"
          href={withLocale("/#tarifs", locale)}
        >
          <ArrowLeft className="size-4" />
          {copy.nav.offers}
        </Link>
      </header>

      <section className="mx-auto mt-14 max-w-[1200px]">
        <LicenseCheckout initialPlan={initialPlan} locale={locale} />
      </section>
    </main>
  );
}
