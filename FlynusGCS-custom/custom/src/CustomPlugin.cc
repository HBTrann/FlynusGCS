#include "CustomPlugin.h"
#include "AppSettings.h"
#include "QGCLoggingCategory.h"
#include "QGCPalette.h"

#include <QtCore/QApplicationStatic>
#include <QtCore/QFile>
#include <QtGui/QFontDatabase>
#include <QtQml/QQmlApplicationEngine>

QGC_LOGGING_CATEGORY(CustomLog, "Custom.CustomPlugin")

Q_APPLICATION_STATIC(CustomPlugin, _customPluginInstance);

// ---------------------------------------------------------------------------
// Flynus brand colors (sampled from the Flynus logo)
// ---------------------------------------------------------------------------
namespace {
constexpr const char *kFlynusGreen      = "#223B25";   // wordmark green
constexpr const char *kFlynusRed        = "#BC0814";   // "F" red
constexpr const char *kFlynusRedLight   = "#FF4D57";   // red for dark theme
constexpr const char *kFlynusAccent     = "#2FBF4A";   // bright green accent (Flynus Dark)

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

void CustomPlugin::init()
{
    QGCCorePlugin::init();

    // Flynus UI font: Barlow (SIL OFL 1.1), re-labelled with the family name "Open Sans"
    // because QGC hard-codes that family in ScreenToolsController::normalFontFamily().
    // Remove the stock Open Sans application fonts first so ours are the only match.
    for (int id = 0; id < 32; id++) {
        const QStringList families = QFontDatabase::applicationFontFamilies(id);
        for (const QString &family : families) {
            if (family.startsWith(QStringLiteral("Open Sans"))) {
                (void) QFontDatabase::removeApplicationFont(id);
                break;
            }
        }
    }
    static const char *const fonts[] = {
        ":/flynus/fonts/FlynusUI-Regular.ttf",
        ":/flynus/fonts/FlynusUI-SemiBold.ttf",
        ":/flynus/fonts/FlynusUI-Bold.ttf",
    };
    for (const char *font : fonts) {
        if (QFontDatabase::addApplicationFont(QString::fromLatin1(font)) < 0) {
            qCWarning(CustomLog) << "Could not load font" << font;
        }
    }
}

void CustomPlugin::adjustSettingMetaData(const QString &settingsGroup, FactMetaData &metaData, bool &userVisible)
{
    QGCCorePlugin::adjustSettingMetaData(settingsGroup, metaData, userVisible);

    if (settingsGroup == AppSettings::settingsGroup) {
        if (metaData.name() == AppSettings::indoorPaletteName) {
            // Default to the "Flynus Dark" theme (1 = Indoor/Dark) on every platform.
            // Users can still switch in Application Settings > General > Color Scheme.
            metaData.setRawDefaultValue(1);
        }
    }
}

void CustomPlugin::paletteOverride(const QString &colorName, QGCPalette::PaletteColorInfo_t &c)
{
    // Dark = "Flynus Dark" (default theme), Light = white theme.
    //                                            Light enabled  Light disabled  Dark enabled   Dark disabled
    if      (colorName == QStringLiteral("window"))              setColor(c, "#FFFFFF", "#FFFFFF", "#141815", "#141815");
    else if (colorName == QStringLiteral("windowTransparent"))   setColor(c, "#E6FFFFFF", "#E6FFFFFF", "#CC141815", "#CC141815");
    else if (colorName == QStringLiteral("windowShade"))         setColor(c, "#F1F3F2", "#E6E8E7", "#1C221E", "#1C221E");
    else if (colorName == QStringLiteral("windowShadeDark"))     setColor(c, "#E2E6E3", "#CFD4D0", "#101311", "#101311");
    else if (colorName == QStringLiteral("text"))                setColor(c, "#1D2A1F", "#9AA39B", "#F2F5F3", "#6F7A72");
    else if (colorName == QStringLiteral("warningText"))         setColor(c, kFlynusRed, kFlynusRed, kFlynusRedLight, kFlynusRedLight);
    else if (colorName == QStringLiteral("button"))              setColor(c, "#FFFFFF", "#FFFFFF", "#232A25", "#232A25");
    else if (colorName == QStringLiteral("buttonBorder"))        setColor(c, kFlynusGreen, "#B5BCB6", kFlynusAccent, "#3A423C");
    else if (colorName == QStringLiteral("buttonText"))          setColor(c, "#1D2A1F", "#9AA39B", "#F2F5F3", "#6F7A72");
    else if (colorName == QStringLiteral("buttonHighlight"))     setColor(c, kFlynusGreen, "#E4E7E5", kFlynusAccent, "#2C332E");
    else if (colorName == QStringLiteral("buttonHighlightText")) setColor(c, "#FFFFFF", "#2C2C2C", "#0B0D0C", "#2C2C2C");
    else if (colorName == QStringLiteral("primaryButton"))       setColor(c, kFlynusGreen, "#B5BCB6", kFlynusAccent, "#3A423C");
    else if (colorName == QStringLiteral("primaryButtonText"))   setColor(c, "#FFFFFF", "#F0F0F0", "#0B0D0C", "#6F7A72");
    else if (colorName == QStringLiteral("textField"))           setColor(c, "#FFFFFF", "#F1F3F2", "#1C221E", "#141815");
    else if (colorName == QStringLiteral("textFieldText"))       setColor(c, "#1D2A1F", "#808080", "#F2F5F3", "#6F7A72");
    else if (colorName == QStringLiteral("groupBorder"))         setColor(c, kFlynusGreen, "#C8CDC9", "#2C3530", "#2C3530");
    else if (colorName == QStringLiteral("mapButtonHighlight"))  setColor(c, kFlynusRed, "#585858", kFlynusAccent, "#585858");
    else if (colorName == QStringLiteral("mapIndicator"))        setColor(c, kFlynusRed, "#585858", kFlynusAccent, "#585858");
    else if (colorName == QStringLiteral("colorGreen"))          setColor(c, "#1E8E34", "#1E8E34", kFlynusAccent, kFlynusAccent);
    else if (colorName == QStringLiteral("colorRed"))            setColor(c, kFlynusRed, kFlynusRed, kFlynusRedLight, kFlynusRedLight);
    else if (colorName == QStringLiteral("missionItemEditor"))   setColor(c, "#E8EFE9", "#585858", "#1C221E", "#585858");
    else if (colorName == QStringLiteral("toolStripHoverColor")) setColor(c, "#C9D6CB", "#585858", "#2C3A2E", "#585858");
    else if (colorName == QStringLiteral("brandingPurple"))      setColor(c, kFlynusGreen, kFlynusGreen, kFlynusGreen, kFlynusGreen);
    else if (colorName == QStringLiteral("brandingBlue"))        setColor(c, kFlynusRed, kFlynusRed, kFlynusRed, kFlynusRed);
    else if (colorName == QStringLiteral("mapMissionTrajectory")) setColor(c, "#FFFFFF", "#FFFFFF", "#FFFFFF", "#FFFFFF");
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
