# Murmur

Flutter-приложение для успокоения, сна и работы с эмоциональным состоянием:
библиотека звуков, дыхательные практики, трекер настроения.

Только iOS и Android. Рабочие заметки, план и принятые решения — в `claude/project.md`
(файл локальный, в репозиторий не пушится).

## Сборка

```bash
flutter pub get
flutter analyze
flutter build apk --debug
```

Секреты в репозитории не лежат. При клонировании на другую машину надо руками принести:

- `android/local.properties` — пароли keystore
- `android/app/release/my-stuff.jks` — сам ключ подписи

## Подпись Android-сборки

1. Положить `.jks` в локальную папку, куда достанет Flutter.
2. Заполнить `android/local.properties` по образцу:

```
android.sign.keyfile=/путь/до/android/sign/my-stuff.jks
android.sign.keyalias=my-stuff
android.sign.storepass=СуперПарольНикомуНеСкажу
```

Детали сертификата (например, для Firebase) — командой вида:

```
keytool -list -v -alias my-stuff -keystore /путь/до/my-stuff.jks
```

## Отпечатки текущего keystore

SHA-1 нужен для Google Sign-In при заведении нового Firebase-проекта.

```
Alias name: my-stuff
Creation date: Oct 20, 2024
Entry type: PrivateKeyEntry
Owner: CN=Igor, OU=Dev, O=MyStuff, L=Dubai, ST=Dubai, C=AE
Valid from: Sun Oct 20 15:19:31 IRKT 2024 until: Thu Mar 07 15:19:31 IRKT 2052
SHA1:   E2:06:37:31:13:1D:52:BA:0B:5D:12:9B:4B:5E:60:EF:90:78:0C:CF
SHA256: FA:27:32:92:45:89:46:12:C7:24:1C:4D:74:88:3D:57:BA:BC:AD:F1:7D:33:4E:0C:31:43:E4:11:77:54:3B:DF
Signature algorithm: SHA384withRSA · 2048-bit RSA
```
