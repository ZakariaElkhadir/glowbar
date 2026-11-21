#pragma once

#include "stripprotocol.h"

/**
 * @brief Protocol for LEDBLE-01 BLE LED strip controllers.
 *
 * These are generic Chinese controllers sold under many names (BJ-AP104
 * "LED Mood Lights", MohuanLED / HappyLighting app strips, etc.).  They
 * advertise as @c "LEDBLE-xx-xxxxxxxx" and accept 9-byte commands on
 * characteristic @c 0xFFE1 (service @c 0xFFE0).
 *
 * Protocol reverse-engineered by
 * [8none1/ledble-ledlamp](https://github.com/8none1/ledble-ledlamp).
 */
class LedbleProtocol : public StripProtocol {
public:
    QString name() const override;
    bool matchesDevice(const QBluetoothDeviceInfo &device) const override;
    QBluetoothUuid serviceUuid() const override;
    QBluetoothUuid characteristicUuid() const override;
    QByteArray powerOnPacket() const override;
    QByteArray powerOffPacket() const override;
    QByteArray colorPacket(const QColor &color, int brightness) const override;
};
