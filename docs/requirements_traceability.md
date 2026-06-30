# Requirements Traceability

This matrix tracks requirement issues against the implementation and verification artifacts in the repository.

| Requirement | GitHub issue | Status | Implementation | Verification |
| --- | --- | --- | --- | --- |
| Guest request flow E2E coverage | #4 Add E2E coverage for Request a seat booking flow | Implemented | `ExperienceDetailView` exposes stable request-sheet identifiers and `RequestsView` exposes a scroll target for acceptance checks. | `dineatlocalsUITests.testGuestCanRequestSeatAndSeePendingRequest` drives date selection, seat adjustment, intro and notes entry, submission through `experience.request.submit`, and pending request visibility in Requests. |
| Host request action E2E coverage | #5 Add E2E coverage for host request accept and decline actions | Implemented | `RequestsView` exposes request card, status, accept, and decline identifiers keyed by request ID. | `dineatlocalsUITests.testHostCanAcceptAndDeclineRequests` accepts one pending host request, declines another, verifies status updates, and verifies action controls are removed after each transition. |
