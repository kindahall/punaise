const fs = require("node:fs/promises");
const path = require("node:path");
const sharp = require("sharp");

const root = path.resolve(__dirname, "..");
const appShotPath = path.join(__dirname, "punaise-app-window.png");
const outputPath = path.join(__dirname, "punaise-landing-visual-v2.png");

const width = 1800;
const height = 1120;

function esc(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function note({ x, y, w, h, color, pin, title, date, score, rotate = 0, ink = "#0d2a46" }) {
  const titleSize = title.length > 16 ? 23 : 27;
  return `
    <g transform="translate(${x} ${y}) rotate(${rotate} ${w / 2} ${h / 2})">
      <rect x="0" y="0" width="${w}" height="${h}" rx="24" fill="${color}" filter="url(#softShadow)"/>
      <rect x="0" y="86" width="${w}" height="1" fill="#000" opacity=".06"/>
      <rect x="0" y="128" width="${w}" height="1" fill="#000" opacity=".04"/>
      <circle cx="${w / 2}" cy="-1" r="22" fill="#f56d2d"/>
      <text x="${w / 2}" y="9" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="24" font-weight="800" fill="#fff">•</text>
      <text x="24" y="46" font-family="Arial, Helvetica, sans-serif" font-size="17" font-weight="800" fill="${ink}" opacity=".72">${esc(pin)}</text>
      <text x="24" y="74" font-family="Arial, Helvetica, sans-serif" font-size="20" font-weight="900" fill="${ink}" opacity=".78">${esc(date)}</text>
      <rect x="${w - 78}" y="34" width="48" height="34" rx="17" fill="#fff" opacity=".36"/>
      <text x="${w - 54}" y="58" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="20" font-weight="900" fill="${ink}">${esc(score)}</text>
      <text x="28" y="${h - 44}" font-family="Arial, Helvetica, sans-serif" font-size="${titleSize}" font-weight="900" fill="${ink}">${esc(title)}</text>
    </g>`;
}

async function main() {
  const appShot = await sharp(appShotPath)
    .resize({ width: 1040 })
    .png()
    .toBuffer();

  const roundedMask = Buffer.from(`
    <svg width="1040" height="872" viewBox="0 0 1040 872" xmlns="http://www.w3.org/2000/svg">
      <rect width="1040" height="872" rx="30" fill="#fff"/>
    </svg>`);

  const roundedApp = await sharp(appShot)
    .composite([{ input: roundedMask, blend: "dest-in" }])
    .png()
    .toBuffer();

  const base = Buffer.from(`
  <svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <filter id="softShadow" x="-30%" y="-30%" width="160%" height="170%">
        <feDropShadow dx="0" dy="22" stdDeviation="24" flood-color="#12304a" flood-opacity=".18"/>
      </filter>
      <filter id="appShadow" x="-20%" y="-20%" width="150%" height="150%">
        <feDropShadow dx="0" dy="34" stdDeviation="38" flood-color="#12304a" flood-opacity=".20"/>
      </filter>
      <linearGradient id="heroBg" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#fffdf8"/>
        <stop offset=".52" stop-color="#f6fbfd"/>
        <stop offset="1" stop-color="#fff6ea"/>
      </linearGradient>
    </defs>

    <rect width="${width}" height="${height}" fill="url(#heroBg)"/>
    <rect x="56" y="42" width="1688" height="76" rx="22" fill="#ffffff" opacity=".88"/>
    <circle cx="104" cy="80" r="21" fill="#ffcf58"/>
    <text x="136" y="91" font-family="Arial, Helvetica, sans-serif" font-size="26" font-weight="900" fill="#0d2a46">Punaise</text>
    <text x="1230" y="88" font-family="Arial, Helvetica, sans-serif" font-size="16" font-weight="800" fill="#687581">Gratuit</text>
    <text x="1334" y="88" font-family="Arial, Helvetica, sans-serif" font-size="16" font-weight="800" fill="#687581">Pro</text>
    <text x="1430" y="88" font-family="Arial, Helvetica, sans-serif" font-size="16" font-weight="800" fill="#687581">Télécharger</text>
    <rect x="1564" y="58" width="140" height="44" rx="16" fill="#0d2a46"/>
    <text x="1634" y="87" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="15" font-weight="900" fill="#fff">Passer Pro</text>

    <g transform="translate(84 184)">
      <text x="0" y="80" font-family="Arial, Helvetica, sans-serif" font-size="92" font-weight="900" fill="#0d2a46">Punaise</text>
      <text x="2" y="128" font-family="Arial, Helvetica, sans-serif" font-size="33" font-weight="800" fill="#f05a22">Épingle ce qui presse.</text>
      <text x="2" y="184" font-family="Arial, Helvetica, sans-serif" font-size="22" font-weight="700" fill="#5e6c78">Tes échéances importantes restent visibles</text>
      <text x="2" y="218" font-family="Arial, Helvetica, sans-serif" font-size="22" font-weight="700" fill="#5e6c78">sur le bureau Mac.</text>
      <rect x="0" y="242" width="252" height="62" rx="18" fill="#f05a22"/>
      <text x="126" y="281" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="19" font-weight="900" fill="#fff">Télécharger gratuitement</text>
      <rect x="274" y="242" width="182" height="62" rx="18" fill="#fff" stroke="#d8e0e6" stroke-width="2"/>
      <text x="365" y="281" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="19" font-weight="900" fill="#0d2a46">Passer en Pro</text>
      <text x="2" y="352" font-family="Arial, Helvetica, sans-serif" font-size="16" font-weight="800" fill="#687581">Free: 5 Punaises visibles.</text>
      <text x="2" y="378" font-family="Arial, Helvetica, sans-serif" font-size="16" font-weight="800" fill="#687581">Pro: illimité, sauvegarde et Stripe.</text>
    </g>

    <rect x="620" y="142" width="1080" height="906" rx="34" fill="#ffffff" filter="url(#appShadow)" opacity=".96"/>

    <g transform="translate(84 868)">
      <rect x="0" y="0" width="330" height="154" rx="24" fill="#ffffff" stroke="#dde6ec"/>
      <text x="28" y="45" font-family="Arial, Helvetica, sans-serif" font-size="22" font-weight="900" fill="#0d2a46">Gratuit</text>
      <text x="28" y="82" font-family="Arial, Helvetica, sans-serif" font-size="17" font-weight="700" fill="#627180">5 Punaises visibles</text>
      <text x="28" y="112" font-family="Arial, Helvetica, sans-serif" font-size="15" font-weight="700" fill="#8a96a1">Téléchargement direct</text>
      <rect x="358" y="0" width="330" height="154" rx="24" fill="#0d2a46"/>
      <text x="386" y="45" font-family="Arial, Helvetica, sans-serif" font-size="22" font-weight="900" fill="#fff">Pro</text>
      <text x="386" y="82" font-family="Arial, Helvetica, sans-serif" font-size="17" font-weight="700" fill="#dce9f2">Punaises illimitées</text>
      <text x="386" y="112" font-family="Arial, Helvetica, sans-serif" font-size="15" font-weight="700" fill="#a9bfce">Stripe Checkout</text>
    </g>
  </svg>`);

  const notes = Buffer.from(`
  <svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <filter id="softShadow" x="-30%" y="-30%" width="160%" height="170%">
        <feDropShadow dx="0" dy="18" stdDeviation="22" flood-color="#12304a" flood-opacity=".18"/>
      </filter>
    </defs>
    ${note({ x: 1220, y: 142, w: 270, h: 174, color: "#ffe38c", pin: "Échéance", date: "demain", score: "82", title: "Contrat client", rotate: -3 })}
    ${note({ x: 1492, y: 266, w: 260, h: 172, color: "#ffd0ca", pin: "Critique", date: "18:00", score: "94", title: "Facture", rotate: 3 })}
    ${note({ x: 1126, y: 610, w: 264, h: 174, color: "#bfe2ff", pin: "Appel", date: "15 mai", score: "56", title: "Relancer client", rotate: 2 })}
    ${note({ x: 1458, y: 748, w: 266, h: 174, color: "#d9f2cc", pin: "Livraison", date: "lun.", score: "41", title: "Confirmer dépôt", rotate: -2 })}
    ${note({ x: 972, y: 286, w: 252, h: 166, color: "#f7f1df", pin: "Projet", date: "17 mai", score: "28", title: "Nouvelle Punaise", rotate: -1 })}
  </svg>`);

  await sharp(base)
    .composite([
      { input: roundedApp, left: 640, top: 160 },
      { input: notes, left: 0, top: 0 }
    ])
    .png()
    .toFile(outputPath);

  console.log(path.relative(root, outputPath));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
