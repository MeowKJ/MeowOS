#include "systembackend.h"

#include <QtConcurrent/QtConcurrentRun>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QRegularExpression>
#include <QSet>
#include <QStorageInfo>
#include <QSysInfo>
#include <QtMath>

#ifdef Q_OS_LINUX
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <sys/ioctl.h>
#include <unistd.h>
#endif

#include "version.h"

namespace {

QString readTextFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return QString();
    return QString::fromLocal8Bit(file.readAll()).trimmed();
}

QString runProcess(const QString &program, const QStringList &arguments, int timeoutMs = 5000)
{
    QProcess process;
    process.setProcessChannelMode(QProcess::MergedChannels);
    process.start(program, arguments);
    if (!process.waitForStarted(qMin(timeoutMs, 3000)) || !process.waitForFinished(timeoutMs)) {
        process.kill();
        process.waitForFinished(500);
        return QString();
    }
    return QString::fromLocal8Bit(process.readAll()).trimmed();
}

bool readInteger(const QString &path, qint64 *value)
{
    bool ok = false;
    const qint64 parsed = readTextFile(path).toLongLong(&ok);
    if (ok) *value = parsed;
    return ok;
}

bool readI2cRegister(quint8 address, quint8 reg, quint8 *data, int length)
{
#ifdef Q_OS_LINUX
    const QByteArray device = qEnvironmentVariable("MEOW_BATTERY_I2C", "/dev/i2c-1").toLocal8Bit();
    const int fd = ::open(device.constData(), O_RDWR | O_CLOEXEC);
    if (fd < 0) return false;
    bool success = false;
    for (int attempt = 0; attempt < 3 && !success; ++attempt) {
        i2c_msg messages[2] = {};
        messages[0].addr = address;
        messages[0].len = 1;
        messages[0].buf = &reg;
        messages[1].addr = address;
        messages[1].flags = I2C_M_RD;
        messages[1].len = static_cast<__u16>(length);
        messages[1].buf = data;
        i2c_rdwr_ioctl_data transaction = { messages, 2 };
        success = ::ioctl(fd, I2C_RDWR, &transaction) >= 0;
        if (!success) ::usleep(2000);
    }
    ::close(fd);
    return success;
#else
    Q_UNUSED(address)
    Q_UNUSED(reg)
    Q_UNUSED(data)
    Q_UNUSED(length)
    return false;
#endif
}

bool readI2cWord(quint8 address, quint8 reg, quint16 *value)
{
    quint8 data[2] = {};
    if (!readI2cRegister(address, reg, data, 2)) return false;
    *value = static_cast<quint16>(data[0] | (data[1] << 8));
    return true;
}

double normalizeTemperature(qint64 raw)
{
    const qint64 magnitude = qAbs(raw);
    if (magnitude >= 10000) return raw / 1000.0;
    if (magnitude >= 100) return raw / 10.0;
    return static_cast<double>(raw);
}

QString formatBytes(qint64 bytes)
{
    static const char *units[] = {"B", "KB", "MB", "GB", "TB"};
    double value = qMax<qint64>(0, bytes);
    int unit = 0;
    while (value >= 1024.0 && unit < 4) {
        value /= 1024.0;
        ++unit;
    }
    return QStringLiteral("%1 %2").arg(value, 0, 'f', unit == 0 ? 0 : 1)
            .arg(QString::fromLatin1(units[unit]));
}

QStringList splitNmcliTerseLine(const QString &line)
{
    QStringList fields;
    QString current;
    bool escaped = false;
    for (const QChar ch : line) {
        if (escaped) {
            current.append(ch);
            escaped = false;
        } else if (ch == QLatin1Char('\\')) {
            escaped = true;
        } else if (ch == QLatin1Char(':')) {
            fields.append(current);
            current.clear();
        } else {
            current.append(ch);
        }
    }
    if (escaped) current.append(QLatin1Char('\\'));
    fields.append(current);
    return fields;
}

