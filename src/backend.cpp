#include "backend.h"
#include "stripprotocol.h"

#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothLocalDevice>
#include <QBluetoothUuid>
#include <QDir>
#include <QFile>
#include <QLowEnergyController>
#include <QLowEnergyService>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>

namespace {
const QColor kFallbackColor("#FFD60A");

// The app was called ledstrip before; carry its settings (the remembered
// strip, color and brightness) over to the new name once.
QString defaultSettingsPath() {
    const QString config = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
    const QString path = config + "/glowbar/glowbar.conf";
    const QString legacy = config + "/ledstrip/ledstrip.conf";
    if (!QFile::exists(path) && QFile::exists(legacy)) {
        QDir().mkpath(config + "/glowbar");
        QFile::copy(legacy, path);
    }
    return path;
}
}

Backend::Backend(const QString &settingsPath, const QString &themeDirectory, QObject *parent)
    : QObject(parent),
      m_settingsPath(settingsPath.isEmpty()
                         ? defaultSettingsPath()
                         : settingsPath),
      m_themeDirectory(themeDirectory.isEmpty() ? QDir::homePath() + "/.local/state/omarchy/current/theme"
                                                : themeDirectory) {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    m_power = settings.value("power", true).toBool();
    const QColor saved(settings.value("color", "#ffffff").toString());
    m_color = saved.isValid() ? saved : QColor(Qt::white);
    m_brightness = qBound(5, settings.value("brightness", 100).toInt(), 100);
    m_address = settings.value("address").toString();
    m_protocolName = settings.value("protocol").toString();

    // Restore the saved protocol, or default to the first registered one.
    for (auto *p : StripProtocol::all()) {
        if (p->name() == m_protocolName) {
            m_protocol = p;
            break;
        }
    }
    if (!m_protocol && !StripProtocol::all().isEmpty())
        m_protocol = StripProtocol::all().first();

    // Throttle rapid slider drags: send the latest color every 60 ms to keep
    // the strip smooth without flooding the BLE connection.
    m_flushTimer.setSingleShot(true);
    m_flushTimer.setInterval(60);
    connect(&m_flushTimer, &QTimer::timeout, this, &Backend::flush);

    m_reconnectTimer.setSingleShot(true);
    m_reconnectTimer.setInterval(800);
    connect(&m_reconnectTimer, &QTimer::timeout, this, &Backend::connectDevice);

    // Kill a connection attempt that is neither ready nor refused after a few
    // seconds; this usually means the strip dropped it halfway through setup.
    m_connectTimeout.setSingleShot(true);
    m_connectTimeout.setInterval(6000);
    connect(&m_connectTimeout, &QTimer::timeout, this, &Backend::restart);

    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(500);
    connect(&m_saveTimer, &QTimer::timeout, this, &Backend::save);
}

Backend::~Backend() {
    if (m_saveTimer.isActive())
        save();
    cleanup();
}

QColor Backend::output() const {
    return m_power ? StripProtocol::scaled(m_color, m_brightness) : QColor(Qt::black);
}

QColor Backend::themeLightColor() const {
    QFile keyboard(m_themeDirectory + "/keyboard.rgb");
    if (keyboard.open(QIODevice::ReadOnly)) {
        QString value = QString::fromUtf8(keyboard.readAll()).trimmed();
        if (!value.startsWith('#'))
            value.prepend('#');
        const QColor color(value);
        if (color.isValid())
            return color;
    }
    QFile colors(m_themeDirectory + "/colors.toml");
    if (colors.open(QIODevice::ReadOnly)) {
        static const QRegularExpression accent(R"re(^\s*accent\s*=\s*["'](#[0-9a-fA-F]{6})["'])re",
                                               QRegularExpression::MultilineOption);
        const auto match = accent.match(QString::fromUtf8(colors.readAll()));
        if (match.hasMatch())
            return QColor(match.captured(1));
    }
    return kFallbackColor;
}

QList<QByteArray> Backend::pendingPackets() const {
    if (!m_protocol)
        return {};
    QList<QByteArray> packets;
    if (m_powerDirty)
        packets << (m_power ? m_protocol->powerOnPacket() : m_protocol->powerOffPacket());
    if (m_colorDirty && m_power)
        packets << m_protocol->colorPacket(m_color, m_brightness);
    return packets;
}

