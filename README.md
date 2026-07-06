# Stock Inventory

Offline-first inventory management app built with Flutter, MVVM, and a local SQLite database (`sqflite`). No server, no account, no internet required — all data lives on the device.

Inspired by the feature set of *Mobile Inventory PRO*: named items with barcodes, categories, stock-in/out tracking, low-stock alerts, and camera barcode scanning.

## Architecture (MVVM)

```
lib/
  core/db/        DatabaseHelper — sqflite schema, migrations, singleton connection
  core/theme/      App-wide theme
  models/          Plain data classes: Category, Item, StockTransaction
  repositories/    CRUD + queries against DatabaseHelper (the "Model" access layer)
  viewmodels/      ChangeNotifier classes — screen state + business logic, no widgets
  views/           Screens (Flutter widgets) — bind to a ViewModel via provider
  widgets/         Small reusable UI pieces (ItemCard, StatTile, EmptyState)
```

Each screen creates its ViewModel with `ChangeNotifierProvider` and reads it with
`context.watch<...>()` — Views never call repositories or touch the database directly.

## Features

- Items: name, barcode/SKU, category, quantity, unit price, unit, low-stock threshold, notes
- Categories: create/edit/delete, items get uncategorized (not deleted) if their category is removed
- Stock In / Stock Out / Adjustment, each recorded as an auditable transaction row
- Dashboard: total items, low-stock count, total inventory value, recent activity feed
- Search & filter items by name/barcode, category, and low-stock-only
- Barcode scanning via the device camera (`mobile_scanner`) — scan to look up an existing
  item or jump straight into "add new item" with the barcode pre-filled; also usable
  from the item form to fill the barcode field

## Database schema

- `categories(id, name, description, created_at)`
- `items(id, name, barcode, category_id, quantity, unit_price, low_stock_threshold, unit, notes, created_at, updated_at)`
- `stock_transactions(id, item_id, type[IN|OUT|ADJUST], quantity, note, created_at)`

`items.quantity` is only ever changed inside `TransactionRepository.recordTransaction`,
inside a DB transaction together with the audit row, so the running total and history
can never drift apart.

## Getting started

This repo currently contains the Dart source (`lib/`) and `pubspec.yaml` only. Flutter's
platform folders (`android/`, `ios/`, etc.) aren't included, so generate them once:

```bash
cd "Stock Inventory"
flutter create . --project-name stock_inventory --org com.example
flutter pub get
```

`flutter create .` on a directory that already has `lib/` and `pubspec.yaml` only adds
the missing platform folders — it will not overwrite your existing code.

### Camera permission (required for barcode scanning)

After running `flutter create .`, add the camera permission:

**Android** — `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS** — `ios/Runner/Info.plist`, inside the top-level `<dict>`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is used to scan item barcodes.</string>
```

### Run

```bash
flutter run
```

## Possible next steps

- Item photos
- CSV/Excel import & export
- Multiple list types (purchase orders, receipts, fixed-asset lists)
- Bluetooth/Zebra DataWedge hardware scanner support