QVariantMap collectStatus()
{
    QVariantMap result;
    const QString wifi = runProcess(QStringLiteral("nmcli"),
                                    {QStringLiteral("-t"), QStringLiteral("-e"), QStringLiteral("yes"),
                                     QStringLiteral("-f"),
                                     QStringLiteral("ACTIVE,SSID"), QStringLiteral("device"),
                                     QStringLiteral("wifi")}, 2500);
    QString currentWifi;
    for (const QString &line : wifi.split(QRegularExpression(QStringLiteral("\\r?\\n")), Qt::SkipEmptyParts)) {
        const QStringList fields = splitNmcliTerseLine(line);
        if (fields.size() >= 2 && fields.at(0) == QStringLiteral("yes")) {
            currentWifi = fields.at(1);
            break;
        }
    }
    result.insert(QStringLiteral("wifiName"), currentWifi);

    bool batteryAvailable = false;
    int batteryPercent = -1;
    int voltageMv = -1;
    int currentMa = 0;
    double temperatureC = -273.15;
    QString batteryStatus;
    QString batteryHealth;
    QString chargeTemperatureZone;
    bool chargerAvailable = false;
    bool externalPowerPresent = false;

    const QDir supplies(QStringLiteral("/sys/class/power_supply"));
    const QStringList entries = supplies.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const QString &entry : entries) {
        const QString base = supplies.absoluteFilePath(entry);
        const QString type = readTextFile(base + QStringLiteral("/type"));
        if (type.compare(QStringLiteral("Battery"), Qt::CaseInsensitive) == 0 && !batteryAvailable) {
            batteryAvailable = true;
            qint64 raw = 0;
            if (readInteger(base + QStringLiteral("/capacity"), &raw)) batteryPercent = qBound(0, static_cast<int>(raw), 100);
            if (readInteger(base + QStringLiteral("/voltage_now"), &raw)) voltageMv = static_cast<int>(raw / 1000);
            if (readInteger(base + QStringLiteral("/current_now"), &raw)) currentMa = static_cast<int>(raw / 1000);
            if (readInteger(base + QStringLiteral("/temp"), &raw)
                    || readInteger(base + QStringLiteral("/temp_now"), &raw)
                    || readInteger(base + QStringLiteral("/temperature"), &raw)) {
                temperatureC = normalizeTemperature(raw);
            }
            batteryStatus = readTextFile(base + QStringLiteral("/status"));
            batteryHealth = readTextFile(base + QStringLiteral("/health"));
        }

        // The charger NTC is a safety input. Report its own exported zone only;
        // never derive it from the fuel-gauge temperature.
        const QString lowerName = entry.toLower();
        if (lowerName.contains(QStringLiteral("charger")) || lowerName.contains(QStringLiteral("sgm415"))) {
            const QString health = readTextFile(base + QStringLiteral("/health"));
            if (health.compare(QStringLiteral("Cold"), Qt::CaseInsensitive) == 0) chargeTemperatureZone = QStringLiteral("cold");
            else if (health.compare(QStringLiteral("Cool"), Qt::CaseInsensitive) == 0) chargeTemperatureZone = QStringLiteral("cool");
            else if (health.compare(QStringLiteral("Warm"), Qt::CaseInsensitive) == 0) chargeTemperatureZone = QStringLiteral("warm");
            else if (health.compare(QStringLiteral("Hot"), Qt::CaseInsensitive) == 0
                     || health.compare(QStringLiteral("Overheat"), Qt::CaseInsensitive) == 0) chargeTemperatureZone = QStringLiteral("hot");
            else if (health.compare(QStringLiteral("Good"), Qt::CaseInsensitive) == 0) chargeTemperatureZone = QStringLiteral("normal");
        }
    }

    // Direct hardware fallback for the fixed A5E carrier-board wiring. This
    // remains useful on kernels that do not provide power_supply drivers.
    quint8 chargerStatus = 0;
    quint8 chargerFault = 0;
    chargerAvailable = readI2cRegister(0x6b, 0x08, &chargerStatus, 1);
    if (chargerAvailable) {
        externalPowerPresent = chargerStatus & 0x04;
        const int chargeState = (chargerStatus >> 3) & 0x03;
        if (chargeState == 1 || chargeState == 2) batteryStatus = QStringLiteral("Charging");
        else if (chargeState == 3) batteryStatus = QStringLiteral("Full");
        else batteryStatus = QStringLiteral("Not charging");
        readI2cRegister(0x6b, 0x09, &chargerFault, 1);
        switch (chargerFault & 0x07) {
        case 0x02: chargeTemperatureZone = QStringLiteral("warm"); break;
        case 0x03: chargeTemperatureZone = QStringLiteral("cool"); break;
        case 0x05: chargeTemperatureZone = QStringLiteral("cold"); break;
        case 0x06: chargeTemperatureZone = QStringLiteral("hot"); break;
        case 0x00: chargeTemperatureZone = QStringLiteral("normal"); break;
        default: chargeTemperatureZone.clear(); break;
        }
    }

    quint16 gaugeTemperature = 0;
    quint16 gaugeVoltage = 0;
    quint16 gaugeCurrent = 0;
    quint16 gaugeSoc = 0;
    if (readI2cWord(0x55, 0x06, &gaugeTemperature)) {
        batteryAvailable = true;
        temperatureC = gaugeTemperature / 10.0 - 273.15;
        if (readI2cWord(0x55, 0x08, &gaugeVoltage)) voltageMv = gaugeVoltage;
        if (readI2cWord(0x55, 0x14, &gaugeCurrent)) currentMa = static_cast<qint16>(gaugeCurrent);
        if (readI2cWord(0x55, 0x2c, &gaugeSoc)) batteryPercent = qBound(0, static_cast<int>(gaugeSoc), 100);
        batteryHealth = QStringLiteral("Good");
    }
    const bool batteryCharging = batteryStatus.compare(QStringLiteral("Charging"), Qt::CaseInsensitive) == 0;
    result.insert(QStringLiteral("batteryAvailable"), batteryAvailable);
    result.insert(QStringLiteral("batteryPercent"), batteryPercent);
    result.insert(QStringLiteral("batteryStatus"), batteryStatus);
    result.insert(QStringLiteral("batteryHealth"), batteryHealth);
    result.insert(QStringLiteral("batteryCharging"), batteryCharging);
    result.insert(QStringLiteral("chargerAvailable"), chargerAvailable);
    result.insert(QStringLiteral("externalPowerPresent"), externalPowerPresent);
    result.insert(QStringLiteral("batteryTemperatureC"), temperatureC);
    result.insert(QStringLiteral("chargeTemperatureZone"), chargeTemperatureZone);
    result.insert(QStringLiteral("batteryVoltageMv"), voltageMv);
    result.insert(QStringLiteral("batteryCurrentMa"), currentMa);

    const QString cards = readTextFile(QStringLiteral("/proc/asound/cards"));
    const bool audioAvailable = cards.contains(QStringLiteral("Meow Speaker"), Qt::CaseInsensitive)
            || cards.contains(QStringLiteral("meow-speaker"), Qt::CaseInsensitive)
            || cards.contains(QStringLiteral("simple-card"), Qt::CaseInsensitive);
    int volumePercent = -1;
    const QRegularExpression percentExpression(QStringLiteral("\\[(\\d{1,3})%\\]"));
    for (const QString &control : {QStringLiteral("Speaker"), QStringLiteral("Meow")}) {
        const QString output = runProcess(QStringLiteral("amixer"),
                                          {QStringLiteral("-c"), QStringLiteral("Speaker"),
                                           QStringLiteral("sget"), control}, 1200);
        QRegularExpressionMatchIterator matches = percentExpression.globalMatch(output);
        while (matches.hasNext()) {
            bool ok = false;
            const int value = matches.next().captured(1).toInt(&ok);
            if (ok) volumePercent = qBound(0, value, 100);
        }
        if (volumePercent >= 0) break;
    }
    result.insert(QStringLiteral("audioAvailable"), audioAvailable);
    result.insert(QStringLiteral("volumePercent"), volumePercent);

    QString backlightPath;
    int brightnessMax = 0;
    int brightnessPercent = -1;
    const QDir backlights(QStringLiteral("/sys/class/backlight"));
    for (const QString &entry : backlights.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
        const QString base = backlights.absoluteFilePath(entry);
        qint64 current = 0;
        qint64 maximum = 0;
        if (readInteger(base + QStringLiteral("/actual_brightness"), &current)
                && readInteger(base + QStringLiteral("/max_brightness"), &maximum)
                && maximum > 0) {
            backlightPath = base + QStringLiteral("/brightness");
            brightnessMax = static_cast<int>(maximum);
            brightnessPercent = qBound(0, qRound(100.0 * current / maximum), 100);
            break;
        }
    }
    result.insert(QStringLiteral("backlightPath"), backlightPath);
    result.insert(QStringLiteral("brightnessMax"), brightnessMax);
    result.insert(QStringLiteral("displayBrightnessPercent"), brightnessPercent);
    result.insert(QStringLiteral("brightnessAvailable"), !backlightPath.isEmpty());
    return result;
}

