import Link from "next/link";
import { CreditCard, Download } from "lucide-react";
import { getSiteLocale, siteCopy, withLocale } from "@/lib/site-i18n";

type ProIndisponiblePageProps = {
  searchParams: Promise<{
    lang?: string;
  }>;
};

export default async function ProIndisponiblePage({
  searchParams,
}: ProIndisponiblePageProps) {
  const params = await searchParams;
  const locale = getSiteLocale(params.lang);
  const copy = siteCopy[locale];

  return (
    <main className="flex min-h-screen items-center justify-center px-6 py-16">
      <section className="w-full max-w-2xl rounded-[32px] border border-[#dce8ef] bg-white/88 p-8 text-center shadow-[0_28px_80px_rgba(13,42,70,0.10)] sm:p-12">
        <CreditCard className="mx-auto size-14 text-[#f05a22]" />
        <h1 className="mt-8 text-4xl font-black tracking-normal text-[#0d2a46]">
          {copy.unavailable.title}
        </h1>
        <p className="mx-auto mt-5 max-w-lg text-lg font-bold leading-8 text-[#657481]">
          {copy.unavailable.intro}
        </p>
        <div className="mt-8 flex flex-col justify-center gap-4 sm:flex-row">
          <a className="primary-cta" href="/api/download">
            <Download className="size-5" />
            {copy.home.downloadCta}
          </a>
          <Link className="secondary-cta" href={withLocale("/#tarifs", locale)}>
            {copy.unavailable.offers}
          </Link>
          <Link className="secondary-cta" href={withLocale("/licence", locale)}>
            {copy.unavailable.create}
          </Link>
        </div>
      </section>
    </main>
  );
}
