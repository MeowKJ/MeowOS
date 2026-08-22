#include "systembackend.h"

#include <QtConcurrent/QtConcurrentRun>
#include <QAbstractSocket>
#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QNetworkAddressEntry>
#include <QNetworkInterface>
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

struct ProcessResult {
    QString output;
    int exitCode = -1;
    bool started = false;
    bool timedOut = false;

    bool ok() const { return started && !timedOut && exitCode == 0; }
};

ProcessResult runProcessDetailed(const QString &program, const QStringList &arguments, int timeoutMs = 5000)
{
    ProcessResult result;
    QProcess process;
    process.setProcessChannelMode(QProcess::MergedChannels);
    process.start(program, arguments);
    result.started = process.waitForStarted(qMin(timeoutMs, 3000));
    if (!result.started) return result;
    if (!process.waitForFinished(timeoutMs)) {
        result.timedOut = true;
        process.kill();
        process.waitForFinished(500);
    }
    result.output = QString::fromLocal8Bit(process.readAll()).trimmed();
    result.exitCode = process.exitCode();
    return result;
}

QString runProcess(const QString &program, const QStringList &arguments, int timeoutMs = 5000)
{
    const ProcessResult result = runProcessDetailed(program, arguments, timeoutMs);
    return result.started && !result.timedOut ? result.output : QString();
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

QVariantList collectEthernetPorts()
{
    QVariantList ports;
    for (const QString &name : {QStringLiteral("eth0"), QStringLiteral("eth1")}) {
        const QString base = QStringLiteral("/sys/class/net/") + name;
        if (!QFileInfo::exists(base)) continue;

        qint64 carrierValue = 0;
        const bool carrier = readInteger(base + QStringLiteral("/carrier"), &carrierValue) && carrierValue == 1;
        qint64 speedValue = -1;
        readInteger(base + QStringLiteral("/speed"), &speedValue);
        qint64 mtuValue = 0;
        readInteger(base + QStringLiteral("/mtu"), &mtuValue);

        QString ipv4;
        QString ipv6;
        const QNetworkInterface interface = QNetworkInterface::interfaceFromName(name);
        for (const QNetworkAddressEntry &address : interface.addressEntries()) {
            const QHostAddress ip = address.ip();
            const QString formatted = ip.toString() + QLatin1Char('/') + QString::number(address.prefixLength());
            if (ip.protocol() == QAbstractSocket::IPv4Protocol && ipv4.isEmpty()) ipv4 = formatted;
            else if (ip.protocol() == QAbstractSocket::IPv6Protocol && ipv6.isEmpty()
                     && !ip.isLinkLocal()) ipv6 = formatted;
        }

        QVariantMap port;
        port.insert(QStringLiteral("name"), name);
        port.insert(QStringLiteral("connected"), carrier);
        port.insert(QStringLiteral("state"), readTextFile(base + QStringLiteral("/operstate")));
        port.insert(QStringLiteral("speed"), carrier && speedValue > 0 ? static_cast<int>(speedValue) : 0);
        port.insert(QStringLiteral("duplex"), carrier ? readTextFile(base + QStringLiteral("/duplex")) : QString());
        port.insert(QStringLiteral("mac"), readTextFile(base + QStringLiteral("/address")));
        port.insert(QStringLiteral("mtu"), static_cast<int>(mtuValue));
        port.insert(QStringLiteral("ipv4"), ipv4);
        port.insert(QStringLiteral("ipv6"), ipv6);
        ports.append(port);
    }
    return ports;
}

bool parseCpuLine(const QByteArray &line, QVector<quint64> *idleOut, QVector<quint64> *totalOut)
{
    // "cpu0  user nice system idle iowait irq softirq steal guest guest_nice"
    QList<QByteArray> parts = line.split(' ');
    parts.removeAll(QByteArray());
    if (parts.size() < 5) return false;
    const int count = qMin(8, parts.size() - 1);
    quint64 values[8] = {};
    for (int i = 0; i < count; ++i) {
        bool ok = false;
        values[i] = parts.at(i + 1).toULongLong(&ok);
        if (!ok) return false;
    }
    quint64 total = 0;
    for (int i = 0; i < count; ++i) total += values[i];
    idleOut->append(values[3] + values[4]);
    totalOut->append(total);
    return true;
}

int parseGpuBusy(const QString &text)
{
    QString value = text.trimmed();
    if (value.isEmpty()) return -1;
    if (value.endsWith(QLatin1Char('%'))) value.chop(1);
    value = value.trimmed();
    bool ok = false;
    const qint64 parsed = value.toLongLong(&ok);
    if (!ok || parsed < 0 || parsed > 100) return -1;
    return static_cast<int>(parsed);
}

QVariantMap collectStatus(const QString &scope)
{
    QVariantMap result;
    if (scope != QStringLiteral("idle")) {
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

        if (!currentWifi.isEmpty() && scope == QStringLiteral("wifi")) {
            QString wifiDevice;
            QString wifiIpv4;
            QString wifiGateway;
            QString wifiMac;
            const QString deviceStatus = runProcess(QStringLiteral("nmcli"),
                                                    {QStringLiteral("-t"), QStringLiteral("-e"), QStringLiteral("yes"),
                                                     QStringLiteral("-f"), QStringLiteral("DEVICE,TYPE,STATE"),
                                                     QStringLiteral("device"), QStringLiteral("status")}, 1500);
            for (const QString &line : deviceStatus.split(QRegularExpression(QStringLiteral("\\r?\\n")), Qt::SkipEmptyParts)) {
                const QStringList fields = splitNmcliTerseLine(line);
                if (fields.size() >= 3 && fields.at(1) == QStringLiteral("wifi")
                        && fields.at(2).startsWith(QStringLiteral("connected"))) {
                    wifiDevice = fields.at(0);
                    break;
                }
            }
            if (wifiDevice.isEmpty()) wifiDevice = QStringLiteral("wlan0");

            const QNetworkInterface interface = QNetworkInterface::interfaceFromName(wifiDevice);
            for (const QNetworkAddressEntry &address : interface.addressEntries()) {
                const QHostAddress ip = address.ip();
                if (ip.protocol() == QAbstractSocket::IPv4Protocol && wifiIpv4.isEmpty()) {
                    wifiIpv4 = ip.toString();
                    break;
                }
            }

            const QString deviceShow = runProcess(QStringLiteral("nmcli"),
                                                  {QStringLiteral("-t"), QStringLiteral("-e"), QStringLiteral("yes"),
                                                   QStringLiteral("-f"), QStringLiteral("IP4.GATEWAY,GENERAL.HWADDR"),
                                                   QStringLiteral("device"), QStringLiteral("show"), wifiDevice}, 1500);
            for (const QString &line : deviceShow.split(QRegularExpression(QStringLiteral("\\r?\\n")), Qt::SkipEmptyParts)) {
                const int sep = line.indexOf(QLatin1Char(':'));
                if (sep <= 0) continue;
                const QString key = line.left(sep);
                const QString value = line.mid(sep + 1).trimmed();
                if (key == QStringLiteral("IP4.GATEWAY") && wifiGateway.isEmpty()) wifiGateway = value;
                else if (key.endsWith(QStringLiteral("HWADDR")) && wifiMac.isEmpty()) wifiMac = value;
            }
            if (wifiMac.isEmpty()) wifiMac = readTextFile(QStringLiteral("/sys/class/net/") + wifiDevice + QStringLiteral("/address"));
            result.insert(QStringLiteral("wifiDevice"), wifiDevice);
            result.insert(QStringLiteral("wifiIpv4"), wifiIpv4);
            result.insert(QStringLiteral("wifiGateway"), wifiGateway);
            result.insert(QStringLiteral("wifiMac"), wifiMac);
        }
    }

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
    if (scope == QStringLiteral("sound")) {
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
    if (scope == QStringLiteral("ethernet")) {
        result.insert(QStringLiteral("ethernetPorts"), collectEthernetPorts());
    }
    return result;
}

QString wifiFailureMessage(const ProcessResult &result, const QString &operation)
{
    if (result.timedOut) {
        if (operation == QStringLiteral("connect")) return QStringLiteral("Wi-Fi 连接超时");
        if (operation == QStringLiteral("forget")) return QStringLiteral("删除网络超时");
        return QStringLiteral("Wi-Fi 扫描超时");
    }
    const QString output = result.output;
    if (output.contains(QStringLiteral("not authorized"), Qt::CaseInsensitive)) {
        return operation == QStringLiteral("scan") ? QStringLiteral("没有 Wi-Fi 扫描权限")
                                                    : QStringLiteral("没有修改网络的权限");
    }
    if (output.contains(QStringLiteral("No network with SSID"), Qt::CaseInsensitive)
            || output.contains(QStringLiteral("not found"), Qt::CaseInsensitive)) {
        return QStringLiteral("未找到该网络，请重新扫描");
    }
    if (output.contains(QStringLiteral("Secrets were required"), Qt::CaseInsensitive)
            || output.contains(QStringLiteral("password"), Qt::CaseInsensitive)) {
        return QStringLiteral("密码错误或认证失败");
    }
    if (output.contains(QStringLiteral("unavailable"), Qt::CaseInsensitive)) {
        return QStringLiteral("无线网卡当前不可用");
    }
    if (operation == QStringLiteral("connect")) return QStringLiteral("Wi-Fi 连接失败");
    if (operation == QStringLiteral("forget")) return QStringLiteral("删除网络失败");
    return QStringLiteral("Wi-Fi 扫描失败");
}

QVariantMap collectWifiNetworks()
{
    QVariantMap result;
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

    const ProcessResult scanResult = runProcessDetailed(QStringLiteral("nmcli"),
                                                         {QStringLiteral("device"), QStringLiteral("wifi"),
                                                          QStringLiteral("rescan"), QStringLiteral("ifname"),
                                                          QStringLiteral("wlan0")}, 12000);
    const ProcessResult listResult = runProcessDetailed(QStringLiteral("nmcli"),
                                                         {QStringLiteral("-t"), QStringLiteral("-e"),
                                                          QStringLiteral("yes"), QStringLiteral("-f"),
                                                          QStringLiteral("IN-USE,SSID,SIGNAL,CHAN,FREQ,RATE,SECURITY,BARS"),
                                                          QStringLiteral("device"), QStringLiteral("wifi"),
                                                          QStringLiteral("list"), QStringLiteral("ifname"),
                                                          QStringLiteral("wlan0"), QStringLiteral("--rescan"),
                                                          QStringLiteral("no")}, 5000);
    QVariantList networks;
    QSet<QString> seen;
    for (const QString &line : listResult.output.split(QRegularExpression(QStringLiteral("\\r?\\n")), Qt::SkipEmptyParts)) {
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
    const bool ok = scanResult.ok() && listResult.ok();
    result.insert(QStringLiteral("ok"), ok);
    result.insert(QStringLiteral("networks"), networks);
    result.insert(QStringLiteral("message"), ok ? QString()
                                                 : wifiFailureMessage(scanResult.ok() ? listResult : scanResult,
                                                                      QStringLiteral("scan")));
    return result;
}

QVariantMap runWifiOperation(const QString &operation, const QString &ssid, const QString &password)
{
    QVariantMap result;
    ProcessResult processResult;
    if (operation == QStringLiteral("connect")) {
        const ProcessResult savedProfile = runProcessDetailed(QStringLiteral("nmcli"),
                                                               {QStringLiteral("connection"), QStringLiteral("show"),
                                                                QStringLiteral("id"), ssid}, 3000);
        if (!password.isEmpty() && savedProfile.ok()) {
            const ProcessResult updatePassword = runProcessDetailed(QStringLiteral("nmcli"),
                                                                     {QStringLiteral("connection"), QStringLiteral("modify"),
                                                                      QStringLiteral("id"), ssid,
                                                                      QStringLiteral("802-11-wireless-security.psk"), password}, 5000);
            processResult = updatePassword.ok()
                    ? runProcessDetailed(QStringLiteral("nmcli"),
                                         {QStringLiteral("connection"), QStringLiteral("up"),
                                          QStringLiteral("id"), ssid, QStringLiteral("ifname"),
                                          QStringLiteral("wlan0")}, 30000)
                    : updatePassword;
        } else {
            QStringList arguments{QStringLiteral("device"), QStringLiteral("wifi"), QStringLiteral("connect"), ssid,
                                  QStringLiteral("ifname"), QStringLiteral("wlan0")};
            if (!password.isEmpty()) arguments << QStringLiteral("password") << password;
            processResult = runProcessDetailed(QStringLiteral("nmcli"), arguments, 30000);
        }
    } else {
        processResult = runProcessDetailed(QStringLiteral("nmcli"),
                                           {QStringLiteral("connection"), QStringLiteral("delete"),
                                            QStringLiteral("id"), ssid}, 8000);
    }
    const bool ok = processResult.ok();
    result.insert(QStringLiteral("ok"), ok);
    result.insert(QStringLiteral("operation"), operation);
    result.insert(QStringLiteral("message"), ok
                  ? (operation == QStringLiteral("connect") ? QStringLiteral("Wi-Fi 已连接")
                                                             : QStringLiteral("已忘记网络"))
                  : wifiFailureMessage(processResult, operation));
    return result;
}

} // namespace

SystemBackend::SystemBackend(QObject *parent)
    : QObject(parent), m_statusWatcher(this), m_wifiScanWatcher(this), m_wifiOperationWatcher(this)
{
    m_lastInputMs = QDateTime::currentMSecsSinceEpoch();
    if (qApp) qApp->installEventFilter(this);
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
    connect(&m_wifiScanWatcher, &QFutureWatcher<QVariantMap>::finished, this, [this]() {
        const QVariantMap result = m_wifiScanWatcher.result();
        m_wifiNetworks = result.value(QStringLiteral("networks")).toList();
        m_wifiScanError = result.value(QStringLiteral("message")).toString();
        emit wifiChanged();
        refreshStatus();
    });
    connect(&m_wifiOperationWatcher, &QFutureWatcher<QVariantMap>::finished, this, [this]() {
        const QVariantMap result = m_wifiOperationWatcher.result();
        const bool ok = result.value(QStringLiteral("ok")).toBool();
        m_wifiOperation.clear();
        m_wifiOperationSsid.clear();
        emit wifiChanged();
        emit operationMessage(result.value(QStringLiteral("message")).toString(), ok);
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
QString SystemBackend::wifiIpv4() const { return m_wifiIpv4; }
QString SystemBackend::wifiGateway() const { return m_wifiGateway; }
QString SystemBackend::wifiMac() const { return m_wifiMac; }
QString SystemBackend::wifiDevice() const { return m_wifiDevice; }
bool SystemBackend::wifiScanning() const { return m_wifiScanWatcher.isRunning(); }
bool SystemBackend::wifiOperating() const { return m_wifiOperationWatcher.isRunning(); }
QString SystemBackend::wifiOperation() const { return m_wifiOperation; }
QString SystemBackend::wifiOperationSsid() const { return m_wifiOperationSsid; }
QString SystemBackend::wifiScanError() const { return m_wifiScanError; }
QVariantList SystemBackend::wifiNetworks() const { return m_wifiNetworks; }
QVariantList SystemBackend::ethernetPorts() const { return m_ethernetPorts; }
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
int SystemBackend::cpuTotal() const { return m_cpuTotal; }
QVariantList SystemBackend::cpuUsage() const { return m_cpuUsage; }
int SystemBackend::gpuUsage() const { return m_gpuUsage; }
int SystemBackend::memoryPercent() const { return m_memoryPercent; }
QString SystemBackend::memoryUsed() const { return formatBytes(m_memoryUsedBytes); }
QString SystemBackend::memoryTotal() const { return formatBytes(m_memoryTotalBytes); }

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
    refreshPerformance();
}

void SystemBackend::refreshStatus()
{
    if (m_statusWatcher.isRunning()) {
        m_statusRefreshPending = true;
        return;
    }
    m_statusWatcher.setFuture(QtConcurrent::run(collectStatus, m_activeScope));
}

void SystemBackend::setActiveScope(const QString &scope)
{
    if (m_activeScope == scope) return;
    m_activeScope = scope;
    if (!m_statusWatcher.isRunning()) refreshStatus();
}

qint64 SystemBackend::idleMs() const
{
    return QDateTime::currentMSecsSinceEpoch() - m_lastInputMs;
}

bool SystemBackend::eventFilter(QObject *watched, QEvent *event)
{
    Q_UNUSED(watched)
    switch (event->type()) {
    case QEvent::MouseButtonPress:
    case QEvent::TouchBegin:
    case QEvent::KeyPress:
        m_lastInputMs = QDateTime::currentMSecsSinceEpoch();
        emit inputActivity();
        break;
    case QEvent::MouseButtonRelease:
    case QEvent::TouchEnd:
    case QEvent::Wheel:
        m_lastInputMs = QDateTime::currentMSecsSinceEpoch();
        break;
    default:
        break;
    }
    return false;
}

void SystemBackend::refreshPerformance()
{
    QVector<quint64> idle;
    QVector<quint64> total;
    QFile statFile(QStringLiteral("/proc/stat"));
    if (statFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        while (!statFile.atEnd()) {
            const QByteArray line = statFile.readLine().trimmed();
            if (!line.startsWith("cpu")) continue;
            parseCpuLine(line, &idle, &total);
        }
    }
    if (idle.isEmpty() || total.isEmpty() || idle.size() != total.size()) return;

    QVariantList usage;
    if (m_cpuHavePrev && m_cpuPrevIdle.size() == idle.size()) {
        for (int i = 0; i < idle.size(); ++i) {
            const qint64 idleDelta = static_cast<qint64>(idle.at(i) - m_cpuPrevIdle.at(i));
            const qint64 totalDelta = static_cast<qint64>(total.at(i) - m_cpuPrevTotal.at(i));
            const int percent = totalDelta > 0
                    ? qBound(0, static_cast<int>(100.0 * (totalDelta - idleDelta) / totalDelta), 100)
                    : 0;
            usage.append(percent);
        }
    } else {
        for (int i = 0; i < idle.size(); ++i) usage.append(0);
    }
    m_cpuHavePrev = true;
    m_cpuPrevIdle = idle;
    m_cpuPrevTotal = total;
    const int cpuTotal = usage.isEmpty() ? -1 : usage.at(0).toInt();

    int gpu = -1;
    for (const QString &path : {QStringLiteral("/sys/kernel/gpu/gpu_busy"),
                                QStringLiteral("/sys/kernel/gpu/gpu_utilization")}) {
        const QString text = readTextFile(path);
        if (text.isEmpty()) continue;
        const int parsed = parseGpuBusy(text);
        if (parsed >= 0) { gpu = parsed; break; }
    }

    qint64 memTotal = 0;
    qint64 memAvailable = 0;
    QFile memInfo(QStringLiteral("/proc/meminfo"));
    if (memInfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        while (!memInfo.atEnd()) {
            const QString line = QString::fromLatin1(memInfo.readLine().trimmed());
            if (line.startsWith(QStringLiteral("MemTotal"))) memTotal = line.section(QLatin1Char(' '), -2, -2).toLongLong();
            else if (line.startsWith(QStringLiteral("MemAvailable"))) memAvailable = line.section(QLatin1Char(' '), -2, -2).toLongLong();
            if (memTotal > 0 && memAvailable > 0) break;
        }
    }
    const qint64 memUsed = qMax<qint64>(0, memTotal - memAvailable);
    const int memPercent = memTotal > 0 ? qBound(0, static_cast<int>(100.0 * memUsed / memTotal), 100) : -1;

    if (cpuTotal != m_cpuTotal || usage != m_cpuUsage || gpu != m_gpuUsage
            || memPercent != m_memoryPercent || memUsed != m_memoryUsedBytes
            || memTotal != m_memoryTotalBytes) {
        m_cpuTotal = cpuTotal;
        m_cpuUsage = usage;
        m_gpuUsage = gpu;
        m_memoryPercent = memPercent;
        m_memoryUsedBytes = memUsed;
        m_memoryTotalBytes = memTotal;
        emit performanceChanged();
    }
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
    if (snapshot.contains(QStringLiteral("wifiName"))) {
        const QString wifiName = snapshot.value(QStringLiteral("wifiName")).toString();
        QString wifiIpv4 = m_wifiIpv4;
        QString wifiGateway = m_wifiGateway;
        QString wifiMac = m_wifiMac;
        QString wifiDevice = m_wifiDevice;
        if (snapshot.contains(QStringLiteral("wifiIpv4"))) wifiIpv4 = snapshot.value(QStringLiteral("wifiIpv4")).toString();
        if (snapshot.contains(QStringLiteral("wifiGateway"))) wifiGateway = snapshot.value(QStringLiteral("wifiGateway")).toString();
        if (snapshot.contains(QStringLiteral("wifiMac"))) wifiMac = snapshot.value(QStringLiteral("wifiMac")).toString();
        if (snapshot.contains(QStringLiteral("wifiDevice"))) wifiDevice = snapshot.value(QStringLiteral("wifiDevice")).toString();
        if (wifiName != m_wifiName || wifiIpv4 != m_wifiIpv4 || wifiGateway != m_wifiGateway
                || wifiMac != m_wifiMac || wifiDevice != m_wifiDevice) {
            m_wifiName = wifiName;
            m_wifiIpv4 = wifiIpv4;
            m_wifiGateway = wifiGateway;
            m_wifiMac = wifiMac;
            m_wifiDevice = wifiDevice;
            emit wifiChanged();
        }
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
    const bool hasVolume = snapshot.contains(QStringLiteral("volumePercent"));
    if ((hasVolume && volumePercent != m_volumePercent) || audioAvailable != m_audioAvailable) {
        if (hasVolume) m_volumePercent = volumePercent;
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

    const QVariantList ethernetPorts = snapshot.value(QStringLiteral("ethernetPorts")).toList();
    if (snapshot.contains(QStringLiteral("ethernetPorts")) && ethernetPorts != m_ethernetPorts) {
        m_ethernetPorts = ethernetPorts;
        emit ethernetChanged();
    }
}

void SystemBackend::scanWifi()
{
    if (m_wifiScanWatcher.isRunning()) return;
    if (!m_wifiScanError.isEmpty()) {
        m_wifiScanError.clear();
        emit wifiChanged();
    }
    m_wifiScanWatcher.setFuture(QtConcurrent::run(collectWifiNetworks));
    emit wifiChanged();
}

void SystemBackend::connectWifi(const QString &ssid, const QString &password)
{
    if (!m_wifiOperationWatcher.isRunning()) {
        m_wifiOperation = QStringLiteral("connect");
        m_wifiOperationSsid = ssid;
        m_wifiOperationWatcher.setFuture(QtConcurrent::run(runWifiOperation, QStringLiteral("connect"), ssid, password));
        emit wifiChanged();
    }
}

void SystemBackend::forgetWifi(const QString &ssid)
{
    if (!m_wifiOperationWatcher.isRunning()) {
        m_wifiOperation = QStringLiteral("forget");
        m_wifiOperationSsid = ssid;
        m_wifiOperationWatcher.setFuture(QtConcurrent::run(runWifiOperation, QStringLiteral("forget"), ssid, QString()));
        emit wifiChanged();
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
