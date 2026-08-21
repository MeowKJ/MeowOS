#pragma once

#include <QObject>
#include <QFutureWatcher>
#include <QProcess>
#include <QTimer>
#include <QVariantMap>
#include <QVariantList>

class SystemBackend final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString hostname READ hostname NOTIFY systemInfoChanged)
    Q_PROPERTY(QString kernel READ kernel NOTIFY systemInfoChanged)
    Q_PROPERTY(QString diskUsed READ diskUsed NOTIFY storageChanged)
    Q_PROPERTY(QString diskTotal READ diskTotal NOTIFY storageChanged)
    Q_PROPERTY(int diskPercent READ diskPercent NOTIFY storageChanged)
    Q_PROPERTY(bool nvmeAvailable READ nvmeAvailable NOTIFY storageChanged)
    Q_PROPERTY(bool nvmeMounted READ nvmeMounted NOTIFY storageChanged)
    Q_PROPERTY(QString nvmeModel READ nvmeModel NOTIFY storageChanged)
    Q_PROPERTY(QString nvmeMountPoint READ nvmeMountPoint NOTIFY storageChanged)
    Q_PROPERTY(QString nvmeUsed READ nvmeUsed NOTIFY storageChanged)
    Q_PROPERTY(QString nvmeTotal READ nvmeTotal NOTIFY storageChanged)
    Q_PROPERTY(int nvmePercent READ nvmePercent NOTIFY storageChanged)
    Q_PROPERTY(QString wifiName READ wifiName NOTIFY wifiChanged)
    Q_PROPERTY(bool wifiConnected READ wifiConnected NOTIFY wifiChanged)
    Q_PROPERTY(bool wifiScanning READ wifiScanning NOTIFY wifiChanged)
    Q_PROPERTY(bool wifiOperating READ wifiOperating NOTIFY wifiChanged)
    Q_PROPERTY(QString wifiOperation READ wifiOperation NOTIFY wifiChanged)
    Q_PROPERTY(QString wifiOperationSsid READ wifiOperationSsid NOTIFY wifiChanged)
    Q_PROPERTY(QString wifiScanError READ wifiScanError NOTIFY wifiChanged)
    Q_PROPERTY(QVariantList wifiNetworks READ wifiNetworks NOTIFY wifiChanged)
    Q_PROPERTY(QVariantList ethernetPorts READ ethernetPorts NOTIFY ethernetChanged)
    Q_PROPERTY(bool batteryAvailable READ batteryAvailable NOTIFY powerChanged)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY powerChanged)
    Q_PROPERTY(QString batteryStatus READ batteryStatus NOTIFY powerChanged)
    Q_PROPERTY(bool batteryCharging READ batteryCharging NOTIFY powerChanged)
    Q_PROPERTY(bool chargerAvailable READ chargerAvailable NOTIFY powerChanged)
    Q_PROPERTY(bool externalPowerPresent READ externalPowerPresent NOTIFY powerChanged)
    Q_PROPERTY(double batteryTemperatureC READ batteryTemperatureC NOTIFY powerChanged)
    Q_PROPERTY(QString chargeTemperatureZone READ chargeTemperatureZone NOTIFY powerChanged)
    Q_PROPERTY(int batteryVoltageMv READ batteryVoltageMv NOTIFY powerChanged)
    Q_PROPERTY(int batteryCurrentMa READ batteryCurrentMa NOTIFY powerChanged)
    Q_PROPERTY(QString batteryHealth READ batteryHealth NOTIFY powerChanged)
    Q_PROPERTY(double batteryPowerW READ batteryPowerW NOTIFY powerChanged)
    Q_PROPERTY(int volumePercent READ volumePercent NOTIFY audioChanged)
    Q_PROPERTY(bool audioAvailable READ audioAvailable NOTIFY audioChanged)
    Q_PROPERTY(int displayBrightnessPercent READ displayBrightnessPercent NOTIFY displayChanged)
    Q_PROPERTY(bool brightnessAvailable READ brightnessAvailable NOTIFY displayChanged)
    Q_PROPERTY(int displayRotation READ displayRotation CONSTANT)

