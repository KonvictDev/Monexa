// lib/utils/date_filter.dart

// Enum for predefined date ranges
enum DateFilter {
  today,
  yesterday,
  last7Days,
  last30Days,
  custom,
}

enum PaymentOption { cash, online }

enum PinStage { verifyOld, setNew, confirmNew }

enum Feature {
  // Volume Limits (Orders and Products)
  orders,
  products,

  // Feature Access (UI/Gated)
  cloudSync,
  dataRestore,
  dataExport,
  advancedFiltering,
  customerManagement, // Add/Edit/Delete Customers
  categoryCustomization, // Add new categories
  receiptCustomization, // Edit receipt footer/toggles
  ltvAnalytics, // Customer LTV metrics
  changeSecurityPin, // Changing the PIN
}