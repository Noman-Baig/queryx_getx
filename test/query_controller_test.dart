// These tests use `flutter_test`, not plain `dart test` — GetX schedules an
// `onReady()` post-frame callback internally when a controller is put via
// `Get.put`, which needs Flutter's binding initialized. Run with
// `flutter test`.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:queryx_getx/queryx_getx.dart';

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset(); // clean GetX dependency-injection state between tests
  });

  group('useQuery', () {
    test('fetches and exposes data through QueryxSnapshot', () async {
      setupQueryxClient(QueryClient(), permanent: true);

      final controller = useQuery<List<String>>(
        QueryKey(['users']),
        () async => ['ada', 'linus'],
      );

      expect(controller.value.isLoading, isTrue);
      await pump();

      expect(controller.value.hasData, isTrue);
      expect(controller.value.data, ['ada', 'linus']);
    });

    test('same key returns the same registered controller', () {
      setupQueryxClient(QueryClient(), permanent: true);

      final a = useQuery<String>(QueryKey(['dashboard']), () async => 'x');
      final b = useQuery<String>(QueryKey(['dashboard']), () async => 'x');

      expect(identical(a, b), isTrue);
    });

    test('two calls with a shared key still dedupe to one network fetch',
        () async {
      setupQueryxClient(QueryClient(), permanent: true);
      var callCount = 0;
      Future<String> fetcher() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 'v';
      }

      // Force two distinct controllers via distinct tags, to prove
      // deduplication happens at the QueryClient layer, independent of the
      // GetX controller-sharing convenience.
      useQuery<String>(QueryKey(['shared']), fetcher, tag: 'a');
      useQuery<String>(QueryKey(['shared']), fetcher, tag: 'b');

      await pump();
      await pump();
      await pump();

      expect(callCount, 1, reason: 'QueryClient dedup should still apply');
    });

    test('disposeQuery releases the GetX controller', () {
      setupQueryxClient(QueryClient(), permanent: true);
      useQuery<String>(QueryKey(['temp']), () async => 'x');
      expect(Get.isRegistered<QueryxController<String>>(tag: 'temp'), isTrue);

      disposeQuery<String>(QueryKey(['temp']));
      expect(Get.isRegistered<QueryxController<String>>(tag: 'temp'), isFalse);
    });

    test(
        'invalidateQueries on the shared client causes the controller to refetch',
        () async {
      final client = QueryClient();
      setupQueryxClient(client, permanent: true);
      var callCount = 0;
      final key = QueryKey(['profile']);

      final controller = useQuery<String>(key, () async {
        callCount++;
        return 'v$callCount';
      });

      await pump();
      expect(controller.value.data, 'v1');

      client.invalidateQueries(key);
      await pump();

      expect(controller.value.data, 'v2');
    });
  });

  group('useMutation', () {
    test('mutateAsync updates state and can invalidate a query controller',
        () async {
      final client = QueryClient();
      setupQueryxClient(client, permanent: true);

      var usersFetchCount = 0;
      final usersKey = QueryKey(['users']);
      final usersController = useQuery<List<String>>(usersKey, () async {
        usersFetchCount++;
        return List.generate(usersFetchCount, (i) => 'user$i');
      });
      await pump();
      expect(usersFetchCount, 1);

      final mutationController = useMutation<String, String, void>(
        'create-user',
        (name) async => 'created:$name',
        options: MutationOptions(
          onSuccess: (data, variables, context) {
            client.invalidateQueries(usersKey);
          },
        ),
      );

      final result = await mutationController.mutateAsync('grace');
      expect(result, 'created:grace');
      expect(mutationController.value.isSuccess, isTrue);

      await pump();
      expect(usersFetchCount, 2);
      expect(usersController.value.data, ['user0', 'user1']);
    });

    test('optimistic update via queryxClient cache primitives + rollback',
        () async {
      final client = QueryClient();
      setupQueryxClient(client, permanent: true);
      final likesKey = QueryKey(['post', 1, 'likes']);

      final likes = useQuery<int>(likesKey, () async => 5);
      await pump();
      expect(likes.value.data, 5);

      final fail = useMutation<int, void, int>(
        'like-fails',
        (_) async => throw Exception('server rejected'),
        options: MutationOptions<int, void, int>(
          onMutate: (_) async {
            final snapshot = client.getQueryData<int>(likesKey)!;
            client.updateQueryData<int>(likesKey, (n) => (n ?? 0) + 1);
            return snapshot;
          },
          onError: (error, _, snapshot) {
            if (snapshot != null) client.setQueryData<int>(likesKey, snapshot);
          },
        ),
      );

      await expectLater(fail.mutateAsync(null), throwsA(isA<QueryError>()));
      expect(likes.value.data, 5,
          reason: 'rollback should restore prior value');
    });
  });

  group('useInfiniteQuery', () {
    test('fetchNextPage accumulates items through the controller', () async {
      final allPages = [
        const InfinitePage(items: ['a', 'b'], nextParam: 1),
        const InfinitePage<String, int>(items: ['c'], nextParam: null),
      ];

      final feed = useInfiniteQuery<String, int>(
        QueryKey(['feed']),
        initialPageParam: 0,
        fetchPage: (page) async => allPages[page ?? 0],
      );

      await pump();
      expect(feed.value.items, ['a', 'b']);

      await feed.fetchNextPage();
      expect(feed.value.items, ['a', 'b', 'c']);
      expect(feed.value.hasNextPage, isFalse);
    });
  });
}
