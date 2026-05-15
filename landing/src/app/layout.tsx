import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000"),
  title: "Punaise - Épingle ce qui presse",
  description:
    "Punaise transforme les échéances importantes en notes visibles sur le bureau Mac.",
  openGraph: {
    title: "Punaise",
    description: "Épingle ce qui presse.",
    images: ["/images/punaise-landing-visual.png"],
  },
  icons: {
    icon: "/images/punaise-icon.png",
    apple: "/images/punaise-icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="fr"
      className={`${geistSans.variable} ${geistMono.variable}`}
    >
      <body>{children}</body>
    </html>
  );
}
