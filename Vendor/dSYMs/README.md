# Символы (dSYM) для сторонних фреймворков

Сообщения **Upload Symbols Failed** для `ABParTool`, `GRDFUSDK`, `JLDialUnit`, `ZipZap` значат: в архиве нет **dSYM** с тем же **UUID**, что у бинарника внутри `.framework`.

## Что положить сюда

Скопируйте сюда папки вида:

- `ABParTool.framework.dSYM`
- `GRDFUSDK.framework.dSYM`
- `JLDialUnit.framework.dSYM`
- `ZipZap.framework.dSYM`

(именно **bundle** `.dSYM`, как их отдаёт Xcode или поставщик SDK).

## Откуда взять

1. **Veepoo / JL (ABParTool, GRDFUSDK, JLDialUnit)**  
   Запросите у поставщика **Veepoo iOS SDK** пакет dSYM для **той же версии** бинарников, что лежат в корне проекта рядом с `.xcodeproj`. Без их dSYM символизировать краши внутри этих библиотек нельзя — сгенерировать их локально нельзя.

2. **ZipZap**  
   У вас есть исходники в `Vendor/zipzap-source/`. Соберите **Release** для **iphoneos** со схемой *ZipZap (iOS Framework)* и `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym`, затем скопируйте из `Build/Products/Release-iphoneos/` файл `ZipZap.framework.dSYM` сюда.

Проверка UUID (должен совпасть с текстом ошибки в Organizer):

```bash
dwarfdump --uuid ZipZap.framework/ZipZap
dwarfdump --uuid ZipZap.framework.dSYM
```

## Автокопирование в архив

В таргет TamyrFlow добавлен Run Script, который при **Archive** копирует все `Vendor/dSYMs/*.dSYM` в каталог dSYM архива.

Полная инструкция: **`Docs/TESTFLIGHT_DSYM.md`**.
