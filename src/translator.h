#pragma once

#include <QFileSystemWatcher>
#include <QHash>
#include <QJsonValue>
#include <QLocale>
#include <QTimer>
#include <QTranslator>

/**
 * @brief Live-reloading translator driven by Omarchy's language selection.
 *
 * Catalogs are flat JSON objects that map English source text to its
 * translation, one file per Omarchy language code (e.g. @c i18n/da.json,
 * @c i18n/pt-BR.json). QML uses plain @c qsTr("Save") and C++ uses
 * @c tr("Save"); no context IDs are needed.
 *
 * A counted string — @c qsTr("%n clips","",count) — maps to a JSON object
 * of CLDR plural forms keyed by category:
 * @code{.json}
 * { "one": "%n klip", "other": "%n klip" }
 * @endcode
 *
 * The translator watches the language file and its parent directory so that
 * a language change made in Omarchy's Setup › Language is picked up
 * automatically without restarting the application.
 */
class Translator : public QTranslator {
    Q_OBJECT
    Q_PROPERTY(QString language READ language NOTIFY changed)

public:
    /**
     * @brief Constructs the translator and performs an initial load.
     * @param languageFile     Path to the Omarchy language file.
     *                         Defaults to @c ~/.config/omarchy/language.
     * @param catalogDirectory Resource or file-system directory that contains
     *                         the per-language JSON catalog files.
     *                         Defaults to @c :/i18n (compiled-in resources).
     * @param parent           Optional QObject parent.
     */
    explicit Translator(const QString &languageFile = {}, const QString &catalogDirectory = ":/i18n",
                        QObject *parent = nullptr);

    /** @brief Returns the active BCP 47 language code (e.g. @c "en", @c "pt-BR"). */
    QString language() const { return m_language; }

    /** @brief Returns @c true when no translation strings are loaded (English pass-through). */
    bool isEmpty() const override { return m_strings.isEmpty(); }

    /**
     * @brief Looks up @p sourceText in the active catalog.
     *
     * When @p n is non-negative the string is treated as a counted form and
     * the appropriate CLDR plural category is selected via pluralCategory().
     * Returns an empty string (Qt's signal to show the English source) when
     * no translation is found.
     */
    QString translate(const char *context, const char *sourceText, const char *disambiguation = nullptr,
                      int n = -1) const override;

    /**
     * @brief Reads the BCP 47 language code from @p path.
     *
     * Expects exactly one registry code on the first line.  Returns @c "en"
     * when the file is missing, unreadable, or its first line is not a valid
     * code.
     */
    static QString readLanguage(const QString &path);

    /**
     * @brief Returns the CLDR cardinal plural category for @p count in @p language.
     *
     * Implements the same rules as Omarchy's @c shell/Commons/Plural.js and
     * covers every language shipped with Omarchy.
     *
     * @param language BCP 47 language code.
     * @param count    The integer count that selects the plural form.
     * @return One of @c "zero", @c "one", @c "two", @c "few", @c "many", or @c "other".
     */
    static QString pluralCategory(const QString &language, long long count);

    /**
     * @brief Returns the QLocale Omarchy uses to format numbers and dates for @p language.
     *
     * Reads @c OMARCHY_PATH/default/i18n/locales.json so that, for example,
     * Arabic uses Western digits as the desktop does.  Falls back to Qt's own
     * locale for the code when the registry is unavailable.
     */
    static QLocale formatLocale(const QString &language);

signals:
    /** @brief Emitted after the active language or its strings change. */
    void changed();

private:
    /** @brief Re-reads the language file, loads the matching catalog, and emits changed(). */
    void reload();

    QString m_languageFile;
    QString m_catalogDirectory;
    QString m_language;
    QHash<QString, QJsonValue> m_strings;
    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
};
