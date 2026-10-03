/// Route paths and names used by GoRouter.
enum AppRoute {
  dashboard('/dashboard'),
  transactions('/transactions'),
  addTransaction('/transactions/add'),
  editTransaction('/transactions/edit/:id'),
  reports('/reports'),
  settings('/settings'),
  categoryManager('/categories'),
  budgetSetup('/budget/setup'),
  smartRecordingReview('/smart-recording/review'),
  receiptPicker('/smart-recording/receipt-picker');

  const AppRoute(this.path);
  final String path;
}
