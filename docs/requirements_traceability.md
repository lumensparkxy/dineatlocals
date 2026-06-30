# Requirements Traceability

This matrix tracks requirement issues against the implementation and verification artifacts in the repository.

| Requirement | GitHub issue | Status | Implementation | Verification |
| --- | --- | --- | --- | --- |
| Guest request flow E2E coverage | #4 Add E2E coverage for Request a seat booking flow | Implemented | `ExperienceDetailView` exposes stable request-sheet identifiers and `RequestsView` exposes a scroll target for acceptance checks. | `dineatlocalsUITests.testGuestCanRequestSeatAndSeePendingRequest` drives date selection, seat adjustment, intro and notes entry, submission through `experience.request.submit`, and pending request visibility in Requests. |
