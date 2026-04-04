import 'package:flutter_test/flutter_test.dart';
import 'package:polar_app/router.dart';

void main() {
  group('resolveAppRedirect', () {
    test('sends unresolved startup state to loading', () {
      expect(
        resolveAppRedirect(
          location: '/home',
          authReady: false,
          authenticated: false,
          athleteAllowed: false,
          isCoach: false,
        ),
        '/loading',
      );
    });

    test('sends logged out users to auth', () {
      expect(
        resolveAppRedirect(
          location: '/history',
          authReady: true,
          authenticated: false,
          athleteAllowed: false,
          isCoach: false,
        ),
        '/auth',
      );
    });

    test('keeps logged out users on auth', () {
      expect(
        resolveAppRedirect(
          location: '/auth',
          authReady: true,
          authenticated: false,
          athleteAllowed: false,
          isCoach: false,
        ),
        isNull,
      );
    });

    test('sends authenticated athletes from auth to home', () {
      expect(
        resolveAppRedirect(
          location: '/auth',
          authReady: true,
          authenticated: true,
          athleteAllowed: true,
          isCoach: false,
        ),
        '/home',
      );
    });

    test('hides developer and coach paths in athlete build', () {
      expect(
        resolveAppRedirect(
          location: '/dev',
          authReady: true,
          authenticated: true,
          athleteAllowed: true,
          isCoach: false,
        ),
        '/home',
      );
      expect(
        resolveAppRedirect(
          location: '/coach/readiness',
          authReady: true,
          authenticated: true,
          athleteAllowed: true,
          isCoach: false,
        ),
        '/home',
      );
    });

    test('allows athlete routes when authenticated', () {
      expect(
        resolveAppRedirect(
          location: '/sync-session',
          authReady: true,
          authenticated: true,
          athleteAllowed: true,
          isCoach: false,
        ),
        isNull,
      );
    });

    test('sends authenticated coaches from auth to coach home', () {
      expect(
        resolveAppRedirect(
          location: '/auth',
          authReady: true,
          authenticated: true,
          athleteAllowed: false,
          isCoach: true,
        ),
        '/coach/readiness',
      );
    });

    test('keeps authenticated coaches on coach routes', () {
      expect(
        resolveAppRedirect(
          location: '/coach/readiness',
          authReady: true,
          authenticated: true,
          athleteAllowed: false,
          isCoach: true,
        ),
        isNull,
      );
    });

    test('redirects coaches away from athlete routes', () {
      expect(
        resolveAppRedirect(
          location: '/home',
          authReady: true,
          authenticated: true,
          athleteAllowed: false,
          isCoach: true,
        ),
        '/coach/readiness',
      );
    });
  });
}
