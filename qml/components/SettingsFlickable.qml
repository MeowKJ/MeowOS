import QtQuick 2.15

Flickable {
    id: settingsFlickRoot
    clip: true
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.DragAndOvershootBounds
    boundsMovement: Flickable.FollowBoundsBehavior
    maximumFlickVelocity: 4000
    flickDeceleration: 1500
    // Distinguish a deliberate tap from a scroll before a child control takes
    // the event. Zero delay makes small finger jitter cancel many clicks.
    pressDelay: 90
    pixelAligned: true
}
