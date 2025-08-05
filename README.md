

# EyeSpeak Assist Mobile

This directory contains a simplified Flutter implementation of **EyeSpeak Assist** for Android and iOS. It provides a scanning on‑screen keyboard and uses blink detection to select keys.

The project depends on Google's ML Kit for blink detection and the platform text‑to‑speech engine.

## Building

1. Install Flutter (>=3.10) and the Android/iOS SDKs.
2. Run `flutter pub get` inside this `mobile` directory.
3. Connect a device or start an emulator.
4. Run `flutter run` to launch the app.

A release build can be generated with `flutter build apk` or `flutter build ios`.

## 🐧 Using a Samsung S25 Ultra for Testing (Linux / Pop!_OS)

> 💡 This guide avoids Android Studio and uses only the command-line tools for a lightweight setup.

### 🔹 Step 1: Enable USB Debugging on Your Phone
1. On your S25 Ultra, open **Settings → About phone → Software information**.
2. Tap **Build number** 7 times to unlock **Developer options**.
3. Go to **Settings → Developer options** and enable **USB debugging**.

---

### 🔹 Step 2: Install Flutter
```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

---

### 🔹 Step 3: Install Android Command-Line Tools
```bash
mkdir -p ~/Android/cmdline-tools
cd ~/Android
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip
unzip cmdline-tools.zip
mv cmdline-tools cmdline-tools-temp
mkdir -p cmdline-tools/latest
mv cmdline-tools-temp/* cmdline-tools/latest/
rmdir cmdline-tools-temp
```

---

### 🔹 Step 4: Configure Environment Variables
```bash
echo 'export ANDROID_HOME=$HOME/Android' >> ~/.zshrc
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.zshrc
echo 'export PATH=$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH' >> ~/.zshrc
source ~/.zshrc
```

---

### 🔹 Step 5: Install Java and Android SDK Packages
```bash
sudo apt install openjdk-17-jdk -y
sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-33" "build-tools;34.0.0"
flutter doctor --android-licenses
```

---

### 🔹 Step 6: Enable USB Access (Udev Rules)
```bash
sudo nano /etc/udev/rules.d/51-android.rules
```

Paste this line:
```
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
```

Then apply changes:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG plugdev $USER
newgrp plugdev
```

---

### 🔹 Step 7: Connect & Launch
1. Plug in your Samsung Galaxy S25 Ultra via USB.
2. Accept the **USB Debugging** prompt on the phone.
3. Run:
```bash
flutter devices
flutter run
```
You're all set 🚀

1. Enable developer options on the phone:
   - Open **Settings** → **About phone** → **Software information**.
   - Tap **Build number** seven times to unlock developer options.
2. Return to **Settings** → **Developer options** and enable **USB debugging**.
3. Install the Samsung USB drivers on your computer (or Android File Transfer on macOS).
4. Connect the phone to your computer with a USB cable and confirm the debugging prompt on the device.
5. Run `flutter devices` to verify that the S25 Ultra appears in the device list.
6. Execute `flutter run` from this directory to build and launch the app on the phone.

## Compliance Notes

- The camera feed is processed only for real‑time blink detection and is not stored.
- A camera usage description must be provided in the Android manifest and iOS `Info.plist` when publishing to the stores.
- Audio is generated using the native text‑to‑speech services (`FlutterTts`).

This mobile code is provided under the same **CC BY‑NC 4.0** license as the desktop version.
