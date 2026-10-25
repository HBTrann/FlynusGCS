#pragma once

#include <QtQml/QQmlAbstractUrlInterceptor>

#include "QGCCorePlugin.h"

class QQmlApplicationEngine;

Q_DECLARE_LOGGING_CATEGORY(CustomLog)

/// Flynus GCS core plugin: branding only (colors, logos, defaults).
/// All stock QGroundControl features stay enabled.
class CustomPlugin : public QGCCorePlugin
{
    Q_OBJECT

public:
    explicit CustomPlugin(QObject *parent = nullptr);

    static QGCCorePlugin *instance();

    void adjustSettingMetaData(const QString &settingsGroup, FactMetaData &metaData, bool &userVisible) final;
    void paletteOverride(const QString &colorName, QGCPalette::PaletteColorInfo_t &colorInfo) final;
    QQmlApplicationEngine *createQmlApplicationEngine(QObject *parent) final;
    void destroyQmlApplicationEngine(QQmlApplicationEngine *qmlEngine) final;

    /// Disable the "new QGroundControl version available" check.
    QString stableVersionCheckFileUrl() const final { return QString(); }

private:
    QQmlApplicationEngine *_qmlEngine = nullptr;
    class CustomOverrideInterceptor *_urlInterceptor = nullptr;
};

/// Redirects qrc:/<path> to qrc:/Custom/<path> when an override exists in custom.qrc.
class CustomOverrideInterceptor : public QQmlAbstractUrlInterceptor
{
public:
    QUrl intercept(const QUrl &url, QQmlAbstractUrlInterceptor::DataType type) final;
};
