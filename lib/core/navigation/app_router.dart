import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/details/screens/movie_details_screen.dart';
import '../../models/movie.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/movie/:id',
        name: 'details',
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final id = int.tryParse(idStr ?? '') ?? 0;
          
          // Optional Movie model passed from source list to support instant Hero transitions
          final movie = state.extra is Movie ? state.extra as Movie : null;
          
          return MovieDetailsScreen(
            movieId: id,
            initialMovie: movie,
          );
        },
      ),
    ],
  );
});
