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

Créer les installateurs :

```bash
./script/build_installer.sh
```

Les artefacts générés sont placés dans `dist/` et ne sont pas versionnés.

## Distribution

Le script d’installation génère :

- `dist/installers/Punaise-0.1.0.dmg`
- `dist/installers/Punaise-0.1.0.pkg`

Par défaut, la build locale est signée en ad-hoc. Pour une distribution publique, définir une identité Developer ID et notariser le DMG ou le PKG.
