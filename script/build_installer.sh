#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Punaise"
BUNDLE_ID="com.artisaul.Punaise"
VERSION="${VERSION:-0.1.6}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
MIN_SYSTEM_VERSION="13.0"
PUBLIC_RELEASE="${PUBLIC_RELEASE:-0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_DIR="$DIST_DIR/release"
INSTALLER_DIR="$DIST_DIR/installers"
DMG_STAGING_DIR="$DIST_DIR/dmg-staging"

APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

DMG_PATH="$INSTALLER_DIR/$APP_NAME-$VERSION.dmg"
PKG_PATH="$INSTALLER_DIR/$APP_NAME-$VERSION.pkg"

NOTARY_ARGS=()
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  NOTARY_ARGS=(--keychain-profile "$NOTARY_PROFILE")
elif [[ -n "${APPLE_ID:-}" || -n "${APP_SPECIFIC_PASSWORD:-}" || -n "${TEAM_ID:-}" ]]; then
  if [[ -z "${APPLE_ID:-}" || -z "${APP_SPECIFIC_PASSWORD:-}" || -z "${TEAM_ID:-}" ]]; then
    echo "APPLE_ID, APP_SPECIFIC_PASSWORD and TEAM_ID must be set together." >&2
    exit 2
  fi
  NOTARY_ARGS=(--apple-id "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD" --team-id "$TEAM_ID")
fi

if [[ "$PUBLIC_RELEASE" == "1" ]]; then
  if [[ -z "${CODESIGN_IDENTITY:-}" ]]; then
    echo "PUBLIC_RELEASE=1 requires CODESIGN_IDENTITY, for example: Developer ID Application: Name (TEAMID)" >&2
    exit 2
  fi
  if [[ -z "${INSTALLER_SIGN_IDENTITY:-}" ]]; then
    echo "PUBLIC_RELEASE=1 requires INSTALLER_SIGN_IDENTITY, for example: Developer ID Installer: Name (TEAMID)" >&2
    exit 2
  fi
  if [[ "${#NOTARY_ARGS[@]}" -eq 0 ]]; then
    echo "PUBLIC_RELEASE=1 requires NOTARY_PROFILE or APPLE_ID + APP_SPECIFIC_PASSWORD + TEAM_ID." >&2
    exit 2
  fi
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

mkdir -p "$DIST_DIR" "$RELEASE_DIR" "$INSTALLER_DIR"

echo "==> Building $APP_NAME $VERSION release"
swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"

echo "==> Staging app bundle"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$ROOT_DIR/Resources/Punaise.icns" "$APP_RESOURCES/Punaise.icns"
cp "$ROOT_DIR/Resources/PunaiseIcon1024.png" "$APP_RESOURCES/PunaiseIcon1024.png"
find "$ROOT_DIR/Resources" -maxdepth 1 -type d -name "*.lproj" -exec cp -R {} "$APP_RESOURCES/" \;

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>fr</string>
  <key>CFBundleAllowMixedLocalizations</key>
  <true/>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>Punaise</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSCalendarsUsageDescription</key>
  <string>Punaise lit les événements de Calendrier pour créer des Punaises depuis Google Agenda.</string>
  <key>NSCalendarsFullAccessUsageDescription</key>
  <string>Punaise lit les événements de Calendrier pour créer des Punaises depuis Google Agenda.</string>
  <key>NSRemindersUsageDescription</key>
  <string>Punaise lit les rappels pour créer des Punaises depuis Apple Reminders.</string>
  <key>NSRemindersFullAccessUsageDescription</key>
  <string>Punaise lit les rappels pour créer des Punaises depuis Apple Reminders.</string>
  <key>NSSupportsAutomaticGraphicsSwitching</key>
  <true/>
</dict>
</plist>
PLIST

plutil -lint "$INFO_PLIST"

echo "==> Signing app bundle"
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
else
  codesign --force --deep --sign - "$APP_BUNDLE"
fi
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "==> Creating DMG installer"
rm -rf "$DMG_STAGING_DIR" "$DMG_PATH"
mkdir -p "$DMG_STAGING_DIR"
cp -R "$APP_BUNDLE" "$DMG_STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

cat >"$DMG_STAGING_DIR/Installer Punaise.txt" <<TXT
Punaise — Épingle ce qui presse.

Installation :
1. Glisse Punaise.app dans Applications.
2. Ouvre Punaise depuis Applications.
3. Si macOS affiche un avertissement de sécurité pour cette build locale, fais clic droit > Ouvrir.

Cette build locale est signée en ad-hoc sauf si CODESIGN_IDENTITY est défini.
TXT

hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --timestamp --sign "$CODESIGN_IDENTITY" "$DMG_PATH"
fi

hdiutil verify "$DMG_PATH"

echo "==> Creating PKG installer"
rm -f "$PKG_PATH"
pkgbuild \
  --component "$APP_BUNDLE" \
  --install-location /Applications \
  --identifier "$BUNDLE_ID.installer" \
  --version "$VERSION" \
  "$PKG_PATH"

if [[ -n "${INSTALLER_SIGN_IDENTITY:-}" ]] && command -v productsign >/dev/null 2>&1; then
  SIGNED_PKG="$INSTALLER_DIR/$APP_NAME-$VERSION-signed.pkg"
  productsign --sign "$INSTALLER_SIGN_IDENTITY" "$PKG_PATH" "$SIGNED_PKG"
  mv "$SIGNED_PKG" "$PKG_PATH"
fi

pkgutil --payload-files "$PKG_PATH" >/dev/null

if [[ "${#NOTARY_ARGS[@]}" -gt 0 ]]; then
  echo "==> Notarizing DMG"
  xcrun notarytool submit "$DMG_PATH" \
    "${NOTARY_ARGS[@]}" \
    --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
  spctl -a -vvv -t open "$DMG_PATH"

  echo "==> Notarizing PKG"
  xcrun notarytool submit "$PKG_PATH" \
    "${NOTARY_ARGS[@]}" \
    --wait
  xcrun stapler staple "$PKG_PATH"
  xcrun stapler validate "$PKG_PATH"
  spctl -a -vvv -t install "$PKG_PATH"
fi

echo
echo "Created:"
echo "  $DMG_PATH"
echo "  $PKG_PATH"
echo
echo "For public distribution, sign with Developer ID and notarize the DMG or PKG."
