import Link from "next/link";
import {
  ArrowLeft,
  Mail,
  MessageSquareText,
  Send,
  ShieldCheck,
} from "lucide-react";
import { SiteLogo } from "@/components/site-logo";
import { getSiteLocale, siteCopy, withLocale } from "@/lib/site-i18n";

type ContactPageProps = {
  searchParams: Promise<{
    sent?: string;
    error?: string;
    lang?: string;
  }>;
};

const contactEmail =
  process.env.NEXT_PUBLIC_CONTACT_EMAIL?.trim() || "contact@punaise.cloud";

export default async function ContactPage({ searchParams }: ContactPageProps) {
  const params = await searchParams;
  const locale = getSiteLocale(params.lang);
  const copy = siteCopy[locale];
  const sent = params.sent === "1";
  const error = params.error === "1";

  return (
    <main className="min-h-screen bg-[#fbfaf6] px-6 py-8 text-[#0d2a46] sm:px-10 lg:px-14">
      <header className="mx-auto flex max-w-[1400px] items-center justify-between">
        <Link className="flex items-center gap-3" href={withLocale("/", locale)}>
          <SiteLogo />
          <span className="text-2xl font-black tracking-normal">Punaise</span>
        </Link>

        <Link
          className="inline-flex items-center gap-2 rounded-2xl border border-[#dce8ef] bg-white/80 px-5 py-3 text-sm font-black text-[#40566b]"
          href={withLocale("/", locale)}
        >
          <ArrowLeft className="size-4" />
          {copy.nav.home}
        </Link>
      </header>

      <section className="mx-auto mt-14 grid max-w-[1200px] grid-cols-1 gap-6 lg:grid-cols-[0.86fr_1.14fr]">
        <div className="rounded-[32px] border border-[#dce8ef] bg-white/88 p-8 shadow-[0_28px_80px_rgba(13,42,70,0.10)]">
          <p className="inline-flex items-center gap-2 rounded-full bg-[#fff2d4] px-4 py-2 text-sm font-black text-[#0d2a46]">
            <Mail className="size-4 text-[#f05a22]" />
            {copy.nav.contact}
          </p>
          <h1 className="mt-6 text-5xl font-black leading-none tracking-normal">
            {copy.contact.title}
          </h1>
          <p className="mt-6 text-lg font-bold leading-8 text-[#657481]">
            {copy.contact.intro}
          </p>

          <div className="mt-8 grid gap-3 text-sm font-black text-[#40566b]">
            <a
              className="inline-flex items-center gap-3 rounded-[20px] border border-[#dce8ef] bg-[#fbfaf6] px-4 py-4"
              href={`mailto:${contactEmail}?subject=Contact%20Punaise`}
            >
              <Mail className="size-5 text-[#f05a22]" />
              {contactEmail}
            </a>
            <div className="inline-flex items-center gap-3 rounded-[20px] border border-[#dce8ef] bg-[#fbfaf6] px-4 py-4">
              <ShieldCheck className="size-5 text-[#2f9e44]" />
              {copy.contact.response}
            </div>
          </div>
        </div>

        <form
          action="/api/contact"
          className="rounded-[32px] border border-[#dce8ef] bg-white/92 p-6 shadow-[0_28px_80px_rgba(13,42,70,0.10)] sm:p-8"
          method="post"
        >
          <input
            aria-hidden="true"
            autoComplete="off"
            className="hidden"
            name="company"
            tabIndex={-1}
            type="text"
          />
          <input name="lang" type="hidden" value={locale} />

          {sent ? (
            <div className="mb-6 rounded-[22px] border border-[#bfe8c5] bg-[#effaf0] px-5 py-4 text-sm font-black text-[#247a35]">
              {copy.contact.sent}
            </div>
          ) : null}

          {error ? (
            <div className="mb-6 rounded-[22px] border border-[#ffd0ca] bg-[#fff4f2] px-5 py-4 text-sm font-black text-[#b03a1c]">
              {copy.contact.error}
            </div>
          ) : null}

          <div className="grid gap-5 sm:grid-cols-2">
            <label className="grid gap-2 text-sm font-black text-[#40566b]">
              {copy.contact.name}
              <input
                className="min-h-14 rounded-[18px] border border-[#dce8ef] bg-[#fbfaf6] px-4 text-base font-bold outline-none focus:border-[#f05a22]"
                maxLength={120}
                name="name"
                placeholder={copy.contact.namePlaceholder}
                type="text"
              />
            </label>

            <label className="grid gap-2 text-sm font-black text-[#40566b]">
              Email
              <input
                className="min-h-14 rounded-[18px] border border-[#dce8ef] bg-[#fbfaf6] px-4 text-base font-bold outline-none focus:border-[#f05a22]"
                maxLength={180}
                name="email"
                placeholder={copy.license.emailPlaceholder}
                required
                type="email"
              />
            </label>
          </div>

          <label className="mt-5 grid gap-2 text-sm font-black text-[#40566b]">
            {copy.contact.subject}
            <input
              className="min-h-14 rounded-[18px] border border-[#dce8ef] bg-[#fbfaf6] px-4 text-base font-bold outline-none focus:border-[#f05a22]"
              maxLength={160}
              name="subject"
              placeholder={copy.contact.subjectPlaceholder}
              type="text"
            />
          </label>

          <label className="mt-5 grid gap-2 text-sm font-black text-[#40566b]">
            {copy.contact.message}
            <textarea
              className="min-h-44 resize-y rounded-[18px] border border-[#dce8ef] bg-[#fbfaf6] px-4 py-4 text-base font-bold leading-7 outline-none focus:border-[#f05a22]"
              maxLength={4000}
              name="message"
              placeholder={copy.contact.messagePlaceholder}
              required
            />
          </label>

          <button className="primary-cta mt-7 w-full" type="submit">
            <Send className="size-5" />
            {copy.contact.send}
          </button>

          <p className="mt-5 flex items-center gap-2 text-sm font-extrabold text-[#82909c]">
            <MessageSquareText className="size-4 text-[#f05a22]" />
            {copy.contact.privateNote}
          </p>
        </form>
      </section>
    </main>
  );
}
