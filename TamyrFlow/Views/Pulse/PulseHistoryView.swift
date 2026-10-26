import SwiftUI

struct PulseHistoryView: View {
    @ObservedObject var service: PulseService
    @Environment(\.dismiss) private var dismiss
    @State private var items: [PulseMeasurement] = []
    @State private var isLoadingMore = false
    @State private var canLoadMore = true
    @State private var detail: PulseMeasurement?

    private let pageSize = 40

    var body: some View {
        ZStack {
            GoalsBackgroundView()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text(L10n.Pulse.historyTitle)
                        .font(AppFont.interBold(17))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, ProfileTheme.contentInset)
                .padding(.top, 6)

                if items.isEmpty && !isLoadingMore {
                    VStack(spacing: 10) {
                        Spacer()
                        Text(L10n.Pulse.noData)
                            .font(AppFont.interBold(16))
                            .foregroundStyle(.white)
                        Text(L10n.Pulse.historyEmptySub)
                            .font(AppFont.interBold(13))
                            .foregroundStyle(ProfileTheme.muted)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(items) { item in
                                Button {
                                    detail = item
                                } label: {
                                    historyRow(item)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    if item.id == items.last?.id {
                                        Task { await loadMore() }
                                    }
                                }
                            }
                            if isLoadingMore {
                                ProgressView().tint(.white).padding()
                            }
                        }
                        .padding(.horizontal, ProfileTheme.contentInset)
                        .padding(.top, 14)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task { await reload() }
        .sheet(item: $detail) { m in
            PulseInfoSheet(kind: .measurementDetail(m), onDismiss: { detail = nil })
        }
    }

    private func historyRow(_ m: PulseMeasurement) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.48))
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color(red: 1, green: 0.35, blue: 0.48).opacity(0.18)))

            VStack(alignment: .leading, spacing: 4) {
                Text(PulseFormatters.bpmWithUnit(m.value))
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Text("\(PulseFormatters.shortDateTime(m.recordedAt)) · \(PulseFormatters.sourceTitle(m.source))")
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ProfileTheme.muted)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ProfileTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private func reload() async {
        items = []
        canLoadMore = true
        await loadMore()
    }

    private func loadMore() async {
        guard canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        let page = await service.loadHistory(limit: pageSize, offset: items.count)
        if page.count < pageSize { canLoadMore = false }
        let existing = Set(items.map(\.id))
        items.append(contentsOf: page.filter { !existing.contains($0.id) })
    }
}
