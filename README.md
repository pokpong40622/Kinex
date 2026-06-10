# kinex_app

Flutter front-end for **Kinex**. The app embeds the Unity **MEGA DANCE** game
(pose-tracked dancing) via the [`flutter_embed_unity`](https://pub.dev/packages/flutter_embed_unity)
package.

## ⚠️ A fresh clone will NOT build for Android out of the box

The embedded Unity content lives in `android/unityLibrary/`, which is a
**multi-GB generated artifact** (with individual files >100 MB that GitHub
rejects). It is therefore **gitignored** and is **not** included in a clone.
You must regenerate it from the companion Unity project before any Android
build, or the build will fail.

## Building for Android

This app embeds Unity via `flutter_embed_unity`. The embedded Unity player
lives in `android/unityLibrary/` (gitignored) and is exported from the
companion Unity project.

**Companion Unity project:** `KinexUnity`
(github.com/pokpong40622/KinexUnity), locally at `D:\Unity project\Kinex`.

### Regenerate `android/unityLibrary/` before building

1. Open the Unity project (Unity **6000.4.0f1**).
2. Make sure the build scene is `Assets/Scenes/MegaDanceScene.unity`
   (File → Build Settings — it may already be set).
3. Run the menu item **Kinex → Spike Export Android (ARM64)**. This exports the
   Unity player into `D:\kinex_app\android\unityLibrary`.
4. Back in the Flutter app:
   ```
   flutter pub get
   flutter build apk --debug      # or: flutter run -d <device>
   ```

### Constraints

- **ARM64 only.** Unity 6 cannot build x86_64 Android, so x86_64 emulators
  will not work. Use a real ARM64 device or an `arm64-v8a` emulator.
- Android **minSdk is 25**.
- The app requests **camera permission**, used for MediaPipe pose tracking
  inside Unity.
