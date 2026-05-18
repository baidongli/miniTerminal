# 上架发布指南（Google Play + App Store）

App 唯一标识（永久）：`com.baidongli.miniterminal`
版本：由 `pubspec.yaml` 的 `version:` 决定 versionName；versionCode /
iOS build number 由 CI 的 run number 自动递增（Play 要求每次上传递增）。

---

## A. Google Play（你已有 Console 账号）

### 一次性：生成上传密钥（在任意有 JDK 的电脑上做一次，妥善保存）

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

记住你设置的 **store 密码、key 别名（upload）、key 密码**。
`upload-keystore.jks` 丢了会无法更新已上架 App，务必备份。

### 一次性：在 GitHub 仓库加 4 个 Secrets

仓库 → Settings → Secrets and variables → Actions → New secret：

| Secret 名 | 值 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` 的输出 |
| `ANDROID_KEYSTORE_PASSWORD` | store 密码 |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | key 密码 |

> 生成 base64：`base64 -w0 upload-keystore.jks`（mac 用
> `base64 -i upload-keystore.jks | tr -d '\n'`），整段粘进 secret。

加好后，下一次推 `main`，CI 会自动构建**已签名 AAB**。

### 每次发布

1. 等 CI 绿 → 进那次 run → Artifacts 下载 `miniterminal-build`，
   里面有 `miniterminal.aab`。
2. Play Console → 你的应用 → 测试或正式 → 创建版本 → 上传
   `miniterminal.aab`。
3. 首次需补全：应用名称、简介、隐私政策链接、截图、分级问卷、
   数据安全表单。建议先发**内部测试**轨道验证安装。
4. Play 默认开启「应用签名」：上传密钥用于上传，Google 持有
   最终签名密钥，正常流程，无需额外操作。

### 没配 Secrets 时

CI 跳过 AAB，只产出可旁加载的 `miniterminal.apk`（现状），
完全不影响。配了才多出 AAB。

---

## B. Apple App Store（暂无账号，先就绪）

### 现状

- 包标识、版本号、图标已按上架要求配好。
- CI 的 iOS job 目前只做 **release 编译检查（不签名）**，
  因为签名/上传必须有 Apple Developer 账号。
- App Store 不接受未签名安装，**没有 $99/年 Apple Developer
  Program 无法上架**（这是 Apple 的硬性要求，非本项目限制）。

### 注册账号后要做的（届时我来接好流水线）

1. 加入 Apple Developer Program（$99/年）。
2. App Store Connect 创建 App，bundle id 填
   `com.baidongli.miniterminal`。
3. 生成并提供这些 GitHub Secrets（我会据此加签名归档+上传 job）：
   - `APPSTORE_API_KEY_ID` / `APPSTORE_API_ISSUER_ID` /
     `APPSTORE_API_PRIVATE_KEY`（App Store Connect API Key，用于
     fastlane 上传，最省事）
   - 分发证书与描述文件（或用 fastlane match 管理）
4. 通知我「Apple 账号好了」，我把 iOS job 从「编译检查」升级为
   「签名归档 → 上传 TestFlight/App Store」，同样缺密钥自动跳过。

---

## 注意

- 上传密钥 / Apple 证书属高敏资料：只放 GitHub Secrets，
  绝不提交进仓库。
- `applicationId` / bundle id 一经上架不可改，已锁定
  `com.baidongli.miniterminal`。
- 每次上架版本号要递增：改 `pubspec.yaml` 的 `version:`
  （如 `1.0.0+1` → `1.0.1+1`），CI 会用 run number 作 build 号。
