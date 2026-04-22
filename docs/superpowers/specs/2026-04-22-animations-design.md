# Animations Design

**Date:** 2026-04-22  
**Scope:** Subtle, polished motion for route transitions and tab switching  
**Approach:** Option B — GoRouter `pageBuilder` transitions + `AnimatedSwitcher` tab crossfade

---

## Goals

- Every navigation feels intentional and smooth, never jarring
- Short durations (200–300ms), standard Material curves
- Zero new dependencies — Flutter built-ins only

---

## Route Transitions

All `GoRoute` entries in `router.dart` switch from `builder:` to `pageBuilder:` returning a `CustomTransitionPage`. Three helper functions handle the three distinct patterns:

### `_slidePage(child)` — Onboarding screens
- Routes: all `/onboarding/*`
- Transition: horizontal slide-in from right (`SlideTransition` with `Tween<Offset>(begin: Offset(1,0), end: Offset.zero)`)
- Duration: 280ms
- Curve: `Curves.easeInOut`

### `_slideUpPage(child)` — Log modals
- Routes: `/log/camera`, `/log/scan-result`, `/log/search`, `/log/exercise`, `/log/water`
- Transition: slide up from bottom + fade (`SlideTransition` + `FadeTransition` composed)
- `begin: Offset(0, 0.08)` (subtle, not a full-screen slide — avoids feeling heavy)
- Duration: 300ms
- Curve: `Curves.fastOutSlowIn`

### `_fadePage(child)` — Shell tab routes
- Routes: `/home`, `/analytics`, `/settings`
- Transition: fade only (`FadeTransition`)
- Duration: 200ms
- Curve: `Curves.easeIn`

All three helpers are private functions at the bottom of `router.dart`. Each `pageBuilder:` call is a single line.

---

## Tab Content Crossfade

`ScaffoldWithNavBar` (`lib/widgets/scaffold_with_nav_bar.dart`) is upgraded from `StatelessWidget` to `StatefulWidget`.

- Wraps `child` in `AnimatedSwitcher(duration: 200ms, transitionBuilder: FadeTransition)`
- **Key:** the current tab path string from `GoRouterState.of(context).uri.path`
- The switcher only fires when the tab path changes — log modal pushes over the shell leave it untouched
- No slide inside the switcher (nav bar is fixed; sliding content looks mismatched)

---

## Files Changed

| File | Change |
|---|---|
| `lib/router.dart` | Add `_slidePage`, `_slideUpPage`, `_fadePage` helpers; switch all routes to `pageBuilder` |
| `lib/widgets/scaffold_with_nav_bar.dart` | `StatelessWidget` → `StatefulWidget`; wrap `child` in `AnimatedSwitcher` |

---

## Out of Scope

- Staggered list entrance animations (food entry cards)
- Hero animations between screens
- FAB scale/rotation animations
- Lottie loading animations
