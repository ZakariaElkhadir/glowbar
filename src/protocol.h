#pragma once

#include <QByteArray>
#include <QColor>

// The packets LEDBLE-01 strip controllers understand on characteristic
// 0xFFE1, as worked out by github.com/8none1/ledble-ledlamp and confirmed on a
// BJ-AP104 strip.
namespace Protocol {

QByteArray power(bool on);

// The controller has no working brightness command, so brightness is applied
// by scaling the color before it is sent.
QColor scaled(const QColor &color, int brightness);
QByteArray color(const QColor &color, int brightness);

}
