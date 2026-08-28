import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:queryx_getx/queryx_getx.dart';

Future<void> main() async {
  setupQueryxClient(
    QueryClient(
      defaultStaleTime: const Duration(minutes: 1),
      logger: QueryxLogger(enabled: true),
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(home: const UsersScreen());
  }
}

// --- fake backend ----------------------------------------------------------

class FakeApi {
  static int _likes = 41;

  static Future<List<String>> getUsers() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ['Ada Lovelace', 'Linus Torvalds', 'Grace Hopper'];
  }

  static Future<int> likeLastUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _likes += 1;
    return _likes;
  }
}

final likesKey = QueryKey(['lastUser', 'likes']);

// --- UI ----------------------------------------------------------------------

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = useQuery<List<String>>(QueryKey(['users']), FakeApi.getUsers);
    final likes = useQuery<int>(likesKey, () async => 41);
    final likeMutation = useMutation<int, void, int>(
      'like-last-user',
      (_) => FakeApi.likeLastUser(),
      options: MutationOptions<int, void, int>(
        onMutate: (_) async {
          final snapshot = queryxClient.getQueryData<int>(likesKey) ?? 0;
          queryxClient.updateQueryData<int>(likesKey, (n) => (n ?? 0) + 1);
          return snapshot;
        },
        onSuccess: (serverCount, _, __) {
          queryxClient.setQueryData<int>(likesKey, serverCount);
        },
        onError: (error, _, snapshot) {
          if (snapshot != null) {
            queryxClient.setQueryData<int>(likesKey, snapshot);
          }
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('queryx_getx example')),
      body: RefreshIndicator(
        onRefresh: users.refresh,
        child: Obx(
          () => users.value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e) => Center(child: Text('Error: ${e.message}')),
            data: (people) => ListView(
              children: [
                for (final person in people) ListTile(title: Text(person)),
                ListTile(
                  title: Obx(() => Text('Likes: ${likes.value.data ?? '—'}')),
                  trailing: Obx(
                    () => likeMutation.value.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.favorite_border),
                            onPressed: () => likeMutation.mutate(null),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