void Backend::setPower(bool on) {
    m_power = on;
    m_powerDirty = true;
    // Also resend the color on switch-on so the strip matches the UI even if
    // it was changed from the physical remote in the meantime.
    m_colorDirty = on;
    lightEdited();
}

void Backend::setColor(const QColor &color) {
    if (!color.isValid())
        return;
    m_color = color.toRgb();
    if (!m_power) {
        m_power = true;
        m_powerDirty = true;
    }
    m_colorDirty = true;
    lightEdited();
}

void Backend::setBrightness(int brightness) {
    m_brightness = qBound(5, brightness, 100);
    m_colorDirty = true;
    lightEdited();
}

void Backend::useThemeColor() {
    setColor(themeLightColor());
}

void Backend::lightEdited() {
    emit lightChanged();
    m_saveTimer.start();
    if (!m_flushTimer.isActive())
        m_flushTimer.start();
}

void Backend::flush() {
    // Edits made while the strip is unreachable stay pending and are sent as
    // soon as the connection becomes ready again.
    if (m_state != "ready" || !m_service || !m_characteristic.isValid())
        return;
    const auto mode = m_protocol ? m_protocol->writeMode() : QLowEnergyService::WriteWithoutResponse;
    for (const QByteArray &packet : pendingPackets())
        m_service->writeCharacteristic(m_characteristic, packet, mode);
    m_powerDirty = false;
    m_colorDirty = false;
}

void Backend::save() {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    settings.setValue("power", m_power);
    settings.setValue("color", m_color.name());
    settings.setValue("brightness", m_brightness);
    if (!m_address.isEmpty())
        settings.setValue("address", m_address);
    if (!m_protocolName.isEmpty())
        settings.setValue("protocol", m_protocolName);
}

void Backend::setState(const QString &state, const QString &error) {
    if (state == m_state && error == m_error)
        return;
    m_state = state;
    m_error = error;
    emit stateChanged();
}

void Backend::cleanup() {
    m_reconnectTimer.stop();
    m_connectTimeout.stop();
    if (m_agent) {
        m_agent->disconnect(this);
        m_agent->stop();
        m_agent->deleteLater();
    }
    if (m_service) {
        m_service->disconnect(this);
        m_service->deleteLater();
    }
    if (m_controller) {
        m_controller->disconnect(this);
        m_controller->disconnectFromDevice();
        m_controller->deleteLater();
    }
    // deleteLater() leaves pointers set until the event loop runs; null them
    // so a fresh connection does not accidentally reuse stale objects.
    m_agent = nullptr;
    m_service = nullptr;
    m_controller = nullptr;
    m_characteristic = {};
}

void Backend::connectToStrip() {
    cleanup();
    m_failures = 0;

    if (!m_local) {
        m_local = new QBluetoothLocalDevice(this);
        // Turning Bluetooth on while the window is open reconnects the strip
        // automatically without needing a manual retry.
        connect(m_local, &QBluetoothLocalDevice::hostModeStateChanged, this, [this](auto mode) {
            if (mode != QBluetoothLocalDevice::HostPoweredOff && m_state == "bluetoothOff")
                connectToStrip();
        });
    }
    if (!m_local->isValid()) {
        setState("noAdapter");
        return;
    }
#ifndef Q_OS_MACOS
    // CoreBluetooth on macOS does not expose the adapter power state through
    // QBluetoothLocalDevice; skip the check and let the scan fail naturally.
    if (m_local->hostMode() == QBluetoothLocalDevice::HostPoweredOff) {
        setState("bluetoothOff");
        return;
    }
#endif

    setState("searching");
    m_agent = new QBluetoothDeviceDiscoveryAgent(this);
    m_agent->setLowEnergyDiscoveryTimeout(15000);
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered, this, &Backend::onDeviceDiscovered);
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::deviceUpdated, this,
            [this](const QBluetoothDeviceInfo &info, auto) { onDeviceDiscovered(info); });
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::finished, this, [this] {
        if (m_state == "searching")
            setState("notFound");
    });
    connect(m_agent, &QBluetoothDeviceDiscoveryAgent::errorOccurred, this, [this] {
        setState("error", tr("Bluetooth search failed: %1").arg(m_agent ? m_agent->errorString() : QString()));
    });
    m_agent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
}

