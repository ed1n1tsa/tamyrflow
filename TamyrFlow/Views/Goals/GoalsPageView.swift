import SwiftUI

/// Root of the Goals tab: empty state ↔ list, plus create/edit wizard.
struct GoalsPageView: View {
    @StateObject private var service: GoalsService
    @State private var showCreate = false
    @State private var editingGoal: Goal?
    @State private var historyStub = false
    @State private var errorAlert: String?

    init(auth: AuthService) {
        _service = StateObject(wrappedValue: GoalsService(auth: auth))
    }

    var body: some View {
        ZStack {
            GoalsBackgroundView()

            Group {
                if service.isLoading && service.goals.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else if service.goals.isEmpty {
                    GoalsEmptyStateView {
                        showCreate = true
                    }
                } else {
                    GoalsListView(
                        service: service,
                        onCreate: { showCreate = true },
                        onEdit: { editingGoal = $0 },
                        onHistory: { historyStub = true }
                    )
                }
            }
        }
        .task { await service.refresh() }
        .fullScreenCover(isPresented: $showCreate) {
            CreateGoalFlowView(service: service, existing: nil) {
                showCreate = false
            }
        }
        .fullScreenCover(item: $editingGoal) { goal in
            CreateGoalFlowView(service: service, existing: goal) {
                editingGoal = nil
            }
        }
        .alert(L10n.Goals.historyTitle, isPresented: $historyStub) {
            Button(L10n.Goals.ok, role: .cancel) {}
        } message: {
            Text(L10n.Goals.historyStub)
        }
        .onChange(of: service.lastError) { _, err in
            if let err { errorAlert = err }
        }
        .alert(L10n.Goals.errorTitle, isPresented: Binding(
            get: { errorAlert != nil },
            set: { if !$0 { errorAlert = nil } }
        )) {
            Button(L10n.Goals.ok, role: .cancel) { errorAlert = nil }
        } message: {
            Text(errorAlert ?? "")
        }
    }
}
