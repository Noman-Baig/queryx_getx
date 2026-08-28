<p align="center">
  <img
    src="https://raw.githubusercontent.com/Noman-Baig/queryx_dio/main/assets/logo.jpg"
    alt="QueryX GetX"
    width="240"
    style="border-radius: 24px;"
  />
</p>

<h1 align="center">queryx_getx</h1>

<p align="center">
  Reactive GetX bindings for QueryX.
</p>

<p align="center">
  Query · Mutation · InfiniteQuery
</p>

<p align="center">
  <a href="https://pub.dev/packages/queryx_getx">
    <img src="https://img.shields.io/pub/v/queryx_getx.svg" alt="pub.dev"/>
  </a>
  <a href="https://pub.dev/packages/queryx_getx/score">
    <img src="https://img.shields.io/pub/likes/queryx_getx.svg" alt="likes"/>
  </a>
  <a href="https://github.com/fixprob/queryx_getx/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/fixprob/queryx_getx/test.yml" alt="CI"/>
  </a>
  <img src="https://img.shields.io/badge/GetX-compatible-blueviolet" alt="GetX"/>
</p>

---

GetX bindings for [`queryx`](../queryx) — `Query`, `Mutation`, and
`InfiniteQuery` exposed as reactive `GetxController`s (`.obs`), so GetX apps
get automatic rebuilds via `Obx`/`GetX` widgets with zero manual listener
wiring.

Like `queryx_riverpod`, this is a thin adapter, not a second engine: every
query still goes through one shared `QueryClient` — dedup, caching, retry,
and invalidation all work exactly like they do in plain `queryx`.

## Setup

```dart
void main() {
  setupQueryxClient(QueryClient(defaultStaleTime: const Duration(minutes: 5)));
  runApp(const MyApp());
}
```

`queryxClient` (the getter) throws a clear error if you forget to call
`setupQueryxClient` first — same philosophy as `queryx_riverpod`'s
`queryxClientProvider`: no silent throwaway client that would break
cross-widget cache sharing.

## Queries

```dart
class UsersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final users = useQuery<List<User>>(QueryKey(['users']), api.getUsers);
    return Obx(() => users.value.when(
      loading: () => const CircularProgressIndicator(),
      error: (e) => Text(e.message),
      data: (data) => ListView(children: [for (final u in data) Text(u.name)]),
    ));
  }
}
```

`useQuery` registers the controller with GetX's dependency injection under
`key.id` — call it again anywhere in the app with an equivalent key and you
get back the *same* controller (one `Obx` subscription shared, on top of the
dedup/caching queryx already does at the `QueryClient` level).

Call `disposeQuery(key)` from a `StatefulWidget.dispose()` if you want the
GetX-level controller released eagerly. The cached data itself survives
regardless — that's governed by queryx's own `cacheTime`, independent of
the GetX controller's lifecycle.

### Dependent / parameterized queries

Pass a unique `tag` (or just rely on the key including the parameter, e.g.
`QueryKey(['user', userId])`, which already produces a distinct default
tag per user):

```dart
final userController = useQuery<User>(
  QueryKey(['user', userId]),
  () => api.getUser(userId),
);
```

For a query that should only run once another finishes, use `enabled`:

```dart
final orders = useQuery<List<Order>>(
  QueryKey(['orders', userId]),
  () => api.getOrders(userId),
  options: QueryOptions(enabled: userController.value.hasData),
);
```

## Mutations

```dart
final likePost = useMutation<int, void, int>(
  'like-post-1', // tag — mutations don't have an intrinsic key like queries do
  (_) => api.post('/posts/1/like'),
  options: MutationOptions(
    onMutate: (_) async {
      final snapshot = queryxClient.getQueryData<int>(likesKey)!;
      queryxClient.updateQueryData<int>(likesKey, (n) => (n ?? 0) + 1); // instant UI update
      return snapshot;
    },
    onSuccess: (serverCount, _, __) => queryxClient.setQueryData(likesKey, serverCount),
    onError: (error, _, snapshot) => queryxClient.setQueryData(likesKey, snapshot!), // rollback
  ),
);

ElevatedButton(
  onPressed: () => likePost.mutate(null),
  child: const Icon(Icons.favorite),
)
```

Because `queryxClient` is reachable globally through GetX's DI, mutation
callbacks don't need anything like `queryx_riverpod`'s `optionsBuilder(ref)`
— just reference `queryxClient` directly inside `onMutate`/`onSuccess`.

## Infinite queries

```dart
final feed = useInfiniteQuery<Post, int>(
  QueryKey(['posts']),
  initialPageParam: 0,
  fetchPage: (page) => api.getPosts(page: page ?? 0),
);

Obx(() => ListView(
  children: [
    for (final post in feed.value.items) PostTile(post),
    if (feed.value.hasNextPage)
      TextButton(onPressed: feed.fetchNextPage, child: const Text('Load more')),
  ],
));
```

## A note on testing

Unlike `queryx_riverpod` (which depends on the pure-Dart `riverpod`
package and is testable with plain `dart test`), GetX itself (`get`) is a
single combined package that pulls in Flutter — there's no
`flutter_riverpod`-style split. `Get.put()` schedules an internal
`onReady()` post-frame callback that needs Flutter's binding initialized,
so this package's tests run under `flutter test`, not `dart test` — see
`test/query_controller_test.dart`.

## Installation

```yaml
dependencies:
  queryx_getx: ^0.1.0
  get: ^4.6.6
```
