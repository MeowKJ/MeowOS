#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include <QTimer>
#include "systembackend.h"
#include "version.h"

int main(int argc, char *argv[])
{
    // Prefer GPU scene graph on EGLFS/Panfrost; avoid accidental software fallback.
    qunsetenv("QT_QUICK_BACKEND");
    if (qEnvironmentVariableIsEmpty("QSG_RENDER_LOOP"))
        qputenv("QSG_RENDER_LOOP", "threaded");
    qputenv("QT_QUICK_FLICKABLE_WHEEL_DECELERATION", "5000");

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
        int delay = 1800;
        const int delayIndex = arguments.indexOf(QStringLiteral("--snapshot-delay"));
        if (delayIndex >= 0 && delayIndex + 1 < arguments.size())
            delay = qMax(300, arguments.at(delayIndex + 1).toInt());
        QTimer::singleShot(delay, &engine, [&engine, snapshotFile]() {
            QQuickWindow *quickWindow = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0));
            if (quickWindow) {
                const QImage image = quickWindow->grabWindow();
                image.save(snapshotFile);
            }
            QCoreApplication::quit();
        });
    }
    return app.exec();
}
