export type SiteLocale = "fr" | "en";

export function getSiteLocale(value?: string | null): SiteLocale {
  return value === "en" ? "en" : "fr";
}

export function withLocale(href: string, locale: SiteLocale) {
  if (locale === "fr" || href.startsWith("/api/") || href.startsWith("#")) {
    return href;
  }

  const [path, hash = ""] = href.split("#");
  const separator = path.includes("?") ? "&" : "?";
  return `${path}${separator}lang=en${hash ? `#${hash}` : ""}`;
}

export const siteCopy = {
  fr: {
    languageToggle: "EN",
    nav: {
      free: "Gratuit",
      pro: "Pro",
      license: "Licence",
      download: "Télécharger",
      upgrade: "Passer Pro",
      contact: "Contact",
      home: "Accueil",
      offers: "Offres",
      footerMenu: "Menu pied de page",
    },
    home: {
      badge: "macOS 13+",
      kicker: "Épingle ce qui presse.",
      subtitle: "Tes échéances importantes restent visibles sur le bureau Mac.",
      downloadCta: "Télécharger gratuitement",
      proCta: "Passer en Pro",
      freeLine: "Gratuit : 5 Punaises visibles.",
      proLinePrefix: "Pro",
      month: "mois",
      year: "an",
      equivalentPrefix: "soit",
      proBadge: "Différence Pro",
      proTitle: "Pro ne rajoute pas seulement des notes.",
      proText:
        "Il transforme Punaise en système d'urgence visible : score, anti-oubli, bureau intelligent, imports et sauvegarde.",
      footerText:
        "Une app Mac pour garder les urgences visibles sans transformer ton bureau en gestionnaire de tâches.",
      paymentText: "Paiement sécurisé via Stripe Checkout.",
      notes: [
        {
          tone: "yellow",
          label: "Échéance",
          date: "demain",
          score: "82",
          title: "Contrat client",
          className: "right-[12%] top-[1%] -rotate-2",
        },
        {
          tone: "red",
          label: "Critique",
          date: "18:00",
          score: "94",
          title: "Facture",
          className: "-right-[2%] top-[17%] rotate-2",
        },
        {
          tone: "paper",
          label: "Projet",
          date: "17 mai",
          score: "28",
          title: "Nouvelle Punaise",
          className: "left-[32%] top-[19%] -rotate-1",
        },
        {
          tone: "blue",
          label: "Appel",
          date: "15 mai",
          score: "56",
          title: "Relancer client",
          className: "left-[46%] top-[58%] rotate-1",
        },
        {
          tone: "green",
          label: "Livraison",
          date: "lun.",
          score: "41",
          title: "Confirmer dépôt",
          className: "right-[1%] bottom-[7%] -rotate-1",
        },
      ],
      features: [
        {
          title: "Score d'urgence",
          text: "Chaque Punaise indique ce qui doit remonter maintenant.",
        },
        {
          title: "Mode Anti-oubli",
          text: "Les échéances ignorées deviennent visuellement impossibles à rater.",
        },
        {
          title: "Bureau intelligent",
          text: "Le bureau reste propre tout en gardant les urgences visibles.",
        },
        {
          title: "Imports et contexte",
          text: "Google Agenda, Apple Reminders, fichiers, apps, sites et mails.",
        },
      ],
      proHighlights: [
        "Score d'urgence dynamique",
        "Ce qui presse maintenant",
        "Règles d'urgence personnalisées",
        "Tableau de pression mentale",
        "Plan de secours",
        "Templates métier",
        "iCloud Drive + sauvegarde chiffrée",
        "Contexte fichier, app, site, mail",
      ],
      imageAlt: "Interface Punaise sur macOS",
    },
    pricing: {
      aria: "Tarifs Punaise",
      choose: "Choisir une offre",
      directDownload: "Téléchargement direct",
      try: "Pour essayer",
      stripe: "Stripe Checkout",
      annualPrice: "par an",
      monthlyPrice: "par mois",
      monthly: "Mensuel",
      annualRecommended: "Annuel recommandé",
      or: "ou",
      createLicense: "Créer ma licence Pro",
      download: "Télécharger gratuitement",
      securePayment: "Paiement sécurisé via Stripe Checkout.",
      freeNote:
        "La version gratuite reste suffisante pour essayer Punaise avec 5 notes visibles.",
      plans: {
        gratuit: {
          title: "Gratuit",
          price: "0 €",
          lines: [
            "5 Punaises visibles",
            "Couleurs simples",
            "Notes flottantes basiques",
            "Rappel manuel simple",
          ],
        },
        pro: {
          title: "Pro",
          lines: [
            "Punaises illimitées",
            "Score d'urgence avancé",
            "Mode Anti-oubli",
            "Bureau propre intelligent",
            "Google Agenda et Apple Reminders",
            "iCloud + sauvegarde chiffrée",
            "Contexte fichier, app, site, mail",
            "Activation après paiement",
          ],
        },
      },
    },
    license: {
      step1: "Étape 1 - clé de licence",
      title: "Prépare ta clé Pro",
      intro:
        "La demande est liée à ton paiement Stripe. La clé signée apparaît après confirmation du paiement.",
      yourKey: "Demande",
      creating: "Préparation...",
      copied: "Copiée",
      copy: "Copier",
      regenerate: "Regénérer",
      bullets: [
        "La clé gratuite reste limitée à 5 Punaises visibles.",
        "La clé Pro est signée côté serveur seulement après validation Stripe.",
        "Aucun mot de passe ni tableau de bord requis au lancement.",
      ],
      step2: "Étape 2 - passage Pro",
      accessTitle: "Choisis ton accès",
      email: "Email de licence",
      emailPlaceholder: "toi@exemple.com",
      monthly: "Mensuel",
      monthlyNote: "Sans engagement",
      annual: "Annuel",
      recommended: "Recommandé",
      submit: "Créer ma licence Pro",
      stripeNote:
        "Stripe gère le paiement, la carte, les factures et l’abonnement. La clé reste le lien simple entre le site et l’app Mac.",
    },
    contact: {
      title: "Écris à Punaise.",
      intro:
        "Support, licence, achat Pro ou problème d’installation : le message arrive dans l’espace de suivi du serveur.",
      response: "Réponse avec l’email indiqué dans le formulaire",
      sent: "Message reçu. Tu peux répondre depuis l’email laissé par l’utilisateur.",
      error: "Il manque un email valide ou un message.",
      name: "Nom",
      namePlaceholder: "Ton nom",
      subject: "Sujet",
      subjectPlaceholder: "Licence, paiement, installation...",
      message: "Message",
      messagePlaceholder: "Explique la demande...",
      send: "Envoyer",
      privateNote: "Les messages sont conservés dans le suivi privé du site.",
    },
    merci: {
      title: "Paiement reçu",
      planMonthly: "mensuel",
      planAnnual: "annuel",
      intro:
        "Ton accès Pro {plan} est en cours de validation. Tu peux déjà récupérer Punaise et garder cette page sous la main.",
      keyTitle: "Clé de licence",
      keyText:
        "Elle est signée par Punaise. Colle-la dans l’app Mac pour passer en Pro.",
      download: "Télécharger Punaise",
      back: "Retour",
    },
    unavailable: {
      title: "Stripe n’est pas encore configuré",
      intro:
        "La page de licence est prête. Il reste seulement à brancher les prix Stripe mensuel et annuel pour activer le paiement.",
      offers: "Voir les offres",
      create: "Créer une licence",
    },
  },
  en: {
    languageToggle: "FR",
    nav: {
      free: "Free",
      pro: "Pro",
      license: "License",
      download: "Download",
      upgrade: "Go Pro",
      contact: "Contact",
      home: "Home",
      offers: "Plans",
      footerMenu: "Footer menu",
    },
    home: {
      badge: "macOS 13+",
      kicker: "Pin what matters now.",
      subtitle: "Your important deadlines stay visible on your Mac desktop.",
      downloadCta: "Download free",
      proCta: "Go Pro",
      freeLine: "Free: 5 visible Punaises.",
      proLinePrefix: "Pro",
      month: "month",
      year: "year",
      equivalentPrefix: "about",
      proBadge: "Pro difference",
      proTitle: "Pro does not just add more notes.",
      proText:
        "It turns Punaise into a visible urgency system: scoring, anti-forget mode, smart desktop, imports, and backup.",
      footerText:
        "A Mac app for keeping urgent work visible without turning your desktop into a full task manager.",
      paymentText: "Secure payment through Stripe Checkout.",
      notes: [
        {
          tone: "yellow",
          label: "Deadline",
          date: "tomorrow",
          score: "82",
          title: "Client contract",
          className: "right-[12%] top-[1%] -rotate-2",
        },
        {
          tone: "red",
          label: "Critical",
          date: "6:00 PM",
          score: "94",
          title: "Invoice",
          className: "-right-[2%] top-[17%] rotate-2",
        },
        {
          tone: "paper",
          label: "Project",
          date: "May 17",
          score: "28",
          title: "New Punaise",
          className: "left-[32%] top-[19%] -rotate-1",
        },
        {
          tone: "blue",
          label: "Call",
          date: "May 15",
          score: "56",
          title: "Follow up",
          className: "left-[46%] top-[58%] rotate-1",
        },
        {
          tone: "green",
          label: "Delivery",
          date: "Mon.",
          score: "41",
          title: "Confirm drop-off",
          className: "right-[1%] bottom-[7%] -rotate-1",
        },
      ],
      features: [
        {
          title: "Urgency score",
          text: "Each Punaise shows what needs to rise to the top now.",
        },
        {
          title: "Anti-forget mode",
          text: "Ignored deadlines become visually impossible to miss.",
        },
        {
          title: "Smart desktop",
          text: "Your desktop stays clean while urgent items remain visible.",
        },
        {
          title: "Imports and context",
          text: "Google Calendar, Apple Reminders, files, apps, sites, and email.",
        },
      ],
      proHighlights: [
        "Dynamic urgency score",
        "What matters now",
        "Custom urgency rules",
        "Mental pressure board",
        "Rescue plan",
        "Work templates",
        "iCloud Drive + encrypted backup",
        "File, app, site, and email context",
      ],
      imageAlt: "Punaise interface on macOS",
    },
    pricing: {
      aria: "Punaise pricing",
      choose: "Choose a plan",
      directDownload: "Direct download",
      try: "To try it",
      stripe: "Stripe Checkout",
      annualPrice: "per year",
      monthlyPrice: "per month",
      monthly: "Monthly",
      annualRecommended: "Annual recommended",
      or: "or",
      createLicense: "Create my Pro license",
      download: "Download free",
      securePayment: "Secure payment through Stripe Checkout.",
      freeNote:
        "The free version is enough to try Punaise with 5 visible notes.",
      plans: {
        gratuit: {
          title: "Free",
          price: "€0",
          lines: [
            "5 visible Punaises",
            "Simple colors",
            "Basic floating notes",
            "Simple manual reminder",
          ],
        },
        pro: {
          title: "Pro",
          lines: [
            "Unlimited Punaises",
            "Advanced urgency score",
            "Anti-forget mode",
            "Smart clean desktop",
            "Google Calendar and Apple Reminders",
            "iCloud + encrypted backup",
            "File, app, site, and email context",
            "Activation after payment",
          ],
        },
      },
    },
    license: {
      step1: "Step 1 - license key",
      title: "Prepare your Pro key",
      intro:
        "The request is tied to your Stripe payment. The signed key appears after payment confirmation.",
      yourKey: "Request",
      creating: "Preparing...",
      copied: "Copied",
      copy: "Copy",
      regenerate: "Regenerate",
      bullets: [
        "The free key stays limited to 5 visible Punaises.",
        "The Pro key is server-signed only after Stripe confirmation.",
        "No password or dashboard required at launch.",
      ],
      step2: "Step 2 - Pro upgrade",
      accessTitle: "Choose your access",
      email: "License email",
      emailPlaceholder: "you@example.com",
      monthly: "Monthly",
      monthlyNote: "No commitment",
      annual: "Annual",
      recommended: "Recommended",
      submit: "Create my Pro license",
      stripeNote:
        "Stripe handles payment, cards, invoices, and subscription management. The key stays the simple link between the site and the Mac app.",
    },
    contact: {
      title: "Write to Punaise.",
      intro:
        "Support, license, Pro purchase, or install issue: the message lands in the site’s private follow-up log.",
      response: "Reply using the email provided in the form",
      sent: "Message received. You can reply from the email the user left.",
      error: "A valid email or message is missing.",
      name: "Name",
      namePlaceholder: "Your name",
      subject: "Subject",
      subjectPlaceholder: "License, payment, installation...",
      message: "Message",
      messagePlaceholder: "Explain the request...",
      send: "Send",
      privateNote: "Messages are kept in the site’s private follow-up log.",
    },
    merci: {
      title: "Payment received",
      planMonthly: "monthly",
      planAnnual: "annual",
      intro:
        "Your {plan} Pro access is being validated. You can already download Punaise and keep this page nearby.",
      keyTitle: "License key",
      keyText:
        "It is signed by Punaise. Paste it into the Mac app to unlock Pro.",
      download: "Download Punaise",
      back: "Back",
    },
    unavailable: {
      title: "Stripe is not configured yet",
      intro:
        "The license page is ready. The monthly and annual Stripe prices still need to be connected to activate payment.",
      offers: "See plans",
      create: "Create a license",
    },
  },
} as const;
