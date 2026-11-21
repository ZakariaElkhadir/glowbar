# Place glowbar.icns here.
#
# To generate it from an SVG:
#   brew install librsvg
#   mkdir glowbar.iconset
#   for size in 16 32 64 128 256 512; do
#     rsvg-convert -w $size -h $size ../pkgbuild/glowbar.svg \
#       -o glowbar.iconset/icon_${size}x${size}.png
#     rsvg-convert -w $((size*2)) -h $((size*2)) ../pkgbuild/glowbar.svg \
#       -o glowbar.iconset/icon_${size}x${size}@2x.png
#   done
#   iconutil -c icns glowbar.iconset
