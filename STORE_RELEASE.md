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

### 自动上传到 Play 内部测试轨道（可选）

配好上面 4 个签名 Secrets 后，每次推 main 会产出签名 AAB（在
Artifacts 里）。若想让 CI **自动上传**到 Play「内部测试」轨道，
再加一个 Secret 并满足两个前提：

前提：
1. 应用已在 Play Console 创建（包名 `com.baidongli.miniterminal`），
   且**首个版本必须先手动上传一次**（Google 要求首发手动）。
2. 建一个有权限的服务账号：
   - Google Cloud Console → 该项目 → IAM & Admin → Service
     Accounts → 新建 → 下载 JSON 密钥。
   - 启用 **Google Play Android Developer API**。
   - Play Console → Users & permissions → 邀请该服务账号邮箱，
     给「发布到测试轨道」权限。

然后加 Secret：

| Secret 名 | 值 |
|---|---|
| `PLAY_SERVICE_ACCOUNT_JSON` | 服务账号 JSON 文件的**完整内容** |

之后推 main：CI 自动把签名 AAB 传到 internal 轨道，Play Console
里测试者即可更新。缺这个 Secret 时只产出 AAB 不自动上传。

### 没配 Secrets 时

CI 跳过 AAB，只产出可旁加载的 `miniterminal.apk`（现状），
完全不影响。配了才多出 AAB。

### 把 App 发给别人测（最简单）

不想上 Play 也行：直接把 GitHub release 的
`miniterminal.apk` 链接发给对方，安卓手机允许「安装未知来源」
即可装。零成本。

---

## B. iOS TestFlight / App Store（需 $99/年账号）

给别人用 iOS **必须**有 Apple Developer Program（$99/年）。免费个人
签名只能装你自己的设备、7 天，无法分发。有账号后，**TestFlight**
是给别人测的最佳方式（邮箱/公开链接邀请最多 1 万人，审核很轻）。

### 现状

- 包标识、版本号、图标、显示名都已按上架要求配好。
- CI 的 iOS job 目前只做 **release 编译检查（不签名）**。
- 没有 $99 账号无法签名/上传——Apple 硬性要求。

### 注册账号后的步骤（届时我来接 CI，并用你的真凭证一起调试）

1. 加入 Apple Developer Program（$99/年），等审核通过。
2. App Store Connect → 我的 App → 新建 App，bundle id 选
   `com.baidongli.miniterminal`，填名称 MiniTerminal。
3. 生成 **App Store Connect API Key**（Users and Access → Integrations
   → App Store Connect API → 生成，下载 `.p8`，记下 Key ID 和
   Issuer ID）。
4. 加这些 GitHub Secrets：

   | Secret 名 | 值 |
   |---|---|
   | `APPSTORE_API_KEY_ID` | API Key 的 Key ID |
   | `APPSTORE_API_ISSUER_ID` | Issuer ID |
   | `APPSTORE_API_PRIVATE_KEY` | `.p8` 文件的完整内容 |

5. 通知我「Apple 账号好了 + Secrets 配好了」，我把 iOS job 升级为
   「自动签名归档 → 上传 TestFlight」（用 Xcode 自动签名 +
   `xcrun altool`/fastlane，缺 Secret 自动跳过）。
6. TestFlight 里邀请测试者（邮箱或公开链接），他们装
   TestFlight App 即可安装你的 App。

> 为什么现在不先把 CI 写好：iOS 签名/上传链路必须用真证书+真账号
> 才能验证，盲配极易出错。等你账号就绪，我和你一起一次配通。

---

## 注意

- 上传密钥 / Apple 证书属高敏资料：只放 GitHub Secrets，
  绝不提交进仓库。
- `applicationId` / bundle id 一经上架不可改，已锁定
  `com.baidongli.miniterminal`。
- 每次上架版本号要递增：改 `pubspec.yaml` 的 `version:`
  （如 `1.0.0+1` → `1.0.1+1`），CI 会用 run number 作 build 号。