public:
    explicit SystemBackend(QObject *parent = nullptr);

    QString version() const;
    QString hostname() const;
    QString kernel() const;
    QString diskUsed() const;
    QString diskTotal() const;
    int diskPercent() const;
    bool nvmeAvailable() const;
    bool nvmeMounted() const;
    QString nvmeModel() const;
    QString nvmeMountPoint() const;
    QString nvmeUsed() const;
    QString nvmeTotal() const;
    int nvmePercent() const;
    QString wifiName() const;
    bool wifiConnected() const;
    bool wifiScanning() const;
    bool wifiOperating() const;
    QString wifiOperation() const;
    QString wifiOperationSsid() const;
    QString wifiScanError() const;
    QVariantList wifiNetworks() const;
    QVariantList ethernetPorts() const;
    bool batteryAvailable() const;
    int batteryPercent() const;
    QString batteryStatus() const;
    bool batteryCharging() const;
    bool chargerAvailable() const;
    bool externalPowerPresent() const;
    double batteryTemperatureC() const;
    QString chargeTemperatureZone() const;
    int batteryVoltageMv() const;
    int batteryCurrentMa() const;
    QString batteryHealth() const;
    double batteryPowerW() const;
    int volumePercent() const;
    bool audioAvailable() const;
    int displayBrightnessPercent() const;
    bool brightnessAvailable() const;
    int displayRotation() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void refreshStatus();
    Q_INVOKABLE void scanWifi();
    Q_INVOKABLE void connectWifi(const QString &ssid, const QString &password);
    Q_INVOKABLE void forgetWifi(const QString &ssid);
    Q_INVOKABLE void setVolume(int percent);
    Q_INVOKABLE void playVolumeFeedback();
    Q_INVOKABLE void setDisplayBrightness(int percent);

signals:
    void systemInfoChanged();
    void storageChanged();
    void wifiChanged();
    void ethernetChanged();
    void powerChanged();
    void audioChanged();
    void displayChanged();
    void operationMessage(const QString &message, bool success);

private:
    void refreshSystem();
    void refreshStorage();
    void applyStatusSnapshot(const QVariantMap &snapshot);

    QString m_hostname;
    QString m_kernel;
    QString m_diskUsed;
    QString m_diskTotal;
    int m_diskPercent = 0;
    bool m_nvmeAvailable = false;
    bool m_nvmeMounted = false;
    QString m_nvmeModel;
    QString m_nvmeMountPoint;
    QString m_nvmeUsed;
    QString m_nvmeTotal;
    int m_nvmePercent = 0;
    QString m_wifiName;
    QString m_wifiOperation;
    QString m_wifiOperationSsid;
    QString m_wifiScanError;
    QVariantList m_wifiNetworks;
    QVariantList m_ethernetPorts;
    bool m_batteryAvailable = false;
    int m_batteryPercent = -1;
    QString m_batteryStatus;
    bool m_batteryCharging = false;
    bool m_chargerAvailable = false;
    bool m_externalPowerPresent = false;
    double m_batteryTemperatureC = -273.15;
    QString m_chargeTemperatureZone;
    int m_batteryVoltageMv = -1;
    int m_batteryCurrentMa = 0;
    QString m_batteryHealth;
    int m_volumePercent = -1;
    bool m_audioAvailable = false;
    int m_displayBrightnessPercent = -1;
    bool m_brightnessAvailable = false;
    QString m_backlightPath;
    int m_brightnessMax = 0;
    bool m_statusRefreshPending = false;
    QFutureWatcher<QVariantMap> m_statusWatcher;
    QFutureWatcher<QVariantMap> m_wifiScanWatcher;
    QFutureWatcher<QVariantMap> m_wifiOperationWatcher;
    int m_pendingVolumePercent = 65;
    QTimer m_volumeSetTimer;
    QProcess m_volumeSetProcess;
    QProcess m_feedbackProcess;
    int m_pendingBrightnessPercent = 30;
    QTimer m_brightnessSetTimer;
};