QVariantList collectWifiNetworks()
{
    QSet<QString> savedNetworks;
    const QString savedOutput = runProcess(QStringLiteral("nmcli"),
                                           {QStringLiteral("-t"), QStringLiteral("-e"), QStringLiteral("yes"),
                                            QStringLiteral("-f"), QStringLiteral("NAME,TYPE"),
                                            QStringLiteral("connection"), QStringLiteral("show")}, 2500);
    for (const QString &line : savedOutput.split(QRegularExpression(QStringLiteral("\\r?\\n")), Qt::SkipEmptyParts)) {
        const QStringList fields = splitNmcliTerseLine(line);
        if (fields.size() >= 2 && fields.at(1) == QStringLiteral("802-11-wireless")) {
            savedNetworks.insert(fields.at(0));
        }
    }

    const QString output = runProcess(QStringLiteral("nmcli"),
                                      {QStringLiteral("-t"), QStringLiteral("-e"), QStringLiteral("yes"),
                                       QStringLiteral("-f"),
                                       QStringLiteral("IN-USE,SSID,SIGNAL,CHAN,FREQ,RATE,SECURITY,BARS"),
                                       QStringLiteral("device"), QStringLiteral("wifi"), QStringLiteral("list"),
                                       QStringLiteral("--rescan"), QStringLiteral("yes")}, 12000);
    QVariantList networks;
    QSet<QString> seen;
    for (const QString &line : output.split(QRegularExpression(QStringLiteral("\\r?\\n")), Qt::SkipEmptyParts)) {
        const QStringList fields = splitNmcliTerseLine(line);
        if (fields.size() < 8 || fields.at(1).isEmpty() || seen.contains(fields.at(1))) continue;
        seen.insert(fields.at(1));
        bool frequencyOk = false;
        const int frequency = fields.at(4).section(QLatin1Char(' '), 0, 0).toInt(&frequencyOk);
        QString band;
        if (frequencyOk && frequency >= 5925) band = QStringLiteral("6 GHz");
        else if (frequencyOk && frequency >= 4900) band = QStringLiteral("5 GHz");
        else if (frequencyOk && frequency > 0) band = QStringLiteral("2.4 GHz");
        QVariantMap item;
        item.insert(QStringLiteral("active"), fields.at(0) == QStringLiteral("*") || fields.at(0) == QStringLiteral("yes"));
        item.insert(QStringLiteral("ssid"), fields.at(1));
        item.insert(QStringLiteral("signal"), fields.at(2).toInt());
        item.insert(QStringLiteral("channel"), fields.at(3).toInt());
        item.insert(QStringLiteral("frequency"), frequencyOk ? frequency : 0);
        item.insert(QStringLiteral("band"), band);
        item.insert(QStringLiteral("rate"), fields.at(5));
        item.insert(QStringLiteral("security"), fields.at(6).isEmpty() || fields.at(6) == QStringLiteral("--")
                    ? QStringLiteral("开放") : QString(fields.at(6)).replace(QLatin1Char(' '), QLatin1Char('/')));
        item.insert(QStringLiteral("bars"), fields.at(7));
        item.insert(QStringLiteral("saved"), savedNetworks.contains(fields.at(1)));
        networks.append(item);
    }
    return networks;
}

