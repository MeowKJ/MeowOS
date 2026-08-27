#pragma once

#include <cstdint>
#include <string>

namespace meow {

struct DisplayGeometry {
    std::uint32_t nativeWidth = 0;
    std::uint32_t nativeHeight = 0;
    std::uint32_t logicalWidth = 0;
    std::uint32_t logicalHeight = 0;
    int rotationDegrees = 0;
};

struct TouchPoint {
    double x = 0.0;
    double y = 0.0;
    TouchPoint() = default;
    TouchPoint(double xValue, double yValue) : x(xValue), y(yValue) {}
};

// Keep coordinate transforms in the HAL contract so every frontend (EGLFS,
// X11, Wayland and future RK adapters) presents the same logical orientation.
int normalizeRotationDegrees(int degrees);
DisplayGeometry makeLogicalGeometry(std::uint32_t nativeWidth,
                                    std::uint32_t nativeHeight,
                                    int rotationDegrees);
TouchPoint transformTouchPoint(TouchPoint point, std::uint32_t width,
                               std::uint32_t height, int rotationDegrees);

class IDisplayHal {
public:
    virtual ~IDisplayHal() = default;
    virtual DisplayGeometry geometry() const = 0;
    virtual bool setBrightnessPercent(int percent) = 0;
};

class IInputHal {
public:
    virtual ~IInputHal() = default;
    // The input adapter must consume the same geometry as the display adapter;
    // this prevents a rotated framebuffer with an unrotated touch matrix.
    virtual bool setDisplayGeometry(const DisplayGeometry &geometry) = 0;
    virtual bool start() = 0;
    virtual void stop() = 0;
    virtual std::string deviceName() const = 0;
};

class IPowerHal {
public:
    virtual ~IPowerHal() = default;
    virtual int batteryPercent() const = 0;
    virtual bool externalPowerPresent() const = 0;
};

// Process/session adapter. Implementations may use systemd, a lightweight
// supervisor, or an embedded launcher; policy code must not depend on either.
class IAppProcessHal {
public:
    virtual ~IAppProcessHal() = default;
    virtual bool start(const std::string &appId) = 0;
    virtual bool stop(const std::string &appId) = 0;
    virtual bool isRunning(const std::string &appId) const = 0;
};

} // namespace meow
