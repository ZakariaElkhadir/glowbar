# Place ledstrip.icns here.
#
# To generate it from an SVG:
#   brew install librsvg
#   mkdir ledstrip.iconset
#   for size in 16 32 64 128 256 512; do
#     rsvg-convert -w $size -h $size ../pkgbuild/ledstrip.svg \
#       -o ledstrip.iconset/icon_${size}x${size}.png
#     rsvg-convert -w $((size*2)) -h $((size*2)) ../pkgbuild/ledstrip.svg \
#       -o ledstrip.iconset/icon_${size}x${size}@2x.png
#   done
#   iconutil -c icns ledstrip.iconset
