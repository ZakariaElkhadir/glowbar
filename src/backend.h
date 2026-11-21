#pragma once

#include <QBluetoothDeviceInfo>
#include <QColor>
#include <QLowEnergyCharacteristic>
#include <QObject>
#include <QPointer>
#include <QTimer>

class QBluetoothDeviceDiscoveryAgent;
class QBluetoothLocalDevice;
class QLowEnergyController;
class QLowEnergyService;
class StripProtocol;

/**
 * @brief Bluetooth LE backend for controlling an LED strip.
 *
 * Discovers the strip, maintains an open connection, and writes the light
 * state requested by the UI.  Because the strip controller never reports its
 * own state, the last value set here is treated as the source of truth.
 *
 * The @c state property is one of:
 * - @c "searching"    — scanning for the device
 * - @c "connecting"   — first connection attempt
 * - @c "reconnecting" — restoring a lost connection
 * - @c "ready"        — connected and accepting writes
 * - @c "noAdapter"    — no Bluetooth adapter found
 * - @c "bluetoothOff" — adapter present but powered off
 * - @c "notFound"     — scan completed without finding the strip
 * - @c "error"        — unrecoverable error; see the @c error property
 */
class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY stateChanged)
    Q_PROPERTY(bool power READ power NOTIFY lightChanged)
    Q_PROPERTY(QColor color READ color NOTIFY lightChanged)
    Q_PROPERTY(int brightness READ brightness NOTIFY lightChanged)
    Q_PROPERTY(QColor output READ output NOTIFY lightChanged)

public:
    /**
     * @brief Constructs the backend and restores persisted light settings.
     * @param settingsPath   Path to the INI settings file.
     *                       Defaults to @c ~/.config/ledstrip/ledstrip.conf.
     * @param themeDirectory Directory containing the Omarchy theme files.
     *                       Defaults to @c ~/.local/state/omarchy/current/theme.
     * @param parent         Optional QObject parent.
     */
    explicit Backend(const QString &settingsPath = {}, const QString &themeDirectory = {},
                     QObject *parent = nullptr);

    /** @brief Flushes any pending save and tears down the BLE connection. */
    ~Backend() override;

    QString state() const { return m_state; }
    QString error() const { return m_error; }
    QString deviceName() const { return m_device.name(); }
    bool power() const { return m_power; }
    QColor color() const { return m_color; }
    int brightness() const { return m_brightness; }

    /** @brief Returns the color that will actually be sent to the strip (brightness-scaled, or black when off). */
    QColor output() const;

    /** @brief Starts or restarts a BLE device scan and connects to the first matching strip. */
    Q_INVOKABLE void connectToStrip();

    /** @brief Turns the strip on or off and schedules a flush. */
    Q_INVOKABLE void setPower(bool on);

    /** @brief Toggles the power state. */
    Q_INVOKABLE void togglePower() { setPower(!m_power); }

    /** @brief Sets @p color as the active color and schedules a flush (turns on if currently off). */
    Q_INVOKABLE void setColor(const QColor &color);

    /** @brief Sets brightness in the range [5, 100] and schedules a flush. */
    Q_INVOKABLE void setBrightness(int brightness);

    /** @brief Applies the Omarchy theme's lighting color as the active color. */
    Q_INVOKABLE void useThemeColor();

    /**
     * @brief Returns the Omarchy theme's lighting color.
     *
     * Prefers @c keyboard.rgb (written by Omarchy for RGB keyboards) and
     * falls back to the theme accent color.
     */
    QColor themeLightColor() const;

    /** @brief Returns the BLE packets that would be sent on the next flush. */
    QList<QByteArray> pendingPackets() const;

signals:
    void stateChanged();
    void lightChanged();

private:
    void setState(const QString &state, const QString &error = {});
    void lightEdited();
    void flush();
    void save();
    void cleanup();
    void onDeviceDiscovered(const QBluetoothDeviceInfo &info);
    void connectDevice();
    void setupService();
    void connectionLost();
    void restart();

    QString m_settingsPath;
    QString m_themeDirectory;

    QString m_state = "searching";
    QString m_error;
    bool m_power = true;
    QColor m_color = Qt::white;
    int m_brightness = 100;
    bool m_powerDirty = false;
    bool m_colorDirty = false;

    QString m_address;
    QBluetoothDeviceInfo m_device;
    QBluetoothLocalDevice *m_local = nullptr;
    QPointer<QBluetoothDeviceDiscoveryAgent> m_agent;
    QPointer<QLowEnergyController> m_controller;
    QPointer<QLowEnergyService> m_service;
    QLowEnergyCharacteristic m_characteristic;
    int m_failures = 0;
    StripProtocol *m_protocol = nullptr;
    QString m_protocolName;

    QTimer m_flushTimer;
    QTimer m_reconnectTimer;
    QTimer m_connectTimeout;
    QTimer m_saveTimer;
};
