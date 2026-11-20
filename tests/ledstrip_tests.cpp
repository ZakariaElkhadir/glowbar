#include <QDir>
#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

#include "backend.h"
#include "protocol.h"
#include "theme.h"
#include "translator.h"

class LedstripTests : public QObject {
    Q_OBJECT

private slots:
    void powerPackets()
    {
        QCOMPARE(Protocol::power(true).toHex(' '), QByteArray("7e ff 04 01 ff ff ff ff ef"));
        QCOMPARE(Protocol::power(false).toHex(' '), QByteArray("7e ff 04 00 ff ff ff ff ef"));
    }

    void colorPacket()
    {
        QCOMPARE(Protocol::color(QColor(255, 128, 0), 100).toHex(' '), QByteArray("7e ff 05 03 ff 80 00 ff ef"));
    }

    void brightnessScalesTheColor()
    {
        QCOMPARE(Protocol::scaled(QColor(255, 100, 0), 50), QColor(128, 50, 0));
        QCOMPARE(Protocol::color(QColor(255, 255, 255), 0).toHex(' '), QByteArray("7e ff 05 03 00 00 00 ff ef"));
    }

    void pickingAColorTurnsTheStripOn()
    {
        QTemporaryDir dir;
        Backend backend(dir.filePath("ledstrip.conf"), dir.path());
        backend.setPower(false);
        QCOMPARE(backend.pendingPackets(), QList<QByteArray>{Protocol::power(false)});

        backend.setColor(QColor("#00ff00"));
        QVERIFY(backend.power());
        QCOMPARE(backend.pendingPackets(),
                 (QList<QByteArray>{Protocol::power(true), Protocol::color(QColor("#00ff00"), 100)}));
    }

    void brightnessStaysInRange()
    {
        QTemporaryDir dir;
        Backend backend(dir.filePath("ledstrip.conf"), dir.path());
        backend.setBrightness(500);
        QCOMPARE(backend.brightness(), 100);
        backend.setBrightness(-3);
        QCOMPARE(backend.brightness(), 5);
    }

    void lightIsRemembered()
    {
        QTemporaryDir dir;
        {
            Backend backend(dir.filePath("ledstrip.conf"), dir.path());
            backend.setColor(QColor("#123456"));
            backend.setBrightness(40);
        }
        Backend backend(dir.filePath("ledstrip.conf"), dir.path());
        QCOMPARE(backend.color(), QColor("#123456"));
        QCOMPARE(backend.brightness(), 40);
        QVERIFY(backend.pendingPackets().isEmpty());
    }

    void themeLightPrefersKeyboardRgb()
    {
        QTemporaryDir dir;
        write(dir.filePath("colors.toml"), "accent = \"#112233\"\n");
        Backend backend(dir.filePath("ledstrip.conf"), dir.path());
        QCOMPARE(backend.themeLightColor(), QColor("#112233"));

        // Tokyo Night writes it without the hash.
        write(dir.filePath("keyboard.rgb"), "ff00ff\n");
        QCOMPARE(backend.themeLightColor(), QColor("#ff00ff"));
    }

    void themeLightFallsBack()
    {
        QTemporaryDir dir;
        Backend backend(dir.filePath("ledstrip.conf"), dir.path());
        QCOMPARE(backend.themeLightColor(), QColor("#FFD60A"));
    }

    void themeFallsBack()
    {
        QTemporaryDir dir;
        Theme theme(dir.path());
        QCOMPARE(theme.accent(), QString("#FFD60A"));
        QCOMPARE(theme.accentForeground(), QString("black"));
    }

    void themeReadsAccent()
    {
        QTemporaryDir dir;
        QDir(dir.path()).mkpath("theme");
        write(dir.path() + "/theme/colors.toml", "accent = \"#112233\"\n");

        Theme theme(dir.path());
        QCOMPARE(theme.accent(), QString("#112233"));
        QCOMPARE(theme.accentForeground(), QString("white"));
    }

    void themeFollowsHyprlandRounding()
    {
        QTemporaryDir dir;
        const QString response = dir.filePath("response.json"), command = dir.filePath("hyprctl");
        write(command, "#!/bin/sh\ncat '" + response.toUtf8() + "'\n");
        QVERIFY(QFile::setPermissions(command, QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner));
        write(response, "{\"int\":0}");

        Theme theme(dir.path(), nullptr, command);
        QCOMPARE(theme.radius(), 0);
        write(response, "{\"int\":6}");
        QTRY_COMPARE(theme.radius(), 6);
    }

    void translatorFallsBackToEnglish()
    {
        QTemporaryDir dir;
        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("en"));
        QVERIFY(translator.translate("Main", "Retry").isNull());
    }

    void translatorReadsBundledCatalogs()
    {
        QTemporaryDir dir;
        write(dir.path() + "/language", "fr\n");
        Translator translator(dir.path() + "/language", ":/i18n");
        QCOMPARE(translator.translate("Main", "Retry"), QString("Réessayer"));
    }

    void translatorFollowsTheLanguageFile()
    {
        QTemporaryDir dir;
        write(dir.path() + "/language", "pt-BR\n");
        write(dir.path() + "/pt.json", R"({"Save": "Guardar", "Open": "Abrir"})");
        write(dir.path() + "/pt-BR.json", R"({"Save": "Salvar"})");

        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("pt-BR"));
        QCOMPARE(translator.translate("Main", "Save"), QString("Salvar"));
        QCOMPARE(translator.translate("Main", "Open"), QString("Abrir"));
        QVERIFY(translator.translate("Main", "Quit").isNull());
    }

private:
    static void write(const QString &path, const QByteArray &contents)
    {
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write(contents);
    }
};

QTEST_MAIN(LedstripTests)
#include "ledstrip_tests.moc"
