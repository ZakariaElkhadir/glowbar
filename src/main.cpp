/**
 * @file main.cpp
 * @brief ledstrip — control a Bluetooth LED strip from the desktop.
 */

#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTimer>
#include <QUrl>

#include "backend.h"
#include "theme.h"
#include "translator.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("ledstrip");
    app.setApplicationVersion("0.1.0");

    // Matches the window to ledstrip.desktop so the compositor (Wayland
    // app_id) and the launcher pick up the installed icon.
    app.setDesktopFileName("ledstrip");
    app.setWindowIcon(QIcon::fromTheme("ledstrip"));

    // Every control is drawn by the app, so the plain style is enough.
    QQuickStyle::setStyle("Basic");

    // The neobrutalist look's typefaces ship with the app (SIL OFL).
    for (const char *font : {"ArchivoBlack-Regular", "SpaceGrotesk", "SpaceMono-Regular", "SpaceMono-Bold"})
        QFontDatabase::addApplicationFont(QString(":/fonts/%1.ttf").arg(font));

    // Install before anything is translated; every qsTr() binding is
    // re-evaluated automatically when the Omarchy language changes.
    Translator translator;
    app.installTranslator(&translator);

    Theme theme;
    Backend backend;

    QQmlApplicationEngine engine;
    QObject::connect(&translator, &Translator::changed, &engine, &QQmlEngine::retranslate);
    engine.rootContext()->setContextProperty("translator", &translator);
    engine.rootContext()->setContextProperty("theme", &theme);
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty())
        return 1;

    // Defer the initial scan until the window is visible so the UI can show
    // what is happening while the search runs.
    QTimer::singleShot(0, &backend, &Backend::connectToStrip);

    return app.exec();
}
