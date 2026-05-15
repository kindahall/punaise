import { appendFile, mkdir } from "node:fs/promises";
import path from "node:path";
import { NextRequest, NextResponse } from "next/server";

export const runtime = "nodejs";

const fallbackMessagesPath = path.join(
  process.cwd(),
  "data",
  "contact-messages.jsonl",
);

function clean(value: FormDataEntryValue | null, maxLength: number) {
  if (typeof value !== "string") {
    return "";
  }

  return value.replace(/\s+/g, " ").trim().slice(0, maxLength);
}

function cleanMessage(value: FormDataEntryValue | null) {
  if (typeof value !== "string") {
    return "";
  }

  return value.trim().slice(0, 4000);
}

function getPublicOrigin(request: NextRequest) {
  const configuredOrigin = process.env.NEXT_PUBLIC_SITE_URL?.trim();

  if (configuredOrigin) {
    return configuredOrigin.replace(/\/$/, "");
  }

  const forwardedProto = request.headers.get("x-forwarded-proto") || "https";
  const forwardedHost =
    request.headers.get("x-forwarded-host") || request.headers.get("host");

  if (forwardedHost) {
    return `${forwardedProto}://${forwardedHost}`;
  }

  return new URL(request.url).origin;
}

function redirectToContact(request: NextRequest, params: Record<string, string>) {
  const url = new URL("/contact", getPublicOrigin(request));

  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }

  return NextResponse.redirect(url, { status: 303 });
}

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const lang = clean(formData.get("lang"), 8) === "en" ? "en" : "";
  const languageParams: Record<string, string> = lang ? { lang } : {};

  if (clean(formData.get("company"), 120)) {
    return redirectToContact(request, { ...languageParams, sent: "1" });
  }

  const name = clean(formData.get("name"), 120);
  const email = clean(formData.get("email"), 180).toLowerCase();
  const subject = clean(formData.get("subject"), 160) || "Contact Punaise";
  const message = cleanMessage(formData.get("message"));
  const isValidEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

  if (!isValidEmail || message.length < 4) {
    return redirectToContact(request, { ...languageParams, error: "1" });
  }

  const messagesPath =
    process.env.CONTACT_MESSAGES_PATH?.trim() || fallbackMessagesPath;
  const forwardedFor = request.headers.get("x-forwarded-for");
  const ip = forwardedFor?.split(",")[0]?.trim() || null;

  const record = {
    createdAt: new Date().toISOString(),
    name,
    email,
    subject,
    message,
    lang: lang || "fr",
    ip,
    userAgent: request.headers.get("user-agent"),
  };

  await mkdir(path.dirname(messagesPath), { recursive: true });
  await appendFile(messagesPath, `${JSON.stringify(record)}\n`, "utf8");

  return redirectToContact(request, { ...languageParams, sent: "1" });
}
