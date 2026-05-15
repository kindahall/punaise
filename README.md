# Punaise

Punaise est une app macOS qui transforme les échéances importantes en punaises visibles sur le bureau.

Elle ne cherche pas à remplacer un gestionnaire de tâches complet. Son rôle est de matérialiser l’urgence : score de pression, bureau propre intelligent, mode anti-oubli, mini-fenêtre “Ce qui presse”, import Google Agenda, Apple Reminders et sauvegarde chiffrée.

## Fonctionnalités

- Punaises flottantes sur le bureau macOS
- Moteur d’urgence dynamique avec score de pression
- Mode anti-oubli : halo, vibration, premier plan, état noir dépassé
- Bureau propre intelligent par zones d’urgence
- Ajout naturel en français
- Templates métier : facture, client, livraison, appel, contrat, projet, administratif
- Import intelligent Google Agenda
- Import intelligent Apple Reminders
- Pièces jointes contextuelles : fichier, dossier, app, site, mail
- Mini-fenêtre “Ce qui presse”
- Sauvegarde chiffrée locale et miroir iCloud Drive optionnel

## Développement

Prérequis :

- macOS 13 ou plus récent
- Swift Package Manager

Construire :

```bash
swift build
```

Lancer l’app locale :

```bash
./script/build_and_run.sh
```

Tester :

```bash
./script/test.sh
```

Créer les installateurs :

```bash
./script/build_installer.sh
```

Les artefacts générés sont placés dans `dist/` et ne sont pas versionnés.

## Distribution

Le script d’installation génère :

- `dist/installers/Punaise-0.1.6.dmg`
- `dist/installers/Punaise-0.1.6.pkg`

Par défaut, la build locale est signée en ad-hoc. Elle peut servir aux tests internes, mais macOS Gatekeeper affichera un avertissement si elle est téléchargée depuis Internet.

Pour une distribution publique, il faut signer avec un certificat Apple Developer ID, notariser les installateurs, puis stapler le ticket de notarisation :

```bash
security find-identity -v -p codesigning
xcrun notarytool store-credentials "punaise-notary" \
  --apple-id "compte@exemple.com" \
  --team-id "TEAMID" \
  --password "mot-de-passe-specifique-app"

PUBLIC_RELEASE=1 \
CODESIGN_IDENTITY="Developer ID Application: Nom (TEAMID)" \
INSTALLER_SIGN_IDENTITY="Developer ID Installer: Nom (TEAMID)" \
NOTARY_PROFILE="punaise-notary" \
./script/build_installer.sh
```

En `PUBLIC_RELEASE=1`, le script refuse de produire une release si la signature Developer ID ou la notarisation manque.
