# 上架提交清单（Google Play + App Store）

照这份从上到下走即可。文案取自 `STORE_LISTING.md`,签名/密钥步骤
见 `STORE_RELEASE.md`,隐私政策用 `PRIVACY_POLICY.md` /
`PRIVACY_POLICY_zh.md` 的 GitHub 链接。

App 标识(永久):`com.baidongli.miniterminal`

---

## 0. 通用素材(两个商店都要,先备齐)

- [ ] **App 图标**:1024×1024 PNG(商店用)。仓库已有
      `assets/icon/icon.png`;App Store 需无 alpha,构建已自动处理。
- [ ] **截图**:用真机/模拟器截这几屏 —— 主机列表、终端会话、
      SFTP 浏览、密钥管理、关于页。
      - Play:手机至少 2 张。
      - App Store:至少 6.7" iPhone 一组;有 iPad 再加一组。
- [ ] **隐私政策 URL**:
      `https://github.com/baidongli/miniterminal/blob/main/PRIVACY_POLICY.md`
- [ ] **演示 SSH 服务器**(host / 用户名 / 密码)—— 填到审核备注,
      供审核员测试连接(否则会被拒)。
- [ ] **分类**:开发者工具 / 实用工具。

---

## A. Google Play

### A1. 账号
- [ ] 完成开发者账号身份验证(证件 + 手机号,需几天审核)。

### A2. 创建应用
- [ ] Play Console → 创建应用:名称 `MiniTerminal`、应用、免费。

### A3. 签名(出 AAB)
- [ ] 按 `STORE_RELEASE.md` 生成 `upload-keystore.jks`(**备份!**)。
- [ ] GitHub 仓库加 4 个 Secret(KEYSTORE_BASE64 / 密码 / 别名 /
      key 密码)。
- [ ] 推一次 `main` → CI 产出签名 AAB(在 run 的 Artifacts 里)。

### A4. 商店信息(文案见 STORE_LISTING.md)
- [ ] 应用名称、简短说明、完整说明、关键词。
- [ ] 图标、截图、(可选)宣传图 1024×500。
- [ ] 隐私政策 URL。

### A5. 应用内容(政策表单)
- [ ] 数据安全:勾 **不收集/不分享数据**。
- [ ] 内容分级问卷。
- [ ] 目标受众(非儿童)、广告(无)。

### A6. 发布
- [ ] 先开 **内部测试** 轨道 → 上传 AAB → 加测试者邮箱 → 发布。
- [ ] (个人新账号)按 Google 要求做 **封闭测试:≥12 名测试者、
      持续 14 天**,之后才能申请正式发布。
- [ ] 可选:配 `PLAY_SERVICE_ACCOUNT_JSON` Secret → 之后 CI 自动
      上传内部轨道(首个版本仍需手动传一次)。

---

## B. App Store / TestFlight

### B1. 账号
- [ ] 加入 Apple Developer Program($99/年,个人即可)。

### B2. 创建 App
- [ ] App Store Connect → 我的 App → 新建:bundle id
      `com.baidongli.miniterminal`,名称 MiniTerminal。

### B3. 上传构建包(二选一)
- [ ] **手动**:本地 `flutter build ipa` → 用 Xcode Organizer 或
      Transporter 上传。
- [ ] **CI 自动**:生成 App Store Connect API Key → 加 3 个 Secret
      (`APPSTORE_API_KEY_ID` / `APPSTORE_API_ISSUER_ID` /
      `APPSTORE_API_PRIVATE_KEY`)→ 通知我接 CI 自动传 TestFlight。

### B4. TestFlight(给别人测,最快)
- [ ] 构建包处理完后出现在 TestFlight。
- [ ] 内部测试者(无需审核)或外部测试者(轻量审核)→ 邮箱或
      公开链接邀请。

### B5. 正式上架(可选,审核更严)
- [ ] 填:截图、说明、关键词、支持 URL、隐私政策 URL。
- [ ] App 隐私:勾 **不收集数据**。
- [ ] 加密合规:已设 `ITSAppUsesNonExemptEncryption=false`,无需额外
      操作。
- [ ] 审核备注:放演示 SSH 服务器凭据。
- [ ] 提交审核。

---

## 字段 → 文案来源 速查

| 要填的字段 | 取自 |
|---|---|
| 名称 / 副标题 / 关键词 / 描述 | `STORE_LISTING.md` |
| 隐私政策 URL | `PRIVACY_POLICY.md`(中文 `PRIVACY_POLICY_zh.md`) |
| 签名密钥 / Secrets | `STORE_RELEASE.md` |
| 包标识 | `com.baidongli.miniterminal` |
| 数据收集 | 不收集(全本地 + Keychain) |
