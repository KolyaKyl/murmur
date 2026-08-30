# self_screen

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Signing android version by JKS file

Для того чтобы подписать собранный APK на Windows надо:

1. Положить ключ в локальную папку, так чтобы flutter мог до него добраться
2. Заполнить файл `android/local.properties` по примеру

```
android.sign.keyfile=/home/iaverin/Documents/dev/self_screen/android/sign/my-stuff.jks
android.sign.keyalias=my-stuff
android.sign.storepass=СуперПарольНикомуНеСкажу
```

Дл получения детально информации о сертификате, например для фаербейза нжно выполнить аналог команды - `/opt/android-studio/jbr/bin/keytool -list -v -alias my-stuff -keystore ~/Documents/dev/my_stuff/android/sign/my-stuff.jks`


Details of andoid certificate
```
Alias name: my-stuff
Creation date: Oct 20, 2024
Entry type: PrivateKeyEntry
Certificate chain length: 1
Certificate[1]:
Owner: CN=Igor, OU=Dev, O=MyStuff, L=Dubai, ST=Dubai, C=AE
Issuer: CN=Igor, OU=Dev, O=MyStuff, L=Dubai, ST=Dubai, C=AE
Serial number: a7757995290055be
Valid from: Sun Oct 20 15:19:31 IRKT 2024 until: Thu Mar 07 15:19:31 IRKT 2052
Certificate fingerprints:
         SHA1: E2:06:37:31:13:1D:52:BA:0B:5D:12:9B:4B:5E:60:EF:90:78:0C:CF
         SHA256: FA:27:32:92:45:89:46:12:C7:24:1C:4D:74:88:3D:57:BA:BC:AD:F1:7D:33:4E:0C:31:43:E4:11:77:54:3B:DF
Signature algorithm name: SHA384withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

