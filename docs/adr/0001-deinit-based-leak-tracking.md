# 1. Deinit-based memory-leak tracking in tests

Date: 2026-08-22

## Status

Accepted

## Context

XCTest gave us `addTeardownBlock`, which is how the old
`XCTestCase+trackForMemoryLeaks` helper asserted that a SUT had been
deallocated by the end of a test. Swift Testing has no teardown-block
registration and no test-case base class, so that mechanism has no direct
equivalent.

What it does have: a fresh instance of the suite type per `@Test`. That makes
`deinit` the one hook guaranteed to run after each individual test body.

(The XCTest helper we replaced had zero call sites — there was no leak coverage
to preserve. This decision is about the coverage we chose to add, not about
porting something that worked.)

## Decision

Leak assertions live in the `deinit` of a `LeakTrackingTestCase` base class,
copied from the same helper used in SwiftyOTP. Suites that assert on leaks are
`final class … : LeakTrackingTestCase` and call `trackForMemoryLeaks(_:)`;
suites with nothing to track stay `struct`s.

Before wiring any real suite, a throwaway canary proved the mechanism reports
in both directions: a deliberately retained instance failed with the issue
attributed to the correct test and source line, and a deallocated one passed.

## Consequences

- Any suite that leak-checks must be a **class**, not a struct. That is the
  cost of using `deinit` as the teardown hook.
- Suites needing cleanup that isn't a leak assertion (deleting temp folders,
  wiping `UserDefaults` suites or keychain stores) use their own `deinit`
  directly rather than inheriting, since they must hold their SUTs strongly —
  which is the opposite of what leak tracking asserts.
- The tracker is single-threaded by contract: teardown blocks must not be
  registered from background tasks, and a test that spawns child tasks should
  let them finish before returning, or a still-running task can hold the SUT
  alive and fail the assertion spuriously.
- If a future Swift Testing release offers a real per-test teardown trait, this
  is the thing to revisit — it would let the suites go back to being structs.

## Alternatives considered

- **A composed `final class LeakTracker` property** instead of a base class.
  Keeps suites as value types and needs no inheritance. Rejected so this
  repo's helper stays byte-identical to the SwiftyOTP one it came from; one
  proven helper across both packages beats two designs.
- **Explicit `withLeakTracking { }` scope per test body.** Most flexible, but
  it puts the ceremony in every test instead of once in a base class.
