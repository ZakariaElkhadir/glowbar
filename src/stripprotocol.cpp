#include "stripprotocol.h"
#include "ledbleprotocol.h"

#include <QtGlobal>

QColor StripProtocol::scaled(const QColor &color, int brightness) {
    const int b = qBound(0, brightness, 100);
    auto scale = [b](int channel) { return (channel * b + 50) / 100; };
    return QColor(scale(color.red()), scale(color.green()), scale(color.blue()));
}

const QList<StripProtocol *> &StripProtocol::all() {
    // Add new protocols here.  The backend tries each in order and uses the
    // first one whose matchesDevice() returns true.
    static const QList<StripProtocol *> protocols = {
        new LedbleProtocol,
    };
    return protocols;
}
