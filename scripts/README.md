# Auto Build Scripts

Deze scripts verhogen automatisch het buildnummer voordat je een build maakt.

## Scripts

### `auto_increment_build.sh`
- Genereert een timestamp-based buildnummer (YYYYMMDDHHMM)
- Wordt aangeroepen door de andere build scripts

### `build_ios.sh`
- Genereert timestamp buildnummer
- Maakt clean build
- Buildt voor iOS release
- Gebruik: `./scripts/build_ios.sh`

### `build_android.sh`
- Genereert timestamp buildnummer
- Maakt clean build
- Buildt voor Android release
- Gebruik: `./scripts/build_android.sh`

## Gebruik

Voor iOS build:
```bash
./scripts/build_ios.sh
```

Voor Android build:
```bash
./scripts/build_android.sh
```

## Voorbeeld output
```
🔢 Auto incrementing build number...
Current timestamp: Thu Jan 25 14:32:00 CET 2024
New build number: 202401251432
✅ Build number updated to 202401251432
🚀 Starting iOS build process...
🧹 Cleaning previous build...
📱 Building for iOS...
✅ Build complete!
```

## Timestamp Format
- **YYYY**: Jaar (2024)
- **MM**: Maand (01-12)
- **DD**: Dag (01-31)
- **HH**: Uur (00-23)
- **MM**: Minuut (00-59)

Voorbeeld: `202401251432` = 25 januari 2024, 14:32

Nu hoef je nooit meer handmatig het buildnummer te verhogen! 🎉 