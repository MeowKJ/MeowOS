import QtQuick 2.15

Flickable {
    id: settingsFlickRoot
    clip: true
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.DragAndOvershootBounds
    boundsMovement: Flickable.FollowBoundsBehavior
    maximumFlickVelocity: 4000
    flickDeceleration: 1500
    pressDelay: 0
    pixelAligned: true
}
