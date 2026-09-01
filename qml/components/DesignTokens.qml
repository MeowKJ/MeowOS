pragma Singleton
import QtQuick 2.15

QtObject {
    readonly property color surface: "#F8F7FF"
    readonly property color surfaceStrong: "#FFFFFF"
    readonly property color border: "#E0DBFC"
    readonly property color textPrimary: "#1E1B4B"
    readonly property color textSecondary: "#6B7280"
    readonly property color accent: "#6366F1"
    readonly property color accentStrong: "#4F46E5"
    readonly property color success: "#10B981"
    readonly property color warning: "#F59E0B"
    readonly property color danger: "#EF4444"
    readonly property color info: "#0EA5E9"

    function healthColor(level) {
        if (level === "error") return danger
        if (level === "warning") return warning
        if (level === "ok") return success
        return info
    }
}
