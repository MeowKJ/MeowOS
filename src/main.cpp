#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickItem>
#include <QQuickItemGrabResult>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include <QTimer>
#include "systembackend.h"
#include "version.h"

int main(int argc, char *argv[])
{
    // Prefer the GPU scene graph on EGLFS/Panfrost, while preserving an
    // explicitly requested software backend for offscreen QA and linuxfb.
    QString platformHint = qEnvironmentVariable("QT_QPA_PLATFORM");
    if (platformHint.isEmpty()) platformHint = qEnvironmentVariable("MEOW_QPA_PLATFORM");
    if (platformHint.startsWith(QLatin1String("eglfs"))) qunsetenv("QT_QUICK_BACKEND");
    if (qEnvironmentVariableIsEmpty("QSG_RENDER_LOOP"))
        qputenv("QSG_RENDER_LOOP", "threaded");
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    const QString qpa = qEnvironmentVariable("QT_QPA_PLATFORM");
    const QString meowQpa = qEnvironmentVariable("MEOW_QPA_PLATFORM");
    if (qpa.startsWith(QLatin1String("eglfs")) || meowQpa.startsWith(QLatin1String("eglfs")))
        QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);
    QSurfaceFormat format = QSurfaceFormat::defaultFormat();
    format.setSwapBehavior(QSurfaceFormat::DoubleBuffer);
    format.setSwapInterval(1);
    if (format.samples() < 0)
        format.setSamples(0);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Meow OS"));
    app.setApplicationVersion(QStringLiteral(MEOW_OS_VERSION));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    SystemBackend backend;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("systemBackend"), &backend);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    if (engine.rootObjects().isEmpty()) {
        return 1;
    }

    QString snapshotFile;
    const QStringList arguments = app.arguments();
    const int snapshotIndex = arguments.indexOf(QStringLiteral("--snapshot"));
    if (snapshotIndex >= 0 && snapshotIndex + 1 < arguments.size())
        snapshotFile = arguments.at(snapshotIndex + 1);
    if (!snapshotFile.isEmpty()) {
        QQuickWindow *snapshotWindow = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0));
        if (snapshotWindow && platformHint.startsWith(QLatin1String("offscreen"))) {
            snapshotWindow->setVisibility(QWindow::Windowed);
            snapshotWindow->resize(800, 1280);
        }
        int delay = 1800;
        const int delayIndex = arguments.indexOf(QStringLiteral("--snapshot-delay"));
        if (delayIndex >= 0 && delayIndex + 1 < arguments.size())
            delay = qMax(300, arguments.at(delayIndex + 1).toInt());
        QTimer::singleShot(delay, &engine, [&engine, snapshotFile]() {
            QQuickWindow *quickWindow = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0));
            if (quickWindow) {
                const QSharedPointer<QQuickItemGrabResult> result = quickWindow->contentItem()->grabToImage();
                QObject::connect(result.data(), &QQuickItemGrabResult::ready, quickWindow,
                                 [result, snapshotFile]() {
                    result->image().save(snapshotFile);
                    QCoreApplication::quit();
                });
                return;
            }
            QCoreApplication::quit();
        });
        QTimer::singleShot(delay + 5000, &app, &QCoreApplication::quit);
    }
    return app.exec();
}
