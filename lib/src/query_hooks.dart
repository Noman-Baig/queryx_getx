import 'package:get/get.dart';
import 'package:queryx/queryx.dart';

import 'query_controller.dart';
import 'queryx_client_binding.dart';

/// Gets or creates the [QueryxController] for [key], registering it with
/// GetX's dependency injection under `tag ?? key.id`.
///
/// Calling this again with an equivalent [key] — from any widget, anywhere
/// — returns the *same* controller instance, so they share one `Obx`
/// subscription in addition to the dedup/caching queryx already does at the
/// `QueryClient` level.
///
/// ```dart
/// class UsersScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final controller = useQuery(
///       QueryKey(['users']),
///       api.getUsers,
///     );
///     return Obx(() => controller.value.when(
///       loading: () => const CircularProgressIndicator(),
///       error: (e) => Text(e.message),
///       data: (users) => UserList(users),
///     ));
///   }
/// }
/// ```
///
/// Call [disposeQuery] with the same key/tag when the owning widget is
/// permanently gone (e.g. from a `StatefulWidget.dispose()`) if you want the
/// GetX-level controller released eagerly rather than left registered for
/// the app's lifetime. The underlying cache entry survives regardless —
/// queryx's own `cacheTime` GC governs that, independent of the GetX
/// controller's lifecycle.
QueryxController<T> useQuery<T>(
  QueryKey key,
  Fetcher<T> fetcher, {
  QueryOptions<T>? options,
  QueryClient? client,
  String? tag,
}) {
  final controllerTag = tag ?? key.id;
  if (Get.isRegistered<QueryxController<T>>(tag: controllerTag)) {
    return Get.find<QueryxController<T>>(tag: controllerTag);
  }
  final resolvedClient = client ?? queryxClient;
  final query = resolvedClient.query<T>(key, fetcher, options: options);
  return Get.put<QueryxController<T>>(
    QueryxController<T>(query),
    tag: controllerTag,
  );
}

/// Releases the GetX-registered controller for [key] (or [tag]) — this
/// calls the controller's `onClose()`, which releases its observer from
/// the shared cache entry. Safe to call even if nothing is registered.
void disposeQuery<T>(QueryKey key, {String? tag}) {
  final controllerTag = tag ?? key.id;
  if (Get.isRegistered<QueryxController<T>>(tag: controllerTag)) {
    Get.delete<QueryxController<T>>(tag: controllerTag);
  }
}
