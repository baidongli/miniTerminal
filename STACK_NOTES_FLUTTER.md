# 技术栈专属坑：Flutter（Android + iOS）

> 配合 `DEVELOPMENT_PLAYBOOK.md` 看。这里是做 Flutter app 时真实
> 踩过的坑 + 确切修法，下个 Flutter 项目开工前过一遍。

---

## 工程脚手架

- `android/` `ios/` **不提交**，CI 里 `flutter create` 现生成。
  设包名用 `flutter create --org com.x --project-name app .`
  → applicationId / iOS bundle id = `com.x.app`（**上架后不可改**，
  开工就定）。
- 需要的原生改动在 CI 用脚本 patch `flutter create` 的产物，
  并 `cat` 出来核对。复杂改动用 Python 脚本，比 `sed` 稳，且写成
  **找不到锚点就不动文件**，避免污染已跑通的流水线。

## debug vs release（最高频回归源）

- **INTERNET 权限**：Flutter 只在 debug/profile 的 manifest 自动
  注入 `android.permission.INTERNET`；**release 主 manifest 没有**
  → 一切网络报 `OS Error: Operation not permitted, errno = 1`。
  修：CI 往 `android/app/src/main/AndroidManifest.xml` 显式加。
- **签名差异**：Flutter app 模板默认 release 用 debug key 签
  （`flutter build apk --release` 开箱可装，便于旁加载）；但
  **Google Play 必须用专用上传密钥签 AAB**，不能用 debug key。
- 切 debug↔release 或换密钥 → 签名变 → 用户必须**先卸载旧包**，
  本地数据丢失，提前告知。

## NDK：纯 Dart/Kotlin app 不需要它

- Flutter 3.44 `flutter create` 在 `android/app/build.gradle.kts`
  写死 `ndkVersion = flutter.ndkVersion`，逼 Gradle 解析/下载 NDK，
  即使项目无 C/C++ 代码。网络不稳时下成损坏包
  （`Archive is not a ZIP archive` / `did not have a
  source.properties` / `CXX1101`），反复重试卡死。
- 修：`flutter create` 后删掉该行
  （`sed -i '/^\s*ndkVersion\s*=/d'`），AGP 就不再碰 NDK。
  已加进 `tool/setup_local.sh` 和 CI workflow。
- 若曾下过损坏 NDK：`rm -rf $ANDROID_HOME/ndk/<ver>` 清掉。

## compileSdk 冲突

- 传递插件（如 `file_picker` → `flutter_plugin_android_lifecycle`）
  可能要求 `compileSdk ≥ 36`，而插件模块默认编译在 34 →
  `Dependency ... requires ... version 36 ... is currently compiled
  against android-34`。
- 修：项目级 `android/build.gradle.kts` 追加，对所有 Android
  子模块强制 compileSdk：
  ```kotlin
  subprojects { afterEvaluate {
      extensions.findByName("android")?.withGroovyBuilder {
          "compileSdkVersion"(36) } } }
  ```
  比逐个升插件版本稳。已加进 setup_local.sh + CI
  （`tool/patch_android_compilesdk.py`）。
- **坑**：该 `subprojects { afterEvaluate {} }` 必须**插在** Flutter
  root `build.gradle.kts` 的 `subprojects { evaluationDependsOn(
  ":app") }` **之前**——后者会提前评估子项目，注册晚了报
  `Cannot run Project.afterEvaluate when the project is already
  evaluated`。脚本按"插到第一个 subprojects 块前"实现。
- 瞬时网络抖动（`Could not resolve ... aaptcompiler` /
  `handshake`）Gradle 会自动 retry，多数能自恢复，别误判为终错。

## 包体积

- debug APK 可达 ~150MB；`flutter build apk --release
  --split-per-abi` 取 `app-arm64-v8a-release.apk` 降到 ~20MB。
- 上 Play 用 `flutter build appbundle --release`（AAB）。

## 上架

- **versionCode 必须递增**：CI 用 `--build-number=${{ github.run_number }}`。
- **iOS 上架硬门槛**：必须有 Apple Developer Program（$99/年），
  未签名包 App Store 不收。没账号前 CI 只能 `flutter build ios
  --release --no-codesign` 做编译检查。
