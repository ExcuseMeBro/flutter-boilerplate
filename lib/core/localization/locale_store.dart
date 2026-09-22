/// Persistence seam for the active application locale.
///
/// Kept separate from the Riverpod controller so the controller and its tests
/// do not depend on a concrete preferences implementation.
abstract interface class LocaleStore {
  Future<String?> readLocaleCode();

  Future<void> writeLocaleCode(String code);
}
