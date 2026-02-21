# Database Assets Folder

## 📁 Purpose

This folder is for storing the pre-populated SQLite database file.

## 📝 Instructions

If you have a pre-populated database file named `smart_warehouse_v3.db`, place it in this folder:

```
assets/
  └── database/
      └── smart_warehouse_v3.db  ← Place your database file here
```

## 🔄 How It Works

When the app runs for the first time:

1. **If `smart_warehouse_v3.db` exists here**: The app will copy it to the device's database directory
2. **If the file doesn't exist**: The app will create a new empty database with all tables

## ⚠️ Important Notes

- The database file will only be copied on **first run**
- If you update the database file in assets, you need to:
  - Uninstall the app, OR
  - Clear app data, OR
  - Increment the database version in `database_helper.dart`

## 📊 Database Structure

The database contains 10 tables:
1. Categories
2. Products
3. ProductDetails (Batches)
4. ProductUnits
5. StockTransactions
6. Contacts
7. Invoices
8. InvoiceItems
9. PredictionHistory
10. Users

See `database_usage_guide.md` for complete documentation.