QVariantMap runWifiOperation(const QString &operation, const QString &ssid, const QString &password)
{
    QVariantMap result;
    QString output;
    if (operation == QStringLiteral("connect")) {
        QStringList arguments{QStringLiteral("device"), QStringLiteral("wifi"), QStringLiteral("connect"), ssid};
        if (!password.isEmpty()) arguments << QStringLiteral("password") << password;
        output = runProcess(QStringLiteral("nmcli"), arguments, 20000);
    } else {
        output = runProcess(QStringLiteral("nmcli"), {QStringLiteral("connection"), QStringLiteral("delete"),
                                                       QStringLiteral("id"), ssid}, 8000);
    }
    const bool ok = !output.isEmpty() && !output.contains(QStringLiteral("Error"), Qt::CaseInsensitive)
            && !output.contains(QStringLiteral("错误"), Qt::CaseInsensitive);
    result.insert(QStringLiteral("ok"), ok);
    result.insert(QStringLiteral("operation"), operation);
    return result;
}

} // namespace

SystemBackend::SystemBackend(QObject *parent)
    : QObject(parent), m_statusWatcher(this), m_wifiScanWatcher(this), m_wifiOperationWatcher(this)
{
    m_volumeSetTimer.setSingleShot(true);
    m_volumeSetTimer.setInterval(80);
    m_brightnessSetTimer.setSingleShot(true);
    m_brightnessSetTimer.setInterval(60);
    m_volumeSetProcess.setProcessChannelMode(QProcess::MergedChannels);
    m_feedbackProcess.setProcessChannelMode(QProcess::MergedChannels);
    connect(&m_volumeSetTimer, &QTimer::timeout, this, [this]() {
        if (m_volumeSetProcess.state() != QProcess::NotRunning) {
            m_volumeSetTimer.start();
            return;
        }
        m_volumeSetProcess.start(QStringLiteral("amixer"),
                                 {QStringLiteral("-c"), QStringLiteral("Speaker"),
                                  QStringLiteral("sset"), QStringLiteral("Speaker"),
                                  QString::number(m_pendingVolumePercent) + QLatin1Char('%')});
    });
    connect(&m_volumeSetProcess,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int, QProcess::ExitStatus) { refreshStatus(); });
    connect(&m_brightnessSetTimer, &QTimer::timeout, this, [this]() {
        if (m_backlightPath.isEmpty() || m_brightnessMax <= 0) return;
        const int level = qBound(1, qRound(m_brightnessMax * m_pendingBrightnessPercent / 100.0),
                                 m_brightnessMax);
        QFile brightness(m_backlightPath);
        if (!brightness.open(QIODevice::WriteOnly | QIODevice::Text)) return;
        brightness.write(QByteArray::number(level));
        brightness.close();
        refreshStatus();
    });
    connect(&m_statusWatcher, &QFutureWatcher<QVariantMap>::finished, this, [this]() {
        applyStatusSnapshot(m_statusWatcher.result());
        if (m_statusRefreshPending) {
            m_statusRefreshPending = false;
            refreshStatus();
        }
    });
    connect(&m_wifiScanWatcher, &QFutureWatcher<QVariantList>::finished, this, [this]() {
        m_wifiNetworks = m_wifiScanWatcher.result();
        emit wifiChanged();
        refreshStatus();
    });
    connect(&m_wifiOperationWatcher, &QFutureWatcher<QVariantMap>::finished, this, [this]() {
        const QVariantMap result = m_wifiOperationWatcher.result();
        const bool ok = result.value(QStringLiteral("ok")).toBool();
        const bool connecting = result.value(QStringLiteral("operation")).toString() == QStringLiteral("connect");
        emit operationMessage(connecting ? (ok ? QStringLiteral("Wi-Fi 已连接") : QStringLiteral("Wi-Fi 连接失败"))
                                         : (ok ? QStringLiteral("已忘记网络") : QStringLiteral("删除网络失败")), ok);
        refreshStatus();
        scanWifi();
    });
    refresh();
}

