#include "hal_interfaces.h"

#include <algorithm>

namespace meow {

int normalizeRotationDegrees(int degrees)
{
    int normalized = degrees % 360;
    if (normalized < 0) normalized += 360;
    // The display contract intentionally only permits quarter turns.
    if (normalized % 90 != 0) return 0;
    return normalized;
}

DisplayGeometry makeLogicalGeometry(std::uint32_t nativeWidth,
                                    std::uint32_t nativeHeight,
                                    int rotationDegrees)
{
    const int rotation = normalizeRotationDegrees(rotationDegrees);
    const bool swapsAxes = rotation == 90 || rotation == 270;
    DisplayGeometry geometry;
    geometry.nativeWidth = nativeWidth;
    geometry.nativeHeight = nativeHeight;
    geometry.logicalWidth = swapsAxes ? nativeHeight : nativeWidth;
    geometry.logicalHeight = swapsAxes ? nativeWidth : nativeHeight;
    geometry.rotationDegrees = rotation;
    return geometry;
}

TouchPoint transformTouchPoint(TouchPoint point, std::uint32_t width,
                               std::uint32_t height, int rotationDegrees)
{
    const double maxX = width > 0 ? static_cast<double>(width - 1) : 0.0;
    const double maxY = height > 0 ? static_cast<double>(height - 1) : 0.0;
    point.x = std::max(0.0, std::min(point.x, maxX));
    point.y = std::max(0.0, std::min(point.y, maxY));
    switch (normalizeRotationDegrees(rotationDegrees)) {
    case 90:  return TouchPoint{maxY - point.y, point.x};
    case 180: return TouchPoint{maxX - point.x, maxY - point.y};
    case 270: return TouchPoint{point.y, maxX - point.x};
    default:  return point;
    }
}

} // namespace meow
