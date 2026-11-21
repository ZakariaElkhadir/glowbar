#pragma once

#include <QBluetoothDeviceInfo>
#include <QBluetoothUuid>
#include <QByteArray>
#include <QColor>
#include <QLowEnergyService>
#include <QList>

/**
 * @brief Abstract interface for a BLE LED strip protocol.
 *
 * Each subclass encodes the commands for one family of BLE LED strip
 * controllers.  To add support for a new controller:
 *
 * 1. Create a subclass that implements every pure-virtual method.
 * 2. Add an instance to StripProtocol::all() in stripprotocol.cpp.
 *
 * The backend discovers BLE devices, asks each registered protocol whether
 * it matches, and uses the first match to drive the strip.
 */
class StripProtocol {
public:
    virtual ~StripProtocol() = default;

    /** @brief Human-readable protocol name (e.g. @c "LEDBLE-01"). */
    virtual QString name() const = 0;

    /** @brief Returns @c true if @p device is a controller this protocol can drive. */
    virtual bool matchesDevice(const QBluetoothDeviceInfo &device) const = 0;

    /** @brief The GATT service UUID this controller exposes. */
    virtual QBluetoothUuid serviceUuid() const = 0;

    /** @brief The GATT characteristic UUID to write commands to. */
    virtual QBluetoothUuid characteristicUuid() const = 0;

    /** @brief Returns the packet that turns the strip on. */
    virtual QByteArray powerOnPacket() const = 0;

    /** @brief Returns the packet that turns the strip off. */
    virtual QByteArray powerOffPacket() const = 0;

    /**
     * @brief Returns the packet that sets the strip to @p color at @p brightness percent.
     *
     * Implementations that lack a hardware brightness command should scale the
     * color channels using scaled() before encoding.
     */
    virtual QByteArray colorPacket(const QColor &color, int brightness) const = 0;

    /**
     * @brief The BLE write mode to use for this controller.
     *
     * Most cheap controllers use WriteWithoutResponse for speed.
     * Override if your controller requires acknowledged writes.
     */
    virtual QLowEnergyService::WriteMode writeMode() const {
        return QLowEnergyService::WriteWithoutResponse;
    }

    /**
     * @brief Returns @p color with each RGB channel scaled to @p brightness percent.
     *
     * Shared utility for protocols whose controllers lack a hardware
     * brightness command.  Also used by the UI to preview the effective color.
     */
    static QColor scaled(const QColor &color, int brightness);

    /**
     * @brief Returns all registered protocol instances.
     *
     * To register a new protocol, add it to the implementation of this method
     * in stripprotocol.cpp.
     */
    static const QList<StripProtocol *> &all();
};
