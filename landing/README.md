# Punaise Landing

Landing page Next.js pour distribuer Punaise.

## Parcours

- `Télécharger gratuitement` sert le DMG gratuit depuis `public/downloads/Punaise-Free.dmg`.
- `Passer en Pro` ouvre `/licence`, où l’utilisateur prépare une demande de clé, choisit mensuel ou annuel, puis part vers Stripe Checkout.
- `Contact` ouvre `/contact`, où les demandes sont enregistrées côté serveur avec l’email de réponse.
- La page affiche `Gratuit : 0 €`, `Pro : 3,99 €/mois` et `Pro : 29,99 €/an` en prix de lancement par défaut.
- Le webhook Stripe est disponible sur `/api/stripe/webhook`.

## Lancer

```bash
npm run dev
```

## Variables

Copier `.env.example` vers `.env.local`.

```bash
cp .env.example .env.local
```

Définir `STRIPE_SECRET_KEY`, `STRIPE_MONTHLY_PRICE_ID`, `STRIPE_ANNUAL_PRICE_ID`, `STRIPE_WEBHOOK_SECRET` et `PUNAISE_LICENSE_PRIVATE_KEY_B64`.

`NEXT_PUBLIC_PRO_MONTHLY_PRICE`, `NEXT_PUBLIC_PRO_ANNUAL_PRICE` et `NEXT_PUBLIC_PRO_MONTHLY_EQUIVALENT` pilotent le libellé visible du tarif.

`NEXT_PUBLIC_CONTACT_EMAIL` pilote l’adresse affichée dans le pied de page.

`APP_DOWNLOAD_VERSION` ajoute un paramètre de version au lien du DMG pour éviter de resservir un ancien fichier en cache.

`CONTACT_MESSAGES_PATH` indique où stocker les messages envoyés depuis `/contact`. En production VPS, utiliser par exemple `/var/www/punaise/data/contact-messages.jsonl`.

La demande créée sur `/licence` est passée dans les metadata Stripe (`license_request_id`). `/merci` vérifie la Checkout Session avec Stripe, puis affiche une clé `PUNAISE1...` signée que l’app Mac peut vérifier localement.
