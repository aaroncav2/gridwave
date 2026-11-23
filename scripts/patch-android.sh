#!/usr/bin/env bash
set -euo pipefail
sed -i "s/minSdkVersion = [0-9]*/minSdkVersion = 24/" android/variables.gradle
APP_ID=$(node -p "require('./www/admob.config.json').appId")
MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q "gms.ads.APPLICATION_ID" "$MANIFEST"; then
  sed -i "s#</application>#    <meta-data android:name=\"com.google.android.gms.ads.APPLICATION_ID\" android:value=\"$APP_ID\"/>\n    </application>#" "$MANIFEST"
fi
# microphone permission (the "Record Mic" button in Effects Processing)
if ! grep -q "RECORD_AUDIO" "$MANIFEST"; then
  sed -i "s#<application#<uses-permission android:name=\"android.permission.RECORD_AUDIO\" />\n    <uses-permission android:name=\"android.permission.MODIFY_AUDIO_SETTINGS\" />\n    <application#" "$MANIFEST"
fi
# GridWave launcher icons + launch background (replaces the default Capacitor ones)
if [ -d resources/res ]; then
  cp -R resources/res/. android/app/src/main/res/
  sed -i "s/#FFFFFF/#0F766E/" android/app/src/main/res/values/ic_launcher_background.xml
fi
# version (Play requires versionCode to increase each upload)
VC=${VERSION_CODE:-1}
sed -i "s/versionCode [0-9]*/versionCode $VC/" android/app/build.gradle
sed -i "s/versionName \"[^\"]*\"/versionName \"1.1.$VC\"/" android/app/build.gradle
# release signing from env (only if keystore provided)
if [ -n "${KEYSTORE_PATH:-}" ]; then
cat >> android/app/build.gradle <<GRADLE

android {
    signingConfigs {
        release {
            storeFile file("$KEYSTORE_PATH")
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes { release { signingConfig signingConfigs.release } }
}
GRADLE
fi
echo "Patched Android project (AdMob app id: $APP_ID, versionCode: $VC)"
