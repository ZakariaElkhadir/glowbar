#include "ledbleprotocol.h"

QString LedbleProtocol::name() const {
    return QStringLiteral("LEDBLE-01");
}

bool LedbleProtocol::matchesDevice(const QBluetoothDeviceInfo &device) const {
    return device.name().startsWith(QStringLiteral("LEDBLE"));
}

QBluetoothUuid LedbleProtocol::serviceUuid() const {
    return QBluetoothUuid(quint16(0xFFE0));
}

QBluetoothUuid LedbleProtocol::characteristicUuid() const {
    return QBluetoothUuid(quint16(0xFFE1));
}

QByteArray LedbleProtocol::powerOnPacket() const {
    return QByteArray::fromHex("7eff0401ffffffffef");
}

QByteArray LedbleProtocol::powerOffPacket() const {
    return QByteArray::fromHex("7eff0400ffffffffef");
}

QByteArray LedbleProtocol::colorPacket(const QColor &color, int brightness) const {
    const QColor c = scaled(color, brightness);
    QByteArray packet = QByteArray::fromHex("7eff0503");
    packet.append(char(c.red()));
    packet.append(char(c.green()));
    packet.append(char(c.blue()));
    packet.append(char(0xff));
    packet.append(char(0xef));
    return packet;
}
