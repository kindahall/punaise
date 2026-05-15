import { createHash, sign } from "crypto";

export type LicensePlan = "monthly" | "annual";

type IssueLicenseInput = {
  email?: string | null;
  plan: LicensePlan;
  requestId?: string | null;
  sessionId: string;
};

const licensePrefix = "PUNAISE1";
const licenseProduct = "punaise_pro";

function base64url(value: Buffer) {
  return value
    .toString("base64")
    .replaceAll("=", "")
    .replaceAll("+", "-")
    .replaceAll("/", "_");
}

function privateKeyPem() {
  const base64Key = process.env.PUNAISE_LICENSE_PRIVATE_KEY_B64?.trim();

  if (base64Key) {
    return Buffer.from(base64Key, "base64").toString("utf8");
  }

  const key = process.env.PUNAISE_LICENSE_PRIVATE_KEY_PEM?.trim();

  if (!key) {
    return null;
  }

  return key.replaceAll("\\n", "\n");
}

function normalizedEmailHash(email?: string | null) {
  const normalized = email?.trim().toLowerCase();

  if (!normalized) {
    return undefined;
  }

  return createHash("sha256").update(normalized).digest("hex");
}

export function issueSignedLicense(input: IssueLicenseInput) {
  const key = privateKeyPem();

  if (!key) {
    return null;
  }

  const payload = {
    v: 1,
    product: licenseProduct,
    plan: input.plan,
    issuedAt: new Date().toISOString(),
    emailHash: normalizedEmailHash(input.email),
    sessionId: input.sessionId,
    requestId: input.requestId || undefined,
  };
  const payloadBytes = Buffer.from(JSON.stringify(payload), "utf8");
  const signature = sign("sha256", payloadBytes, key);

  return `${licensePrefix}.${base64url(payloadBytes)}.${base64url(signature)}`;
}