QString SystemBackend::version() const { return QStringLiteral(MEOW_OS_VERSION); }
QString SystemBackend::hostname() const { return m_hostname; }
QString SystemBackend::kernel() const { return m_kernel; }
QString SystemBackend::diskUsed() const { return m_diskUsed; }
QString SystemBackend::diskTotal() const { return m_diskTotal; }
int SystemBackend::diskPercent() const { return m_diskPercent; }
bool SystemBackend::nvmeAvailable() const { return m_nvmeAvailable; }
bool SystemBackend::nvmeMounted() const { return m_nvmeMounted; }
QString SystemBackend::nvmeModel() const { return m_nvmeModel; }
QString SystemBackend::nvmeMountPoint() const { return m_nvmeMountPoint; }
QString SystemBackend::nvmeUsed() const { return m_nvmeUsed; }
QString SystemBackend::nvmeTotal() const { return m_nvmeTotal; }
int SystemBackend::nvmePercent() const { return m_nvmePercent; }
QString SystemBackend::wifiName() const { return m_wifiName; }
bool SystemBackend::wifiConnected() const { return !m_wifiName.isEmpty(); }
bool SystemBackend::wifiScanning() const { return m_wifiScanWatcher.isRunning(); }
QVariantList SystemBackend::wifiNetworks() const { return m_wifiNetworks; }
bool SystemBackend::batteryAvailable() const { return m_batteryAvailable; }
int SystemBackend::batteryPercent() const { return m_batteryPercent; }
QString SystemBackend::batteryStatus() const { return m_batteryStatus; }
bool SystemBackend::batteryCharging() const { return m_batteryCharging; }
bool SystemBackend::chargerAvailable() const { return m_chargerAvailable; }
bool SystemBackend::externalPowerPresent() const { return m_externalPowerPresent; }
double SystemBackend::batteryTemperatureC() const { return m_batteryTemperatureC; }
QString SystemBackend::chargeTemperatureZone() const { return m_chargeTemperatureZone; }
int SystemBackend::batteryVoltageMv() const { return m_batteryVoltageMv; }
int SystemBackend::batteryCurrentMa() const { return m_batteryCurrentMa; }
QString SystemBackend::batteryHealth() const { return m_batteryHealth; }
double SystemBackend::batteryPowerW() const
{
    if (!m_batteryAvailable || m_batteryVoltageMv < 0) return -1.0;
    return qAbs(static_cast<double>(m_batteryVoltageMv) * m_batteryCurrentMa) / 1000000.0;
}
int SystemBackend::volumePercent() const { return m_volumePercent; }
bool SystemBackend::audioAvailable() const { return m_audioAvailable; }
int SystemBackend::displayBrightnessPercent() const { return m_displayBrightnessPercent; }
bool SystemBackend::brightnessAvailable() const { return m_brightnessAvailable; }

