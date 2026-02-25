#!/usr/bin/env bash
set -euo pipefail

# ---- Configuration ----
APP_NAME="MiniStock"
BUNDLE_ID="com.atheimuz.MiniStock"
VERSION="${1:-1.0.0}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/.build"
RELEASE_DIR="${PROJECT_DIR}/release"
APP_BUNDLE="${RELEASE_DIR}/${APP_NAME}.app"

cd "${PROJECT_DIR}"

# ---- Clean ----
rm -rf "${RELEASE_DIR}"
mkdir -p "${RELEASE_DIR}"

# ---- Build ----
echo "==> Building arm64..."
swift build -c release --arch arm64

echo "==> Building x86_64..."
swift build -c release --arch x86_64

# ---- Create universal binary ----
echo "==> Creating universal binary..."
lipo -create \
  "${BUILD_DIR}/arm64-apple-macosx/release/${APP_NAME}" \
  "${BUILD_DIR}/x86_64-apple-macosx/release/${APP_NAME}" \
  -output "${RELEASE_DIR}/${APP_NAME}-universal"

# ---- Assemble .app bundle ----
echo "==> Assembling .app bundle..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Executable
cp "${RELEASE_DIR}/${APP_NAME}-universal" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Info.plist
cp "${PROJECT_DIR}/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" "${APP_BUNDLE}/Contents/Info.plist"

# Resource bundle → Contents/Resources/ (codesign requires sealed bundle root)
RESOURCE_BUNDLE="${BUILD_DIR}/arm64-apple-macosx/release/${APP_NAME}_${APP_NAME}.bundle"
if [ -d "${RESOURCE_BUNDLE}" ]; then
  cp -R "${RESOURCE_BUNDLE}" "${APP_BUNDLE}/Contents/Resources/${APP_NAME}_${APP_NAME}.bundle"
fi

# App icon
if [ -f "${PROJECT_DIR}/AppIcon.icns" ]; then
  cp "${PROJECT_DIR}/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

# ---- Ad-hoc code signing ----
echo "==> Signing (ad-hoc)..."
# Sign only the main executable (SPM resource bundle is a plain directory, not a signable bundle)
codesign --force --sign - --identifier "${BUNDLE_ID}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
codesign --force --sign - --identifier "${BUNDLE_ID}" "${APP_BUNDLE}"

# ---- Verify ----
echo "==> Verifying..."
codesign --verify "${APP_BUNDLE}" && echo "    Signature OK"

# ---- Create DMG ----
echo "==> Creating DMG..."
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
TMP_DMG="${RELEASE_DIR}/tmp.dmg"
FINAL_DMG="${RELEASE_DIR}/${DMG_NAME}"
STAGING="${RELEASE_DIR}/dmg-staging"

mkdir -p "${STAGING}"
cp -R "${APP_BUNDLE}" "${STAGING}/"
ln -s /Applications "${STAGING}/Applications"

hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING}" \
  -ov \
  -format UDRW \
  "${TMP_DMG}"

hdiutil convert "${TMP_DMG}" -format UDZO -o "${FINAL_DMG}"

# ---- Cleanup ----
rm -f "${TMP_DMG}"
rm -f "${RELEASE_DIR}/${APP_NAME}-universal"
rm -rf "${STAGING}"

echo ""
echo "==> Done!"
echo "    ${FINAL_DMG}"
ls -lh "${FINAL_DMG}"
