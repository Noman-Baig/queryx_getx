import 'package:get/get.dart';
import 'package:queryx/queryx.dart';

/// Registers [client] with GetX's dependency injection so every
/// `useQuery`/`useMutation` call in the app can find it via [queryxClient].
/// Call this once, near app startup:
///
/// ```dart
/// void main() {
///   setupQueryxClient(QueryClient(defaultStaleTime: const Duration(minutes: 5)));
///   runApp(const MyApp());
/// }
/// ```
void setupQueryxClient(QueryClient client, {bool permanent = true}) {
  Get.put<QueryClient>(client, permanent: permanent);
}

/// The app's shared [QueryClient], as registered via [setupQueryxClient].
/// Throws GetX's own "not found" error (with a clear message pointing back
/// here) if nothing has been registered yet — same philosophy as
/// `queryx_riverpod`'s `queryxClientProvider`: no silent throwaway client
/// that would break cross-widget cache sharing.
QueryClient get queryxClient {
  if (!Get.isRegistered<QueryClient>()) {
    throw StateError(
      'No QueryClient registered. Call setupQueryxClient(QueryClient(...)) '
      'once at app startup before using useQuery/useMutation.',
    );
  }
  return Get.find<QueryClient>();
}