int SystemBackend::displayRotation() const
{
    bool ok = false;
    const int value = qEnvironmentVariableIntValue("MEOW_UI_ROTATION", &ok);
    return ok ? value : -90;
}

void SystemBackend::refresh()
{
    refreshSystem();
    refreshStorage();
    refreshStatus();
}

void SystemBackend::refreshStatus()
{
    if (m_statusWatcher.isRunning()) {
        m_statusRefreshPending = true;
        return;
    }
    m_statusWatcher.setFuture(QtConcurrent::run(collectStatus));
}

void SystemBackend::refreshSystem()
{
    const QString hostname = readTextFile(QStringLiteral("/etc/hostname"));
    const QString kernel = QSysInfo::kernelVersion();
    if (hostname != m_hostname || kernel != m_kernel) {
        m_hostname = hostname;
        m_kernel = kernel;
        emit systemInfoChanged();
    }
}

void SystemBackend::refreshStorage()
{
    QStorageInfo storage(QStringLiteral("/"));
    storage.refresh();
    if (!storage.isValid() || !storage.isReady() || storage.bytesTotal() <= 0) return;
    const qint64 used = storage.bytesTotal() - storage.bytesAvailable();
    const QString diskUsed = formatBytes(used);
    const QString diskTotal = formatBytes(storage.bytesTotal());
    const int diskPercent = qBound(0, static_cast<int>(100.0 * used / storage.bytesTotal()), 100);
    bool nvmeAvailable = false;
    bool nvmeMounted = false;
    QString nvmeModel;
    QString nvmeMountPoint;
    QString nvmeUsed;
    QString nvmeTotal;
    int nvmePercent = 0;

    QDir sysBlock(QStringLiteral("/sys/block"));
    sysBlock.setNameFilters({QStringLiteral("nvme*n*")});
    const QStringList nvmeDevices = sysBlock.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    if (!nvmeDevices.isEmpty()) {
        const QString deviceName = nvmeDevices.first();
        const QString sysPath = sysBlock.absoluteFilePath(deviceName);
        nvmeAvailable = true;
        nvmeModel = readTextFile(sysPath + QStringLiteral("/device/model"));
        qint64 sectors = 0;
        if (readInteger(sysPath + QStringLiteral("/size"), &sectors) && sectors > 0) {
            nvmeTotal = formatBytes(sectors * 512);
        }

        const QString devicePrefix = QStringLiteral("/dev/") + deviceName;
        for (QStorageInfo volume : QStorageInfo::mountedVolumes()) {
            const QString device = QString::fromLocal8Bit(volume.device());
            if (!device.startsWith(devicePrefix)) continue;
            volume.refresh();
            if (!volume.isValid() || !volume.isReady() || volume.bytesTotal() <= 0) continue;
            const qint64 nvmeBytesUsed = volume.bytesTotal() - volume.bytesAvailable();
            nvmeMounted = true;
            nvmeMountPoint = volume.rootPath();
            nvmeUsed = formatBytes(nvmeBytesUsed);
            nvmeTotal = formatBytes(volume.bytesTotal());
            nvmePercent = qBound(0, static_cast<int>(100.0 * nvmeBytesUsed / volume.bytesTotal()), 100);
            break;
        }
    }

    if (diskUsed != m_diskUsed || diskTotal != m_diskTotal || diskPercent != m_diskPercent
            || nvmeAvailable != m_nvmeAvailable || nvmeMounted != m_nvmeMounted
            || nvmeModel != m_nvmeModel || nvmeMountPoint != m_nvmeMountPoint
            || nvmeUsed != m_nvmeUsed || nvmeTotal != m_nvmeTotal || nvmePercent != m_nvmePercent) {
        m_diskUsed = diskUsed;
        m_diskTotal = diskTotal;
        m_diskPercent = diskPercent;
        m_nvmeAvailable = nvmeAvailable;
        m_nvmeMounted = nvmeMounted;
        m_nvmeModel = nvmeModel;
        m_nvmeMountPoint = nvmeMountPoint;
        m_nvmeUsed = nvmeUsed;
        m_nvmeTotal = nvmeTotal;
        m_nvmePercent = nvmePercent;
        emit storageChanged();
    }
}

