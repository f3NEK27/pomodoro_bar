#!/bin/sh
# Собирает build/PomodoroBar.app. Уведомления macOS работают только из .app, не из `swift run`.
# С флагом --install ещё и кладёт приложение в /Applications и запускает его.
set -e
cd "$(dirname "$0")/.."

swift build -c release

APP=build/PomodoroBar.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/PomodoroBar "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"

if [ "$1" = "--install" ]; then
    # Закрыть запущенную копию, чтобы заменить её новой.
    osascript -e 'quit app "PomodoroBar"' 2>/dev/null || true
    rm -rf /Applications/PomodoroBar.app
    cp -R "$APP" /Applications/
    open /Applications/PomodoroBar.app
    echo "Установлено: /Applications/PomodoroBar.app"
else
    echo "Готово: $APP"
fi
