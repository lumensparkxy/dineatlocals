# AGENTS.md

Guidance for Codex and other automation agents working on `dineatlocals`, a SwiftUI iOS marketplace app.

## Project Shape

- Main app target: `dineatlocals`
- Unit tests: `dineatlocalsTests`
- UI tests: `dineatlocalsUITests`
- Xcode project: `dineatlocals.xcodeproj`
- Core state and service wiring: `dineatlocals/AppCore`
- Domain models, validation, scheduling: `dineatlocals/Domain`
- Data mapping and mock store: `dineatlocals/Data`
- SwiftUI screens and shared surfaces: `dineatlocals/Features`
- Assets and plist: `dineatlocals/Assets.xcassets`, `dineatlocals/Info.plist`

Keep changes inside the smallest layer that owns the behavior. UI-only work should not change domain models, service protocols, persistence, mappers, or mock-data contracts unless the issue explicitly requires it.

## Branching Strategy

- Do not commit directly to `main`.
- Start each tracked issue from an up-to-date `main`:
  ```bash
  git switch main
  git pull --ff-only origin main
  ```
- Use one branch per issue or requirement slice.
- Preferred branch name for GitHub issues:
  ```text
  issue-<issue-number>-short-kebab-name
  ```
  Example: `issue-3-request-inbox-identifiers`
- For untracked exploratory work, use:
  ```text
  codex/<short-kebab-name>
  ```
- Keep branches focused. Do not combine unrelated visual, model, test, and cleanup work unless the issue explicitly scopes that cross-cutting change.
- Before opening a PR, verify:
  ```bash
  git status --short --branch
  git diff --stat
  ```

## GitHub Issue Workflow

- Inspect open issues before selecting work.
- Pick the earliest unblocked requirement issue unless the user names a specific issue.
- Skip issues labeled `status:blocked` unless the task is to unblock them.
- PRs must include:
  - concise summary
  - test evidence with commands
  - `Closes #<issue-number>` when the PR completes the issue
- Prefer squash merge for single-issue branches.
- After merge:
  ```bash
  git switch main
  git pull --ff-only origin main
  git branch -d <branch>
  git fetch --prune origin
  ```
- Confirm the linked issue is closed after merge.

## Swift And SwiftUI Practices

- Favor simple SwiftUI composition over broad abstractions.
- Keep view state local with `@State`; use `@Environment(AppModel.self)` for app state already owned by `AppModel`.
- Keep domain logic out of views. Put schedule, validation, and capacity rules in `Domain`.
- Preserve actor-isolation correctness. Shared pure value types and helpers that must be usable outside the main actor should stay explicitly `nonisolated` where appropriate.
- Do not add custom font dependencies unless the issue explicitly asks for them.
- Keep reusable visual tokens in existing shared surface files rather than scattering colors and radii.
- Use existing image/catalog assets before adding new generated assets.
- Avoid unrelated project-file churn in `project.pbxproj`.

## UI And Accessibility

- Every tappable UI element used by UI tests should have a stable accessibility identifier.
- Do not rely on visible copy alone when multiple elements can share labels such as `Accept`, `Decline`, or `Request a seat`.
- Prefer identifiers that map to product concepts:
  ```text
  feature.scope.element
  request.accept.<request-id>
  host.create.calendar.day.<yyyy-mm-dd>
  ```
- Keep VoiceOver labels and values meaningful when using `.labelsHidden()` or custom containers.
- When SwiftUI exposes controls differently across simulator and device, query by identifier across element types in UI tests rather than assuming `button`, `picker`, or `otherElement`.
- For scrollable sheets, give the scroll view a stable identifier and scroll that view directly in UI tests.

## Testing

Always remove old result bundles before reusing a path:

```bash
rm -rf /tmp/dineatlocals-<name>.xcresult
```

Use the full Xcode developer directory for CLI builds and tests:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

Run focused tests first, then broader tests when practical.

Common unit regression suite:

```bash
rm -rf /tmp/dineatlocals-units.xcresult
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -quiet \
  -project dineatlocals.xcodeproj \
  -scheme dineatlocals \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:dineatlocalsTests/MarketplaceMapperTests \
  -only-testing:dineatlocalsTests/MarketplaceValidationTests \
  -only-testing:dineatlocalsTests/MockMarketplaceStoreTests \
  -resultBundlePath /tmp/dineatlocals-units.xcresult
```

Focused UI test example:

```bash
rm -rf /tmp/dineatlocals-ui.xcresult
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -quiet \
  -project dineatlocals.xcodeproj \
  -scheme dineatlocals \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:dineatlocalsUITests/dineatlocalsUITests/testDiscoverFlowShowsExperienceCalendar \
  -resultBundlePath /tmp/dineatlocals-ui.xcresult
```

If a simulator name is unavailable, list available devices:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available
```

Physical device test flow:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun devicectl list devices
```

Then test with the discovered device id:

```bash
rm -rf /tmp/dineatlocals-device.xcresult
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -quiet \
  -project dineatlocals.xcodeproj \
  -scheme dineatlocals \
  -destination 'id=<device-id>' \
  -allowProvisioningUpdates \
  -only-testing:dineatlocalsUITests/dineatlocalsUITests/<testName> \
  -resultBundlePath /tmp/dineatlocals-device.xcresult
```

Use `xcrun xcresulttool get test-results summary --path <bundle> --format json` for concise pass/fail summaries.

## Physical Device Notes

- The device must be trusted, unlocked, and in Developer Mode.
- Use `-allowProvisioningUpdates` for physical-device builds unless the issue is specifically about signing.
- Do not change bundle identifiers, signing teams, entitlements, or provisioning settings unless the task explicitly requires it.
- Xcode may emit benign debugger or DeviceSupport warnings during physical-device UI tests. Treat XCTest pass/fail and result bundles as the source of truth.

## Design System Guidance

- Current visual direction is Neighbourhood Supper Club: warm, intimate, host-story led, trustworthy.
- Keep the shared `Festive*` symbol names unless a task explicitly scopes a naming migration.
- Use the established Supper Club palette and surfaces instead of introducing a new unrelated visual language.
- Guest-facing large titles may use SwiftUI serif design; controls, forms, tabs, and operational screens should use default system text.
- Avoid decorative orb/blob backgrounds.
- Keep cards, controls, and bottom actions stable across iPhone and iPad sizes.

## Data And Contract Safety

- Do not change public model, service, mapper, persistence, or mock-store contracts for UI-only issues.
- Existing tests around marketplace mapping, validation, and mock store behavior are regression gates.
- Capacity, blocked-date, accepted-request, and schedule materialization behavior belongs in domain/store code and must stay covered by tests.
- Do not commit secrets, signing credentials, private user data, `.xcresult` bundles, DerivedData, or local generated scratch files.

## Review Checklist

Before committing:

- The branch is issue-scoped.
- `git diff` contains no unrelated formatting or project-file churn.
- UI changes have stable accessibility identifiers where tests or user workflows depend on them.
- Relevant focused tests pass.
- Broader unit tests pass when the change touches shared domain, data, or app-state behavior.
- PR body records exact verification commands and any known unrelated failures.