- 密钥/证书只进 GitHub Secrets，**绝不提交仓库**；CI 步骤用
  `if: ${{ env.X != '' }}` 门控，缺密钥自动跳过、不阻断主流水线。

## 插件 / 原生配置

- `local_auth`（生物识别）：Android 需把 `MainActivity` 改成
  `FlutterFragmentActivity`，并加 `USE_BIOMETRIC` 权限，否则运行
  时解锁失败（编译不报错，易漏）。
- 加原生依赖的插件（file_picker / path_provider / secure_storage
  等）：编译过不代表运行过，真机逐个验证。

## iOS 真机调试（免费 Apple ID，无需 $99）

1. 装 CocoaPods：`pod --version`，没有则 `sudo gem install cocoapods`。
2. iPhone 首次需开**开发者模式**（iOS 16+）：设置 → 隐私与安全性 →
   开发者模式 → 开 → 重启。
3. Xcode → Settings → Accounts 加 Apple ID（免费）。
4. `open ios/Runner.xcworkspace` → Runner target → Signing &
   Capabilities → 勾 Automatically manage signing → Team 选
   (Personal Team)。bundle id 冲突就改唯一值。
5. `flutter run` 选真机；首次在 iPhone 设置 → 通用 →
   VPN与设备管理里**信任**开发者证书。
6. 免费签名有效期 **7 天**，到期重新 `flutter run`。
7. `pod install`（flutter run 自动触发）走 GitHub/CDN，网络差时开 VPN。
8. **Module 'X' not found**（如 flutter_secure_storage）：Flutter 默认
   开了 Swift Package Manager，而该插件只支持 CocoaPods，SPM+Pods
   混用就报找不到模块。修：`flutter config
   --no-enable-swift-package-manager` → `flutter clean` →
   重建。已加进 setup_local.sh。另：Xcode 必须开
   `Runner.xcworkspace`（非 `.xcodeproj`），否则也报 module not found。

## Dart / API 细节（无编译器时先查 pub.dev 再写）

- 自定义类名会和库导出撞名（本项目 `TerminalThemes` 撞 `xterm`）
  → 一律加 `App` 前缀。
- `dart:typed_data` 的 `BytesBuilder` 没有 `addAll`；用
  `add(List<int>)` / `addByte(int)`。
- `const` 只能用于真有 const 构造的类（如三方异常类常没有）。
- 不确定的回调签名先查文档：本项目 `dartssh2` 的
  `onVerifyHostKey` 是 `FutureOr<bool> Function(String, Uint8List)`，
  查证后才接进握手，避免又一轮红叉。

## 移动端体验

- 终端/编辑类视图设 `padding: EdgeInsets.zero` 收回边距宽度。
- 长内容挤占输入（如服务器超长 PS1 主机名）→ 给开关/引导，
  别试图在客户端重写远端输出（裸流，hacky 不可靠）。

## CI 形态（本项目实证可用）

- `subosito/flutter-action@v2`（channel: stable, cache: true）
  + `actions/setup-java@v4`（temurin 17）。
- 首次构建慢（工具链+Gradle 冷缓存 10–15 min），别误判为卡死。
- iOS job 用 `runs-on: macos-latest` + `continue-on-error: true`，
  不阻断 Android 产出。
- 产物发滚动 pre-release（tag 如 `android-latest`）+ workflow
  artifact 双保险。

## 本地开发（macOS / zsh）

- 给用户的命令**别带行内 `# 注释`**：zsh 交互模式默认不把 `#`
  当注释（`interactive_comments` 关闭），整行粘贴会把 `#...`
  当参数传进去，如 `flutter run # ...` → `Target file "#" not
  found.`。命令与说明分行写。
- `tool/setup_local.sh` 复刻 CI 全部 patch，保证本地/CI 不漂移。
- **关键坑**：`flutter create` **不覆盖已存在的** `android/` 文件，
  上次生成的（含已注入补丁的）文件会残留，二次 patch 因幂等标记
  跳过 → 旧坏块原地不动，本地与 CI 漂移。所以 setup_local.sh 在
  `flutter create` 前 `rm -rf android ios` 干净重建，对齐 CI 的
  全新检出。
