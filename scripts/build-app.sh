#!/bin/sh
# Собирает build/PomodoroBar.app. Уведомления macOS работают только из .app, не из `swift run`.
set -e
cd "$(dirname "$0")/.."

swift build -c release

APP=build/PomodoroBar.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/PomodoroBar "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"

echo "Готово: $APP"
