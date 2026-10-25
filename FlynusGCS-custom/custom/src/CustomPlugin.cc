#include "CustomPlugin.h"
#include "AppSettings.h"
#include "QGCLoggingCategory.h"
#include "QGCPalette.h"

#include <QtCore/QApplicationStatic>
#include <QtCore/QFile>
#include <QtQml/QQmlApplicationEngine>

QGC_LOGGING_CATEGORY(CustomLog, "Custom.CustomPlugin")

Q_APPLICATION_STATIC(CustomPlugin, _customPluginInstance);

// ---------------------------------------------------------------------------
// Flynus brand colors (sampled from the Flynus logo)
// ---------------------------------------------------------------------------
namespace {
constexpr const char *kFlynusGreen      = "#223B25";   // wordmark green
constexpr const char *kFlynusGreenLight = "#3E7A47";   // green for dark theme
constexpr const char *kFlynusRed        = "#BC0814";   // "F" red
constexpr const char *kFlynusRedLight   = "#FF4D57";   // red for dark theme

void setColor(QGCPalette::PaletteColorInfo_t &info,
              const char *lightEnabled, const char *lightDisabled,
              const char *darkEnabled,  const char *darkDisabled)
{
    info[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor(lightEnabled);
    info[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor(lightDisabled);
    info[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor(darkEnabled);
    info[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor(darkDisabled);
}
} // namespace

CustomPlugin::CustomPlugin(QObject *parent)
    : QGCCorePlugin(parent)
{
    qCDebug(CustomLog) << this;
}

QGCCorePlugin *CustomPlugin::instance()
{
    return _customPluginInstance();
}

void CustomPlugin::adjustSettingMetaData(const QString &settingsGroup, FactMetaData &metaData, bool &userVisible)
{
    QGCCorePlugin::adjustSettingMetaData(settingsGroup, metaData, userVisible);

    if (settingsGroup == AppSettings::settingsGroup) {
        if (metaData.name() == AppSettings::indoorPaletteName) {
            // Default to the white (light) theme on every platform.
            // Users can still switch in Application Settings > General > Color Scheme.
            metaData.setRawDefaultValue(0);
        }
    }
}

void CustomPlugin::paletteOverride(const QString &colorName, QGCPalette::PaletteColorInfo_t &c)
{
    //                                            Light enabled  Light disabled  Dark enabled      Dark disabled
    if      (colorName == QStringLiteral("window"))              setColor(c, "#FFFFFF", "#FFFFFF", "#1E2320", "#1E2320");
    else if (colorName == QStringLiteral("windowTransparent"))   setColor(c, "#E6FFFFFF", "#E6FFFFFF", "#CC1E2320", "#CC1E2320");
    else if (colorName == QStringLiteral("windowShade"))         setColor(c, "#F1F3F2", "#E6E8E7", "#2C332E", "#2C332E");
    else if (colorName == QStringLiteral("windowShadeDark"))     setColor(c, "#E2E6E3", "#CFD4D0", "#242A26", "#242A26");
    else if (colorName == QStringLiteral("text"))                setColor(c, "#1D2A1F", "#9AA39B", "#FFFFFF", "#707070");
    else if (colorName == QStringLiteral("warningText"))         setColor(c, kFlynusRed, kFlynusRed, kFlynusRedLight, kFlynusRedLight);
    else if (colorName == QStringLiteral("button"))              setColor(c, "#FFFFFF", "#FFFFFF", "#3A423C", "#3A423C");
    else if (colorName == QStringLiteral("buttonBorder"))        setColor(c, kFlynusGreen, "#B5BCB6", "#6AA874", "#5A625C");
    else if (colorName == QStringLiteral("buttonText"))          setColor(c, "#1D2A1F", "#9AA39B", "#FFFFFF", "#8A928C");
    else if (colorName == QStringLiteral("buttonHighlight"))     setColor(c, kFlynusGreen, "#E4E7E5", kFlynusGreenLight, "#3A3A3A");
    else if (colorName == QStringLiteral("buttonHighlightText")) setColor(c, "#FFFFFF", "#2C2C2C", "#FFFFFF", "#2C2C2C");
    else if (colorName == QStringLiteral("primaryButton"))       setColor(c, kFlynusGreen, "#B5BCB6", kFlynusGreenLight, "#585858");
    else if (colorName == QStringLiteral("primaryButtonText"))   setColor(c, "#FFFFFF", "#F0F0F0", "#FFFFFF", "#2C2C2C");
    else if (colorName == QStringLiteral("textField"))           setColor(c, "#FFFFFF", "#F1F3F2", "#FFFFFF", "#707070");
    else if (colorName == QStringLiteral("textFieldText"))       setColor(c, "#1D2A1F", "#808080", "#000000", "#000000");
    else if (colorName == QStringLiteral("groupBorder"))         setColor(c, kFlynusGreen, "#C8CDC9", "#4D5A4F", "#4D5A4F");
    else if (colorName == QStringLiteral("mapButtonHighlight"))  setColor(c, kFlynusRed, "#585858", kFlynusRedLight, "#585858");
    else if (colorName == QStringLiteral("mapIndicator"))        setColor(c, kFlynusRed, "#585858", kFlynusRedLight, "#585858");
    else if (colorName == QStringLiteral("colorRed"))            setColor(c, kFlynusRed, kFlynusRed, kFlynusRedLight, kFlynusRedLight);
    else if (colorName == QStringLiteral("missionItemEditor"))   setColor(c, "#E8EFE9", "#585858", "#2C3A2E", "#585858");
    else if (colorName == QStringLiteral("toolStripHoverColor")) setColor(c, "#C9D6CB", "#585858", "#3E5A43", "#585858");
    else if (colorName == QStringLiteral("brandingPurple"))      setColor(c, kFlynusGreen, kFlynusGreen, kFlynusGreen, kFlynusGreen);
    else if (colorName == QStringLiteral("brandingBlue"))        setColor(c, kFlynusRed, kFlynusRed, kFlynusRed, kFlynusRed);
}

QQmlApplicationEngine *CustomPlugin::createQmlApplicationEngine(QObject *parent)
{
    _qmlEngine = QGCCorePlugin::createQmlApplicationEngine(parent);
    _urlInterceptor = new CustomOverrideInterceptor();
    _qmlEngine->addUrlInterceptor(_urlInterceptor);
    return _qmlEngine;
}

void CustomPlugin::destroyQmlApplicationEngine(QQmlApplicationEngine *qmlEngine)
{
    if (qmlEngine && (qmlEngine == _qmlEngine)) {
        qmlEngine->removeUrlInterceptor(_urlInterceptor);
        delete _urlInterceptor;
        _urlInterceptor = nullptr;
        _qmlEngine = nullptr;
    }
    QGCCorePlugin::destroyQmlApplicationEngine(qmlEngine);
}

QUrl CustomOverrideInterceptor::intercept(const QUrl &url, QQmlAbstractUrlInterceptor::DataType type)
{
    if ((type == QQmlAbstractUrlInterceptor::QmlFile || type == QQmlAbstractUrlInterceptor::UrlString)
            && url.scheme() == QStringLiteral("qrc")) {
        const QString overrideRes = QStringLiteral(":/Custom%1").arg(url.path());
        if (QFile::exists(overrideRes)) {
            QUrl result;
            result.setScheme(QStringLiteral("qrc"));
            result.setPath(QStringLiteral("/Custom%1").arg(url.path()));
            return result;
        }
    }
    return url;
}
