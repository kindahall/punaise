import Image from "next/image";
import {
  Archive,
  Bell,
  CalendarDays,
  CreditCard,
  Download,
  Pin,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import { PricingTabs } from "@/components/pricing-tabs";
import { SiteLogo } from "@/components/site-logo";
import {
  getSiteLocale,
  siteCopy,
  type SiteLocale,
  withLocale,
} from "@/lib/site-i18n";

const proMonthlyPrice =
  process.env.NEXT_PUBLIC_PRO_MONTHLY_PRICE?.trim() || "3,99 €";
const proAnnualPrice =
  process.env.NEXT_PUBLIC_PRO_ANNUAL_PRICE?.trim() || "29,99 €";
const proMonthlyEquivalent =
  process.env.NEXT_PUBLIC_PRO_MONTHLY_EQUIVALENT?.trim() || "2,50 € / mois";
const contactEmail =
  process.env.NEXT_PUBLIC_CONTACT_EMAIL?.trim() || "contact@punaise.cloud";

const featureIcons = [Pin, Bell, CalendarDays, Archive];

type HomeProps = {
  searchParams: Promise<{
    lang?: string;
  }>;
};

type HeroNote = {
  tone: string;
  label: string;
  date: string;
  score: string;
  title: string;
  className: string;
};

export default async function Home({ searchParams }: HomeProps) {
  const params = await searchParams;
  const locale = getSiteLocale(params.lang);
  const copy = siteCopy[locale];

  return (
    <main className="min-h-screen overflow-hidden bg-[#fbfaf6] text-[#0d2a46]">
      <Header locale={locale} />

      <section className="relative mx-auto grid min-h-[calc(100vh-96px)] w-full max-w-[1800px] grid-cols-1 items-center gap-12 px-6 pb-10 pt-10 sm:px-10 lg:grid-cols-[0.88fr_1.42fr] lg:px-14 lg:pb-14 lg:pt-8">
        <div className="relative z-10 max-w-[610px]">
          <div className="mb-8 inline-flex items-center gap-2 rounded-full border border-[#dce8ef] bg-white/78 px-4 py-2 text-sm font-extrabold text-[#657481] shadow-sm">
            <ShieldCheck className="size-4 text-[#2f9e44]" />
            {copy.home.badge}
          </div>

          <h1 className="text-[clamp(4.25rem,9vw,7.25rem)] font-black leading-[0.86] tracking-normal text-[#0d2a46]">
            Punaise
          </h1>
          <p className="mt-5 whitespace-nowrap text-[1.35rem] font-black leading-none tracking-normal text-[#f05a22] sm:text-[2.25rem] md:text-[2.7rem] xl:text-[3rem]">
            {copy.home.kicker}
          </p>
          <p className="mt-8 max-w-[520px] text-[clamp(1.15rem,1.7vw,1.55rem)] font-bold leading-snug text-[#5f6e7b]">
            {copy.home.subtitle}
          </p>

          <div className="mt-8 flex flex-col gap-4 sm:flex-row">
            <a className="primary-cta" href="/api/download">
              <Download className="size-5" />
              {copy.home.downloadCta}
            </a>
            <a
              className="secondary-cta"
              href={withLocale("/licence?plan=annual", locale)}
            >
              <CreditCard className="size-5" />
              {copy.home.proCta}
            </a>
          </div>

          <p className="mt-8 max-w-md text-base font-extrabold leading-7 text-[#667581]">
            {copy.home.freeLine}
            <br />
            {copy.home.proLinePrefix} : {proMonthlyPrice}/{copy.home.month}{" "}
            {copy.pricing.or} {proAnnualPrice}/{copy.home.year},{" "}
            {copy.home.equivalentPrefix} {proMonthlyEquivalent}.
          </p>

          <PricingTabs locale={locale} />
        </div>

        <HeroProduct alt={copy.home.imageAlt} notes={copy.home.notes} />
      </section>

      <section className="mx-auto grid max-w-[1600px] grid-cols-1 gap-4 px-6 pb-16 sm:px-10 md:grid-cols-2 lg:grid-cols-4 lg:px-14">
        {copy.home.features.map((feature, index) => {
          const FeatureIcon = featureIcons[index] ?? Pin;
          return (
            <article
              className="rounded-[24px] border border-[#dce8ef] bg-white/82 p-6 shadow-[0_18px_50px_rgba(13,42,70,0.07)]"
              key={feature.title}
            >
              <FeatureIcon className="mb-5 size-6 text-[#f05a22]" />
              <h2 className="text-xl font-black tracking-normal">
                {feature.title}
              </h2>
              <p className="mt-3 text-sm font-bold leading-6 text-[#657481]">
                {feature.text}
              </p>
            </article>
          );
        })}
      </section>

      <section className="mx-auto max-w-[1600px] px-6 pb-20 sm:px-10 lg:px-14">
        <div className="grid grid-cols-1 gap-5 rounded-[28px] border border-[#dce8ef] bg-white/82 p-6 shadow-[0_18px_50px_rgba(13,42,70,0.07)] lg:grid-cols-[0.82fr_1.18fr] lg:p-8">
          <div>
            <p className="inline-flex items-center gap-2 rounded-full bg-[#fff2d4] px-4 py-2 text-sm font-black text-[#0d2a46]">
              <Sparkles className="size-4 text-[#f05a22]" />
              {copy.home.proBadge}
            </p>
            <h2 className="mt-5 text-3xl font-black leading-tight tracking-normal text-[#0d2a46]">
              {copy.home.proTitle}
            </h2>
            <p className="mt-4 text-base font-bold leading-7 text-[#657481]">
              {copy.home.proText}
            </p>
          </div>

          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            {copy.home.proHighlights.map((item) => (
              <div
                className="rounded-[18px] border border-[#dce8ef] bg-[#fbfaf6] px-4 py-3 text-sm font-extrabold text-[#40566b]"
                key={item}
              >
                {item}
              </div>
            ))}
          </div>
        </div>
      </section>

      <Footer locale={locale} />
    </main>
  );
}

function Header({ locale }: { locale: SiteLocale }) {
  const copy = siteCopy[locale];
  const languageHref = locale === "fr" ? "/?lang=en" : "/";

  return (
    <header className="mx-auto flex max-w-[1800px] items-center justify-between px-6 py-6 sm:px-10 lg:px-14">
      <a className="flex items-center gap-3" href={withLocale("/", locale)}>
        <SiteLogo />
        <span className="text-2xl font-black tracking-normal">Punaise</span>
      </a>

      <nav className="hidden items-center gap-7 rounded-[24px] bg-white/84 px-8 py-4 text-sm font-black text-[#667581] shadow-[0_18px_50px_rgba(13,42,70,0.06)] md:flex">
        <a href="#gratuit">{copy.nav.free}</a>
        <a href="#pro">{copy.nav.pro}</a>
        <a href={withLocale("/licence", locale)}>{copy.nav.license}</a>
        <a href="/api/download">{copy.nav.download}</a>
        <a href={languageHref}>{copy.languageToggle}</a>
        <a
          className="rounded-2xl bg-[#0d2a46] px-6 py-3 text-white"
          href={withLocale("/licence?plan=annual", locale)}
        >
          {copy.nav.upgrade}
        </a>
      </nav>
    </header>
  );
}

function Footer({ locale }: { locale: SiteLocale }) {
  const copy = siteCopy[locale];

  return (
    <footer className="border-t border-[#dce8ef] bg-white/72 px-6 py-10 sm:px-10 lg:px-14">
      <div className="mx-auto grid max-w-[1800px] grid-cols-1 gap-8 md:grid-cols-[1.1fr_1fr_1fr] md:items-start">
        <div>
          <a
            className="inline-flex items-center gap-3"
            href={withLocale("/", locale)}
          >
            <SiteLogo size={40} />
            <span className="text-2xl font-black tracking-normal">
              Punaise
            </span>
          </a>
          <p className="mt-4 max-w-sm text-sm font-bold leading-6 text-[#657481]">
            {copy.home.footerText}
          </p>
          <p className="mt-5 text-xs font-extrabold text-[#82909c]">
            © 2026 Punaise. macOS 13+.
          </p>
        </div>

        <nav
          aria-label={copy.nav.footerMenu}
          className="grid gap-3 text-sm font-black text-[#40566b]"
        >
          <a href={withLocale("/", locale)}>{copy.nav.home}</a>
          <a href="#gratuit">{copy.nav.free}</a>
          <a href="#pro">{copy.nav.pro}</a>
          <a href={withLocale("/licence", locale)}>{copy.nav.license}</a>
          <a href="/api/download">{copy.nav.download}</a>
          <a href={withLocale("/contact", locale)}>{copy.nav.contact}</a>
        </nav>

        <div className="md:text-right">
          <p className="text-sm font-black text-[#0d2a46]">
            {copy.home.proLinePrefix} : {proMonthlyPrice}/{copy.home.month}{" "}
            {copy.pricing.or} {proAnnualPrice}/{copy.home.year}.
          </p>
          <p className="mt-2 text-sm font-bold text-[#657481]">
            {copy.home.paymentText}
          </p>
          <a
            className="mt-3 inline-flex text-sm font-black text-[#40566b] underline decoration-[#ffcf58] decoration-2 underline-offset-4"
            href={`mailto:${contactEmail}?subject=Contact%20Punaise`}
          >
            {contactEmail}
          </a>
          <a
            className="mt-4 inline-flex rounded-2xl bg-[#0d2a46] px-6 py-3 text-sm font-black text-white shadow-[0_14px_35px_rgba(13,42,70,0.16)]"
            href={withLocale("/licence?plan=annual", locale)}
          >
            {copy.nav.upgrade}
          </a>
        </div>
      </div>
    </footer>
  );
}

function HeroProduct({ alt, notes }: { alt: string; notes: readonly HeroNote[] }) {
  return (
    <div className="relative min-h-[620px] lg:min-h-[900px]">
      <div className="absolute inset-x-0 top-10 mx-auto h-[78%] max-w-[1080px] rounded-[36px] bg-white shadow-[0_45px_100px_rgba(13,42,70,0.18)]" />

      <div className="absolute left-[2%] top-[9%] w-[82%] max-w-[1040px] overflow-hidden rounded-[30px] border border-white/70 bg-white shadow-[0_20px_60px_rgba(13,42,70,0.12)]">
        <Image
          alt={alt}
          className="h-auto w-full"
          height={872}
          priority
          src="/images/punaise-app-window.png"
          width={1040}
        />
      </div>

      <div className="hidden xl:block">
        {notes.map((note) => (
          <FloatingNote key={note.title} {...note} />
        ))}
      </div>

      <div className="absolute inset-x-0 bottom-0 grid grid-cols-2 gap-3 md:hidden">
        {notes.map((note) => (
          <MiniNote key={note.title} {...note} />
        ))}
      </div>
    </div>
  );
}

function FloatingNote({
  tone,
  label,
  date,
  score,
  title,
  className,
}: HeroNote) {
  return (
    <div className={`floating-note note-${tone} ${className}`}>
      <span className="note-pin" />
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-base font-black leading-tight text-[#40566b]">
            {label}
          </p>
          <p className="mt-1 text-xl font-black leading-tight text-[#40566b]">
            {date}
          </p>
        </div>
        <span className="rounded-full bg-white/45 px-4 py-2 text-xl font-black text-[#0d2a46]">
          {score}
        </span>
      </div>
      <p className="mt-8 text-[1.55rem] font-black leading-tight tracking-normal text-[#0d2a46]">
        {title}
      </p>
    </div>
  );
}

function MiniNote({ tone, title }: HeroNote) {
  return (
    <div className={`rounded-3xl p-4 text-sm font-black note-${tone}`}>
      {title}
    </div>
  );
}
