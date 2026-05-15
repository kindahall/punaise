import Image from "next/image";

export function SiteLogo({ size = 44 }: { size?: number }) {
  const radius = Math.round(size * 0.18);

  return (
    <Image
      alt=""
      aria-hidden="true"
      className="shrink-0 shadow-[0_4px_14px_rgba(13,42,70,0.16)]"
      height={size}
      priority
      src="/images/punaise-icon.png"
      style={{ borderRadius: radius }}
      width={size}
    />
  );
}
