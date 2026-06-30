import SwiftUI

struct RequestsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedInbox: Inbox = .guest

    private let theme = FestiveTabTheme.requests
    private let statColumns = [GridItem(.adaptive(minimum: 118), spacing: 10)]

    private enum Inbox: String, CaseIterable, Identifiable {
        case guest
        case hosting

        var id: String { rawValue }

        var title: String {
            switch self {
            case .guest:
                "Guest"
            case .hosting:
                "Hosting"
            }
        }

        var subtitle: String {
            switch self {
            case .guest:
                "Keep track of the tables you have requested and where each conversation stands."
            case .hosting:
                "Review incoming seat requests and respond while the table still feels personal."
            }
        }
    }

    var body: some View {
        ZStack {
            FestiveMarketplaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    inboxContent
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .accessibilityIdentifier("requests.scroll")
        }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            await appModel.reloadRequests()
            await appModel.reloadDiscover()
        }
    }

    private var displayedRequests: [BookingRequest] {
        selectedInbox == .guest ? appModel.guestRequests : appModel.hostRequests
    }

    private var header: some View {
        FestiveHeroCard(
            theme: theme,
            eyebrow: "Hospitality Inbox",
            title: "Requests",
            subtitle: selectedInbox.subtitle
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    ForEach(Inbox.allCases) { inbox in
                        FestiveChoicePill(
                            title: inbox.title,
                            isSelected: selectedInbox == inbox,
                            theme: theme
                        ) {
                            selectedInbox = inbox
                        }
                        .accessibilityIdentifier("requests.inbox.\(inbox.rawValue)")
                    }
                }
                .accessibilityElement(children: .contain)

                LazyVGrid(columns: statColumns, spacing: 10) {
                    FestiveMetricChip(theme: theme, value: "\(displayedRequests.count)", label: "total")
                    FestiveMetricChip(theme: theme, value: "\(count(for: .pending))", label: "pending", highlight: theme.softTint)
                    FestiveMetricChip(theme: theme, value: "\(count(for: .accepted))", label: "accepted", highlight: theme.softTint.opacity(0.88))
                    FestiveMetricChip(theme: theme, value: "\(closedCount)", label: "closed", highlight: theme.softTint.opacity(0.78))
                }
            }
        }
    }

    private var inboxContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            FestiveSectionHeading(
                theme: theme,
                eyebrow: selectedInbox == .guest ? "Guest Side" : "Hosting Side",
                title: selectedInbox == .guest ? "Your booking requests" : "Requests to your table",
                subtitle: selectedInbox == .guest ? "Every table request lives here until the host replies." : "Reply quickly while the table is still warm."
            )

            if displayedRequests.isEmpty {
                FestiveEmptyStateCard(
                    theme: theme,
                    symbolName: selectedInbox == .guest ? "fork.knife.circle" : "tray.circle",
                    title: "No Requests Yet",
                    message: selectedInbox == .guest
                        ? "Browse Discover and request a lunch or dinner to start your first conversation."
                        : "Guest requests to your hosted meals will appear here as soon as your table starts attracting interest."
                )
            } else {
                ForEach(displayedRequests) { request in
                    RequestCard(request: request, hostCanAct: selectedInbox == .hosting)
                }
            }
        }
    }

    private func count(for status: RequestStatus) -> Int {
        displayedRequests.filter { $0.status == status }.count
    }

    private var closedCount: Int {
        displayedRequests.filter { $0.status == .declined || $0.status == .cancelled }.count
    }
}

private struct RequestCard: View {
    @Environment(AppModel.self) private var appModel

    let request: BookingRequest
    let hostCanAct: Bool

    private let theme = FestiveTabTheme.requests

    private var statusStyle: RequestStatusStyle {
        RequestStatusStyle.make(for: request.status)
    }

    var body: some View {
        FestiveSectionCard(theme: theme, fill: statusStyle.surface) {
            VStack(alignment: .leading, spacing: 16) {
                topRow
                storyBlock
                if !request.guestNotes.isEmpty {
                    detailNote
                }
                actions
            }
        }
    }

    private var topRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        FestiveTag(text: hostCanAct ? "Hosting" : "Guest", fill: theme.softTint, foreground: theme.ink)
                        Text(request.seatsRequested == 1 ? "1 seat" : "\(request.seatsRequested) seats")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.8), in: Capsule())
                    }

                    Text(request.experienceTitle)
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(theme.ink)

                    Text(hostCanAct ? "Guest: \(request.guestName)" : "Host: \(request.hostName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.mutedInk)
                }

                Spacer(minLength: 12)

                RequestStatusPill(style: statusStyle)
            }

            HStack(spacing: 12) {
                Label {
                    Text(request.slotStartAt, format: .dateTime.weekday(.abbreviated).day().month().hour().minute())
                } icon: {
                    Image(systemName: "calendar")
                }

                Label("Status update in-app", systemImage: "bell.badge")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(theme.mutedInk.opacity(0.92))
        }
    }

    private var storyBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(hostCanAct ? "Guest introduction" : "Why you asked to join")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(statusStyle.tint)

            Text(request.introMessage)
                .font(.body.weight(.medium))
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .background(SupperClubPalette.paperWarm.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var detailNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Guest notes")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(theme.mutedInk.opacity(0.72))

            Text(request.guestNotes)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var actions: some View {
        if hostCanAct && request.status == .pending {
            HStack(spacing: 10) {
                Button("Accept") {
                    Task { await appModel.updateRequestStatus(.accepted, request: request) }
                }
                .buttonStyle(FestiveActionButtonStyle(tint: SupperClubPalette.sage))

                Button("Decline") {
                    Task { await appModel.updateRequestStatus(.declined, request: request) }
                }
                .buttonStyle(FestiveActionButtonStyle(tint: SupperClubPalette.oxblood))
            }
        } else if !hostCanAct && (request.status == .pending || request.status == .accepted) {
            Button("Cancel Request") {
                Task { await appModel.updateRequestStatus(.cancelled, request: request) }
            }
            .buttonStyle(FestiveActionButtonStyle(tint: theme.secondaryAccent))
        }
    }
}

private struct RequestStatusPill: View {
    let style: RequestStatusStyle

    var body: some View {
        Text(style.title)
            .font(.caption.weight(.bold))
            .foregroundStyle(style.tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct RequestStatusStyle {
    let title: String
    let tint: Color
    let surface: Color

    static func make(for status: RequestStatus) -> RequestStatusStyle {
        switch status {
        case .pending:
            RequestStatusStyle(
                title: status.title,
                tint: SupperClubPalette.amber,
                surface: SupperClubPalette.paper
            )
        case .accepted:
            RequestStatusStyle(
                title: status.title,
                tint: SupperClubPalette.sage,
                surface: SupperClubPalette.paper
            )
        case .declined:
            RequestStatusStyle(
                title: status.title,
                tint: SupperClubPalette.oxblood,
                surface: SupperClubPalette.paper
            )
        case .cancelled:
            RequestStatusStyle(
                title: status.title,
                tint: SupperClubPalette.muted,
                surface: SupperClubPalette.paper
            )
        case .completed:
            RequestStatusStyle(
                title: status.title,
                tint: SupperClubPalette.sage,
                surface: SupperClubPalette.paper
            )
        }
    }
}
