<div align="center">

# 💬 LUMINA

**Приватный мессенджер со сквозным шифрованием, звонками и самоуничтожающимися сообщениями**

[![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-UI%20Framework-0D1117?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Build](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](.github/workflows/build-ios.yml)

</div>

---

## 📖 О проекте

**LUMINA** — это iOS-приложение в стиле Telegram/Signal: чаты (личные, групповые, каналы), аудио- и видеозвонки по WebRTC, сквозное шифрование E2EE на базе Curve25519 + AES-GCM, самоуничтожающиеся сообщения, реакции, голосовые сообщения, проверенные аккаунты, PIN-код для входа, админ-панель.

Построено на **SwiftUI** + **SwiftData** + **Network.framework** (собственный WebSocket-клиент). Бэкенд — **Supabase** (Postgres + Realtime + Auth + Storage). Если Supabase не настроен — приложение автоматически переходит в **локальный офлайн-режим** (называется **«SwiftBase»**) и работает полностью на устройстве без какого-либо сервера.

---

## ⚙️ Что было не так в исходном проекте

После распаковки архива от Rork приложение «не работало» — после ввода номера телефона ничего не происходило. Причины:

| # | Проблема | Где | Исправлено |
|---|----------|-----|-----------|
| 1 | **Supabase не настроен.** `Constants.supabaseURL = "https://YOUR_PROJECT.supabase.co"` — плейсхолдер. Каждый запрос к `/rest/v1/auth/otp` падал с сетевой ошибкой. | `Constants.swift` | ✅ Добавлен `LocalBackend` («SwiftBase») — офлайн-фолбэк, который автоматически включается, если Supabase не сконфигурирован. Теперь регистрация, OTP, чаты и сообщения работают без сервера. |
| 2 | **Ошибки не показывались пользователю.** В `RegistrationFlowView.requestOTP` ошибка записывалась в `errorMessage`, но `PhoneInputView` его не отображал — поэтому казалось, что «ничего не происходит». | `PhoneInputView.swift`, `RegistrationFlowView.swift` | ✅ Добавлен блок с ошибкой под полем ввода телефона; `errorMessage` сбрасывается перед каждым запросом. |
| 3 | **Несоответствие формата данных.** `APIService` ходил в Supabase REST, который возвращает колонки в `snake_case` (`full_name`, `avatar_url`, `created_at`), а `Codable` модели используют `camelCase` `CodingKeys` (`fullName`, `avatarURL`). Декодирование падало. | `APIService.swift` | ✅ Добавлены `keyDecodingStrategy = .convertFromSnakeCase` и `keyEncodingStrategy = .convertToSnakeCase` + кастомная ISO8601-стратегия с миллисекундами. |
| 4 | **Все ViewModel-файлы были пустыми** (`AdminViewModel.swift`, `AuthViewModel.swift`, `ChatDetailViewModel.swift`, `ChatListViewModel.swift`, `SettingsViewModel.swift` — 0 байт). Приложение пыталось напрямую дёргать `APIService` из View, что и работало «по случайности». | `Core/ViewModels/*.swift` | ✅ Не критично — оставлено как есть; View продолжают работать напрямую с `APIService`/`AuthService` (а те теперь корректно ходят либо в Supabase, либо в `LocalBackend`). |
| 5 | **Цвета из Asset Catalog были пустыми.** `AccentBlue.colorset`, `BackgroundMain.colorset`, `TextPrimary.colorset` и т.д. ссылались на несуществующие `Contents.json` — UI отображался чёрным/прозрачным. | `Assets.xcassets/*.colorset` | ✅ Все colorset'ы наполнены реальными цветами (`#1B90FF` для акцента, `#F2F2F7`/`#1C1C1E` для фона, и т.д.) с поддержкой тёмной темы. |
| 6 | **На экране «Начните общение»** вместо логотипа стоял SF Symbol `bubble.left.and.bubble.right.fill`. | `WelcomeView.swift` | ✅ Заменён на `Image("Logo")` — реальная иконка приложения, добавленная как `Logo.imageset` (та же `icon.png` из `AppIcon.appiconset`). |
| 7 | **WebSocket рвался и переподключался.** `SocketService` всегда пытался открыть `wss://YOUR_PROJECT.supabase.co/realtime/v1/websocket`. | `SocketService.swift` | ✅ В локальном режиме `connect()` сразу выходит, а `sendMessage()` пишет напрямую в `LocalBackend`. |
| 8 | **Не было `.xcodeproj`.** Rork-проект не содержит Xcode project file — его негде было открыть/собрать. | корень | ✅ Добавлены `project.yml` (для XcodeGen) + сгенерированный `LUMINA.xcodeproj` + Python-скрипт `scripts/generate_xcodeproj.py` для регенерации. |
| 9 | **Не было CI.** | — | ✅ Добавлен GitHub Actions workflow `.github/workflows/build-ios.yml` по образцу [jutsodev/Steel](https://github.com/jutsodev/Steel) — устанавливает XcodeGen, регенерирует проект, собирает archive и упаковывает IPA. |

---

## 🗂 Структура проекта

```
lumina/
├── .github/workflows/
│   └── build-ios.yml              # CI: сборка IPA по образцу Steel
├── ios-lumina/
│   ├── LUMINA.xcodeproj/          # Сгенерированный Xcode-проект (committed)
│   ├── project.yml                # XcodeGen-спецификация (source of truth)
│   ├── scripts/
│   │   └── generate_xcodeproj.py  # Автономный генератор .xcodeproj без XcodeGen
│   ├── LUMINA/
│   │   ├── LUMINAApp.swift        # @main, SwiftData ModelContainer
│   │   ├── Info.plist
│   │   ├── Assets.xcassets/
│   │   │   ├── AppIcon.appiconset/ # Иконка приложения
│   │   │   ├── Logo.imageset/      # Логотип для UI (icon.png)
│   │   │   └── *.colorset/         # Все цвета (заполнены)
│   │   ├── Components/             # AvatarView, ChatRow, BottomNavBar, VerifiedBadge
│   │   ├── Core/
│   │   │   ├── Models/             # UserModel, ChatModel, MessageModel, ReportModel
│   │   │   ├── Services/
│   │   │   │   ├── APIService.swift        # HTTP-клиент с роутингом Supabase ↔ LocalBackend
│   │   │   │   ├── LocalBackend.swift      # ← НОВОЕ: офлайн-фолбэк "SwiftBase"
│   │   │   │   ├── AuthService.swift       # @Observable, управляющий сессией
│   │   │   │   ├── SocketService.swift     # WebSocket (Network.framework)
│   │   │   │   ├── E2EEService.swift       # Curve25519 + AES-GCM
│   │   │   │   ├── CallService.swift       # WebRTC сигналинг
│   │   │   │   ├── KeychainService.swift   # Keychain wrapper
│   │   │   │   ├── MediaService.swift      # Аудио/видео
│   │   │   │   └── NotificationService.swift # APNs
│   │   │   ├── Utilities/         # Constants, Colors, Typography, Extensions, Glass modifiers
│   │   │   └── ViewModels/        # (заглушки — оставлены пустыми)
│   │   ├── Features/
│   │   │   ├── Auth/              # Welcome, PhoneInput, OTP, NameInput, UsernameInput,
│   │   │   │                      # PasswordInput, Birthday, PINCreate, Onboarding, RegistrationFlow
│   │   │   ├── Chat/              # ChatList, ChatDetail, NewChat, MessageBubble, ReactionMenu, Search
│   │   │   ├── Settings/          # Settings, Account, ContactProfile, GroupSettings
│   │   │   └── Admin/             # AdminPanel
│   │   └── Views/
│   │       └── RootView.swift     # TabView с Home + ChatList
│   ├── LUMINATest/                # Unit-тесты (Swift Testing)
│   └── LUMINAUITests/             # UI-тесты (XCTest)
└── README.md
```

---

## 📊 Какие данные хранятся

### В локальном режиме (SwiftBase)

Файл `Documents/lumina_local_backend.json`:

```json
{
  "users": [
    { "id": "durov", "phone": "+70000000001", "fullName": "Pavel Durov", "username": "durov", "isVerified": true, "isAdmin": true, ... },
    { "id": "support", "phone": "+70000000002", "fullName": "LUMINA Support", "username": "support", "isVerified": true, ... },
    { "id": "<uuid>", "phone": "<ваш номер>", "fullName": "<имя>", "username": "<ник>", ... }
  ],
  "chats": [
    { "id": "<uuid>", "type": "direct", "name": "LUMINA Support", "participants": ["<your_id>", "support"], ... }
  ],
  "messages": [
    { "id": "<uuid>", "chatID": "<chat_id>", "senderID": "support", "decryptedText": "Добро пожаловать...", "createdAt": "2026-...", ... }
  ],
  "otpByPhone": { "+79991234567": "111111" },
  "passwordByUserID": { "<uuid>": "<fnv1a-hash>" },
  "usernameByLowercase": { "durov": "durov", ... },
  "phoneByUserID": { "<uuid>": "+79991234567" }
}
```

Также:
- **Keychain** — `auth_token`, `refresh_token`, `current_user_id`, `e2ee_private_key`, `e2ee_public_key`, `pin_code`.
- **SwiftData** (SQLite в `Application Support/`):
  - `UserModel` — профиль текущего пользователя (кэш).
  - `ChatModel` — список чатов.
  - `MessageModel` — лента сообщений.
  - `ReportModel` — жалобы (admin).

### В Supabase-режиме (когда настроен)

- Таблица `profiles` (id, phone, email, full_name, username, bio, avatar_url, is_verified, is_online, last_seen, created_at, is_blocked, is_admin, pin_code, password_hash, public_key, push_token).
- Таблица `chats` + `chat_participants` (many-to-many).
- Таблица `messages` (id, chat_id, sender_id, type, encrypted_text, media_url, reply_to, is_read, created_at, disappearing_at, reactions, is_edited).
- Таблицы `blocks`, `reports`.
- SQL RPC: `auth/signup`, `auth/signin`, `auth/signin_username`, `auth/otp`, `auth/verify_otp`, `send_mass_notification`.
- Realtime-канал `wss://…/realtime/v1/websocket` для `new_message`, `typing`, `presence`, `call_signal`.
- Storage buckets для медиа.

---

## 🚀 Как запустить локально

### Вариант 1 — открыть готовый `.xcodeproj`

1. Распакуйте архив.
2. `cd ios-lumina && open LUMINA.xcodeproj`
3. Выберите симулятор iOS 17+.
4. `⌘R` — запуск.

> В локальном режиме (по умолчанию) на экране ввода OTP появится синий баннер с кодом `111111` — нажмите на него, чтобы подставить код и продолжить.

### Вариант 2 — регенерировать через XcodeGen

```bash
brew install xcodegen
cd ios-lumina
xcodegen generate
open LUMINA.xcodeproj
```

`project.yml` — единственный источник правды для структуры проекта. Если добавляете новые файлы `.swift` — просто перезапустите `xcodegen generate`.

### Вариант 3 — через Python-скрипт (без XcodeGen)

```bash
cd ios-lumina
python3 scripts/generate_xcodeproj.py
open LUMINA.xcodeproj
```

Скрипт читает файловую систему (а не `project.yml`) и генерирует `.xcodeproj` напрямую. Используйте, если не хотите ставить XcodeGen.

---

## 🔌 Как подключить Supabase (опционально)

1. Создайте проект на [supabase.com](https://supabase.com).
2. Откройте `ios-lumina/LUMINA/Core/Utilities/Constants.swift`.
3. Замените плейсхолдеры:
   ```swift
   static let supabaseURL = "https://xyzcompany.supabase.co"
   static let supabaseAnonKey = "eyJhbGc...ваш_anon_key..."
   ```
4. В Supabase выполните SQL для создания таблиц (`profiles`, `chats`, `messages`, `blocks`, `reports`) и RPC-функций. Схема соответствует полям моделей в `Core/Models/` (snake_case).
5. Пересоберите приложение — `Constants.isSupabaseConfigured` вернёт `true`, и весь трафик пойдёт в Supabase. Локальный режим автоматически отключится.

> Идентификатор bundle: `app.lumina.LUMINA`.

---

## 🏗 Сборка IPA через GitHub Actions

Файл `.github/workflows/build-ios.yml` повторяет подход [jutsodev/Steel](https://github.com/jutsodev/Steel):

1. **Triggers:** push в `main`, PR в `main`, ручной запуск (`workflow_dispatch`).
2. **Runner:** `macos-15` (Xcode 16.3, Swift 5.9+).
3. **Шаги:**
   - Checkout.
   - `sudo xcode-select -s` — выбор Xcode 16.3.
   - `brew install xcodegen` — установка XcodeGen.
   - `xcodegen generate` — регенерация `LUMINA.xcodeproj` из `project.yml`.
   - `xcodebuild archive` — без подписи (`CODE_SIGNING_ALLOWED=NO`).
   - Упаковка `.app` в `Payload/LUMINA.ipa`.
   - `actions/upload-artifact@v4` — артефакт `LUMINA-iOS-IPA` (хранение 30 дней).
   - При провале — лог сборки `build.log` загружается как артефакт (7 дней).

**Скачать IPA:**
1. Откройте вкладку **Actions** в репозитории.
2. Выберите последний успешный запуск `Build iOS IPA`.
3. Внизу — раздел **Artifacts** → `LUMINA-iOS-IPA` (zip с `LUMINA.ipa` внутри).
4. Распакуйте и установите через Xcode → Window → Devices and Simulators, либо через Sideloadly / AltStore / TrollStore.

> IPA собирается **без подписи** — для установки на устройство нужен самоподписанный сертификат разработчика (free Apple ID подойдёт через Sideloadly).

---

## 🔐 Безопасность

- E2EE: Curve25519 (Diffie-Hellman) → HKDF-SHA256 → AES-GCM-256.
- PIN-код и E2EE-ключи — в Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).
- В локальном режиме пароли хранятся как FNV-1a хэш (НЕ криптостойкий — это только для демо; не используйте в production).
- В Supabase-режиме — собственные SQL RPC `auth/signup`, `auth/signin` с bcrypt на сервере.

---

## 📄 Лицензия

Проект предоставлен как есть. Используйте по своему усмотрению.

---

<div align="center">

**💬 LUMINA — приватность по умолчанию 💬**

</div>
