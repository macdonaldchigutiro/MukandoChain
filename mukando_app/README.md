# MukandoChain - Flutter app

A transparent digital ledger for savings groups (mukando / round).
Android, iOS and web from one codebase.

## 1. Create the project (inside your CropMedic folder)
    flutter create mukandochain
    cd mukandochain

Copy from this folder into the new project, replacing what's there:
- pubspec.yaml      -> mukandochain/pubspec.yaml
- lib/ (all files)  -> mukandochain/lib/

    flutter pub get

## 2. Start the backend first (port 8001)
See the backend README.

## 3. Run
    flutter run -d chrome

## Try this
- Tap a pending member (grey) and record their payment
- Watch the pot ring fill and gold coins flow when everyone has paid
- Tap RELEASE to pay out the pot and see the celebration
- Flask menu > "Tamper with a record", then open the Ledger tab and see
  TAMPERING DETECTED. Flask menu > "Reset demo" puts it right again
- Tap any record in the Ledger to see its fingerprint and copy a receipt
- Tap the ? icon for a plain-language explanation

## Phone testing
In lib/api.dart set baseUrl to http://YOUR-PC-IP:8001 (same Wi-Fi) and add
android:usesCleartextTraffic="true" to the <application> tag in
android/app/src/main/AndroidManifest.xml, plus:
    <uses-permission android:name="android.permission.INTERNET"/>