void Backend::onDeviceDiscovered(const QBluetoothDeviceInfo &info) {
    if (m_state != "searching")
        return;
    const bool remembered = !m_address.isEmpty() && info.address().toString() == m_address;

    // Try each registered protocol to see if it recognises this device.
    StripProtocol *protocol = nullptr;
    for (auto *p : StripProtocol::all()) {
        if (p->matchesDevice(info)) {
            protocol = p;
            break;
        }
    }

    // A remembered device may have changed its advertised name; fall back to
    // the protocol that was saved with the address last time.
    if (!protocol && remembered) {
        for (auto *p : StripProtocol::all()) {
            if (p->name() == m_protocolName) {
                protocol = p;
                break;
            }
        }
    }
    if (!protocol)
        return;

    m_protocol = protocol;
    m_protocolName = protocol->name();
    m_agent->disconnect(this);
    m_agent->stop();
    m_device = info;
    m_address = info.address().toString();
    save();
    connectDevice();
}

void Backend::connectDevice() {
    if (!m_device.isValid())
        return;
    setState(m_state == "ready" || m_state == "reconnecting" ? "reconnecting" : "connecting");

    if (!m_controller) {
        m_controller = QLowEnergyController::createCentral(m_device, this);
        connect(m_controller, &QLowEnergyController::connected, m_controller, &QLowEnergyController::discoverServices);
        connect(m_controller, &QLowEnergyController::discoveryFinished, this, &Backend::setupService);
        connect(m_controller, &QLowEnergyController::disconnected, this, &Backend::connectionLost);
        connect(m_controller, &QLowEnergyController::errorOccurred, this, &Backend::connectionLost);
    }
    if (m_controller->state() == QLowEnergyController::UnconnectedState)
        m_controller->connectToDevice();
    m_connectTimeout.start();
}

void Backend::setupService() {
    if (m_service) {
        m_service->disconnect(this);
        m_service->deleteLater();
    }
    m_service = m_controller->createServiceObject(m_protocol->serviceUuid(), this);
    if (!m_service) {
        setState("error", tr("This device isn't an LED strip controller this app knows."));
        return;
    }
    connect(m_service, &QLowEnergyService::stateChanged, this, [this](QLowEnergyService::ServiceState s) {
        if (s != QLowEnergyService::RemoteServiceDiscovered)
            return;
        m_characteristic = m_service->characteristic(m_protocol->characteristicUuid());
        if (!m_characteristic.isValid()) {
            setState("error", tr("This device isn't an LED strip controller this app knows."));
            return;
        }
        m_failures = 0;
        m_connectTimeout.stop();
        setState("ready");
        flush();
    });
    // BlueZ does not always notify Qt when the controller drops an idle
    // connection, so a failed write is often the first sign.  Because the
    // light commands are idempotent, resend everything on the next connection.
    connect(m_service, &QLowEnergyService::errorOccurred, this, [this](QLowEnergyService::ServiceError e) {
        if (m_state == "ready" && e != QLowEnergyService::CharacteristicWriteError)
            return;
        m_powerDirty = true;
        m_colorDirty = m_power;
        restart();
    });
    m_service->discoverDetails();
}

void Backend::restart() {
    m_connectTimeout.stop();
    m_characteristic = {};
    if (m_service) {
        m_service->disconnect(this);
        m_service->deleteLater();
        m_service = nullptr;
    }
    if (m_controller) {
        m_controller->disconnect(this);
        m_controller->disconnectFromDevice();
        m_controller->deleteLater();
        m_controller = nullptr;
    }
    connectionLost();
}

void Backend::connectionLost() {
    m_characteristic = {};
    if (m_state != "ready" && m_state != "connecting" && m_state != "reconnecting")
        return;
    // The controller drops idle connections every few seconds as a normal
    // power-saving measure.  Only a sustained run of failures means the strip
    // is truly gone; in that case restart the full scan to report it.
    if (++m_failures > 6) {
        connectToStrip();
        return;
    }
    if (m_state == "ready")
        setState("reconnecting");
    m_reconnectTimer.start();
}