void SystemBackend::applyStatusSnapshot(const QVariantMap &snapshot)
{
    const QString wifiName = snapshot.value(QStringLiteral("wifiName")).toString();
    if (wifiName != m_wifiName) {
        m_wifiName = wifiName;
        emit wifiChanged();
    }

    const bool batteryAvailable = snapshot.value(QStringLiteral("batteryAvailable")).toBool();
    const int batteryPercent = snapshot.value(QStringLiteral("batteryPercent"), -1).toInt();
    const QString batteryStatus = snapshot.value(QStringLiteral("batteryStatus")).toString();
    const bool batteryCharging = snapshot.value(QStringLiteral("batteryCharging")).toBool();
    const bool chargerAvailable = snapshot.value(QStringLiteral("chargerAvailable")).toBool();
    const bool externalPowerPresent = snapshot.value(QStringLiteral("externalPowerPresent")).toBool();
    const double batteryTemperatureC = snapshot.value(QStringLiteral("batteryTemperatureC"), -273.15).toDouble();
    const QString chargeTemperatureZone = snapshot.value(QStringLiteral("chargeTemperatureZone")).toString();
    const int batteryVoltageMv = snapshot.value(QStringLiteral("batteryVoltageMv"), -1).toInt();
    const int batteryCurrentMa = snapshot.value(QStringLiteral("batteryCurrentMa")).toInt();
    const QString batteryHealth = snapshot.value(QStringLiteral("batteryHealth")).toString();
    if (batteryAvailable != m_batteryAvailable || batteryPercent != m_batteryPercent
            || batteryStatus != m_batteryStatus || batteryCharging != m_batteryCharging
            || chargerAvailable != m_chargerAvailable || externalPowerPresent != m_externalPowerPresent
            || !qFuzzyCompare(batteryTemperatureC + 274.15, m_batteryTemperatureC + 274.15)
            || chargeTemperatureZone != m_chargeTemperatureZone || batteryVoltageMv != m_batteryVoltageMv
            || batteryCurrentMa != m_batteryCurrentMa || batteryHealth != m_batteryHealth) {
        m_batteryAvailable = batteryAvailable;
        m_batteryPercent = batteryPercent;
        m_batteryStatus = batteryStatus;
        m_batteryCharging = batteryCharging;
        m_chargerAvailable = chargerAvailable;
        m_externalPowerPresent = externalPowerPresent;
        m_batteryTemperatureC = batteryTemperatureC;
        m_chargeTemperatureZone = chargeTemperatureZone;
        m_batteryVoltageMv = batteryVoltageMv;
        m_batteryCurrentMa = batteryCurrentMa;
        m_batteryHealth = batteryHealth;
        emit powerChanged();
    }

    const int volumePercent = snapshot.value(QStringLiteral("volumePercent"), -1).toInt();
    const bool audioAvailable = snapshot.value(QStringLiteral("audioAvailable")).toBool();
    if (volumePercent != m_volumePercent || audioAvailable != m_audioAvailable) {
        m_volumePercent = volumePercent;
        m_audioAvailable = audioAvailable;
        emit audioChanged();
    }

    const QString backlightPath = snapshot.value(QStringLiteral("backlightPath")).toString();
    const int brightnessMax = snapshot.value(QStringLiteral("brightnessMax")).toInt();
    const int brightnessPercent = snapshot.value(QStringLiteral("displayBrightnessPercent"), -1).toInt();
    const bool brightnessAvailable = snapshot.value(QStringLiteral("brightnessAvailable")).toBool();
    if (backlightPath != m_backlightPath || brightnessMax != m_brightnessMax
            || brightnessPercent != m_displayBrightnessPercent
            || brightnessAvailable != m_brightnessAvailable) {
        m_backlightPath = backlightPath;
        m_brightnessMax = brightnessMax;
        m_displayBrightnessPercent = brightnessPercent;
        m_brightnessAvailable = brightnessAvailable;
        emit displayChanged();
    }
}

