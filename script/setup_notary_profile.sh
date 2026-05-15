#!/usr/bin/env bash
set -euo pipefail

PROFILE="${NOTARY_PROFILE:-punaise-notary}"

cat <<TXT
Ce script enregistre les identifiants de notarisation Apple dans le trousseau macOS.
Il faut un compte Apple Developer Program actif et un mot de passe specifique a l'app.

Profil cree : $PROFILE
TXT

read -r -p "Apple ID du compte developpeur : " APPLE_ID
read -r -p "Team ID Apple Developer : " TEAM_ID
read -r -s -p "Mot de passe specifique a l'app : " APP_SPECIFIC_PASSWORD
echo

xcrun notarytool store-credentials "$PROFILE" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD"

echo
echo "Profil de notarisation enregistre : $PROFILE"
echo "Tu peux maintenant lancer une release publique avec :"
echo
echo "PUBLIC_RELEASE=1 \\"
echo "CODESIGN_IDENTITY=\"Developer ID Application: Nom (TEAMID)\" \\"
echo "INSTALLER_SIGN_IDENTITY=\"Developer ID Installer: Nom (TEAMID)\" \\"
echo "NOTARY_PROFILE=\"$PROFILE\" \\"
echo "./script/build_installer.sh"
