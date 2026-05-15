import { NextRequest, NextResponse } from "next/server";

export function GET(request: NextRequest) {
  const configuredDownloadUrl = process.env.FREE_DOWNLOAD_URL?.trim();
  const origin = (
    process.env.NEXT_PUBLIC_SITE_URL?.trim() || new URL(request.url).origin
  ).replace(/\/$/, "");
  const downloadUrl =
    configuredDownloadUrl ||
    (() => {
      const localDownloadUrl = new URL("/downloads/Punaise-Free.dmg", origin);
      const downloadVersion = process.env.APP_DOWNLOAD_VERSION?.trim();

      if (downloadVersion) {
        localDownloadUrl.searchParams.set("v", downloadVersion);
      }

      return localDownloadUrl.toString();
    })();

  return NextResponse.redirect(downloadUrl);
}
