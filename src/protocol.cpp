#include "protocol.h"

#include <QtGlobal>

namespace Protocol {

QByteArray power(bool on) {
    return QByteArray::fromHex(on ? "7eff0401ffffffffef" : "7eff0400ffffffffef");
}

QColor scaled(const QColor &color, int brightness) {
    const int b = qBound(0, brightness, 100);
    auto scale = [b](int channel) { return (channel * b + 50) / 100; };
    return QColor(scale(color.red()), scale(color.green()), scale(color.blue()));
}

QByteArray color(const QColor &color, int brightness) {
    const QColor c = scaled(color, brightness);
    QByteArray packet = QByteArray::fromHex("7eff0503");
    packet.append(char(c.red()));
    packet.append(char(c.green()));
    packet.append(char(c.blue()));
    packet.append(char(0xff));
    packet.append(char(0xef));
    return packet;
}

}
