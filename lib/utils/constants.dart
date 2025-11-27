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
  orders,
  products,
  cloudSync,
  dataRestore,
  dataExport,
  advancedFiltering,
  customerManagement,
  categoryCustomization,
  receiptCustomization,
  ltvAnalytics,
  changeSecurityPin,
}