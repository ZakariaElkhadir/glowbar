#pragma once

#include <QFileSystemWatcher>
#include <QObject>
#include <QProcess>
#include <QTimer>

/**
 * @brief Live-reloading Omarchy theme provider.
 *
 * Watches the current-theme directory for changes and re-reads the accent
 * color whenever the theme is switched.  Corner radius is queried from
 * Hyprland via @c hyprctl on a 1-second poll; without Hyprland the radius
 * stays at 0 (sharp corners).
 *
 * Theme watching follows the approach used in Omacut (MIT, David Heinemeier
 * Hansson).
 */
class Theme : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString accent READ accent NOTIFY changed)
    Q_PROPERTY(QString accentForeground READ accentForeground NOTIFY changed)
    Q_PROPERTY(int radius READ radius NOTIFY changed)
    Q_PROPERTY(bool dark READ dark NOTIFY changed)

public:
    /**
     * @brief Constructs the theme watcher and loads the initial theme.
     * @param currentDirectory  Path to the Omarchy current-theme directory.
     *                          Defaults to @c ~/.local/state/omarchy/current.
     * @param parent            Optional QObject parent.
     * @param hyprctl           Path to the @c hyprctl executable (for tests).
     *                          Auto-detected when empty.
     */
    explicit Theme(const QString &currentDirectory = {}, QObject *parent = nullptr, const QString &hyprctl = {});

    /** @brief Kills any running @c hyprctl process. */
    ~Theme() override;

    /** @brief Returns the current accent color as a hex string (e.g. @c "#FFD60A"). */
    QString accent() const { return m_accent; }

    /**
     * @brief Returns @c "black" or @c "white", whichever is more legible on the accent color.
     *
     * Uses the WCAG relative-luminance formula.
     */
    QString accentForeground() const;

    /** @brief Returns @c true unless the Omarchy theme declares itself light. */
    bool dark() const { return m_dark; }

    /**
     * @brief Reads whether the theme in @p directory is dark.
     *
     * Looks for @c mode = "light" in @c colors.toml, or a @c light.mode marker
     * file (older Omarchy themes).  Defaults to dark.
     */
    static bool readDark(const QString &directory);

    /** @brief Returns the current Hyprland corner radius in pixels (0 when unavailable). */
    int radius() const { return m_radius; }

    /**
     * @brief Reads the accent color from a @c colors.toml file at @p path.
     * @return The hex color string, or @c "#FFD60A" when the file is missing or unparseable.
     */
    static QString readAccent(const QString &path);

signals:
    /** @brief Emitted when the accent color or corner radius changes. */
    void changed();

private:
    void reload();
    void refreshRounding();

    QString m_directory;
    QString m_accent = "#FFD60A";
    bool m_dark = true;
    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
    QString m_hyprctl;
    int m_radius = 0;
    QProcess m_roundingProcess;
    QTimer m_roundingPoll, m_roundingTimeout;
};
