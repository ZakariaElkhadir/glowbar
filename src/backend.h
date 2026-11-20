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

// Finds the strip over Bluetooth LE, keeps a connection to it open, and sends
// it the light the window asks for. The controller never reports its own
// state, so the last light set here is remembered and treated as the truth.
class Backend : public QObject {
    Q_OBJECT
    // searching, connecting, reconnecting, ready, noAdapter, bluetoothOff,
    // notFound, or error.
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY stateChanged)
    Q_PROPERTY(bool power READ power NOTIFY lightChanged)
    Q_PROPERTY(QColor color READ color NOTIFY lightChanged)
    Q_PROPERTY(int brightness READ brightness NOTIFY lightChanged)
    Q_PROPERTY(QColor output READ output NOTIFY lightChanged)

public:
    explicit Backend(const QString &settingsPath = {}, const QString &themeDirectory = {},
                     QObject *parent = nullptr);
    ~Backend() override;

    QString state() const { return m_state; }
    QString error() const { return m_error; }
    QString deviceName() const { return m_device.name(); }
    bool power() const { return m_power; }
    QColor color() const { return m_color; }
    int brightness() const { return m_brightness; }
    QColor output() const;

    Q_INVOKABLE void connectToStrip();
    Q_INVOKABLE void setPower(bool on);
    Q_INVOKABLE void togglePower() { setPower(!m_power); }
    Q_INVOKABLE void setColor(const QColor &color);
    Q_INVOKABLE void setBrightness(int brightness);
    Q_INVOKABLE void useThemeColor();

    // The theme's lighting color: keyboard.rgb, which Omarchy writes for RGB
    // keyboards, else the theme accent.
    QColor themeLightColor() const;

    // What would go to the strip on the next write.
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

    QTimer m_flushTimer;
    QTimer m_reconnectTimer;
    QTimer m_connectTimeout;
    QTimer m_saveTimer;
};