void SystemBackend::scanWifi()
{
    if (m_wifiScanWatcher.isRunning()) return;
    m_wifiScanWatcher.setFuture(QtConcurrent::run(collectWifiNetworks));
    emit wifiChanged();
}

void SystemBackend::connectWifi(const QString &ssid, const QString &password)
{
    if (!m_wifiOperationWatcher.isRunning()) {
        m_wifiOperationWatcher.setFuture(QtConcurrent::run(runWifiOperation, QStringLiteral("connect"), ssid, password));
    }
}

void SystemBackend::forgetWifi(const QString &ssid)
{
    if (!m_wifiOperationWatcher.isRunning()) {
        m_wifiOperationWatcher.setFuture(QtConcurrent::run(runWifiOperation, QStringLiteral("forget"), ssid, QString()));
    }
}

void SystemBackend::setVolume(int percent)
{
    m_pendingVolumePercent = qBound(0, percent, 100);
    if (m_volumePercent != m_pendingVolumePercent) {
        m_volumePercent = m_pendingVolumePercent;
        emit audioChanged();
    }
    m_volumeSetTimer.start();
}

void SystemBackend::playVolumeFeedback()
{
    if (!m_audioAvailable) return;
    // Let the debounced mixer write land first, so the feedback is played at
    // the newly selected volume instead of the previous setting.
    QTimer::singleShot(160, this, [this]() {
        if (m_feedbackProcess.state() != QProcess::NotRunning) return;
        m_feedbackProcess.start(QStringLiteral("aplay"),
                                {QStringLiteral("-q"),
                                 QStringLiteral("-D"), QStringLiteral("meow_volume"),
                                 QStringLiteral("/opt/meow-os/assets/sounds/volume-meow.wav")});
    });
}

void SystemBackend::setDisplayBrightness(int percent)
{
    m_pendingBrightnessPercent = qBound(10, percent, 100);
    if (m_displayBrightnessPercent != m_pendingBrightnessPercent) {
        m_displayBrightnessPercent = m_pendingBrightnessPercent;
        emit displayChanged();
    }
    m_brightnessSetTimer.start();
}
