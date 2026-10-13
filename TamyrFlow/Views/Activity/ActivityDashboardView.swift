import SwiftUI

struct ActivityDashboardView: View {
    @ObservedObject var service: ActivityService
    var onAdd: () -> Void
    var onOpenGoals: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                stepsRing
                metricsGrid
                chartCard
                achievementsCard
                recentCard
                goalsFooter
            }
            .padding(.horizontal, ProfileTheme.contentInset)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(ProfileTheme.accent))
                    .shadow(color: ProfileTheme.accent.opacity(0.4), radius: 10, y: 2)
            }
            .padding(.trailing, ProfileTheme.contentInset)
            .padding(.bottom, 16)
        }
    }

    private var stepsRing: some View {
        let ratio = service.metrics.stepsTarget > 0
            ? min(1, service.metrics.steps / service.metrics.stepsTarget) : 0

        return HStack {
            Button {
                // Cycle metric focus later — reserved.
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(ProfileTheme.muted)
            }
            .buttonStyle(.plain)

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: ratio)
                    .stroke(
                        ProfileTheme.accent,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ProfileTheme.accent.opacity(0.45), radius: 8, y: 0)

                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(ProfileTheme.accent)
                    Text(formatInt(service.metrics.steps))
                        .font(AppFont.interBold(28))
                        .foregroundStyle(.white)
                    Text(String(format: L10n.Activity.stepsOf, formatInt(service.metrics.stepsTarget)))
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                }
            }
            .frame(width: 200, height: 200)

            Spacer()

            Button {} label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(ProfileTheme.muted)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    private var metricsGrid: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                metricCard(
                    asset: "GoalIconActivity",
                    value: "\(formatInt(service.metrics.calories)) \(L10n.Goals.unitHint(for: .activity))",
                    sub: String(format: L10n.Activity.outOf, formatInt(service.metrics.caloriesTarget)),
                    ratio: ratio(service.metrics.calories, service.metrics.caloriesTarget),
                    tint: Color.orange
                )
                metricCard(
                    asset: "GoalIconSleep",
                    value: String(format: L10n.Activity.sleepValue, formatDec(service.metrics.sleepHours)),
                    sub: String(format: L10n.Activity.outOfHours, formatDec(service.metrics.sleepTarget)),
                    ratio: ratio(service.metrics.sleepHours, service.metrics.sleepTarget),
                    tint: Color.purple
                )
            }
            GridRow {
                metricCard(
                    asset: "GoalIconWater",
                    value: String(format: L10n.Activity.waterValue, formatDec(service.metrics.waterLiters)),
                    sub: String(format: L10n.Activity.outOfLiters, formatDec(service.metrics.waterTarget)),
                    ratio: ratio(service.metrics.waterLiters, service.metrics.waterTarget),
                    tint: Color.cyan
                )
                metricCard(
                    asset: "GoalIconWeight",
                    value: String(format: L10n.Activity.weightValue, formatDec(service.metrics.weightKg)),
                    sub: String(format: L10n.Activity.weightGoal, formatDec(service.metrics.weightTarget)),
                    ratio: weightRatio(),
                    tint: Color.green
                )
            }
        }
    }

    private func metricCard(asset: String, value: String, sub: String, ratio: CGFloat, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
            Text(value)
                .font(AppFont.interBold(15))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 38, alignment: .topLeading)
            Text(sub)
                .font(AppFont.interBold(11))
                .foregroundStyle(ProfileTheme.muted)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(tint).frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .profileCard()
        .gridCellUnsizedAxes([.vertical])
    }

    private var chartCard: some View {
        let maxV = max(service.hourly.map(\.value).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(ProfileTheme.accent)
                Text(L10n.Activity.chartTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(service.hourly.filter { $0.hour % 2 == 0 }) { bar in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(ProfileTheme.accent.opacity(bar.value > 0 ? 0.95 : 0.25))
                            .frame(height: max(8, CGFloat(bar.value / maxV) * 110))
                        if bar.hour % 6 == 0 {
                            Text(String(format: "%02d:00", bar.hour))
                                .font(AppFont.interBold(9))
                                .foregroundStyle(ProfileTheme.muted)
                        } else {
                            Text(" ")
                                .font(AppFont.interBold(9))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .padding(16)
        .profileCard()
    }

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(ProfileTheme.accent)
                Text(L10n.Activity.achievementsTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(service.achievementDefs) { def in
                        let on = service.unlockedIds.contains(def.id)
                        VStack(spacing: 8) {
                            Image(systemName: achievementSymbol(def.kind))
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(on ? ProfileTheme.accent : ProfileTheme.muted)
                                .frame(width: 52, height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(on ? ProfileTheme.accent.opacity(0.22) : Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(on ? ProfileTheme.accent : ProfileTheme.cardBorder, lineWidth: on ? 2 : 1)
                                        )
                                )
                            Text(L10n.Activity.achievementLabel(def))
                                .font(AppFont.interBold(11))
                                .foregroundStyle(on ? .white : ProfileTheme.muted)
                                .multilineTextAlignment(.center)
                                .frame(width: 72)
                        }
                    }
                }
            }
        }
        .padding(16)
        .profileCard()
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(ProfileTheme.accent)
                Text(L10n.Activity.recentTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Spacer()
            }

            ForEach(service.dayEntries.prefix(8)) { entry in
                HStack(spacing: 12) {
                    Image(entry.typeKey.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(AppFont.interBold(14))
                            .foregroundStyle(.white)
                        Text(String(format: L10n.Activity.recentMeta, entry.durationMin, L10n.Activity.intensityTitle(entry.intensity)))
                            .font(AppFont.interBold(12))
                            .foregroundStyle(ProfileTheme.muted)
                    }
                    Spacer()
                    Text(timeLabel(entry.startedAt))
                        .font(AppFont.interBold(11))
                        .foregroundStyle(ProfileTheme.muted)
                }
                .padding(.vertical, 4)
            }

            if service.dayEntries.isEmpty {
                Text(L10n.Activity.recentEmpty)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
            }
        }
        .padding(16)
        .profileCard()
    }

    @ViewBuilder
    private var goalsFooter: some View {
        if service.activeGoals.isEmpty {
            Button(action: onOpenGoals) {
                HStack(spacing: 12) {
                    Image("GoalIconTarget")
                        .resizable().scaledToFit().frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Activity.setGoalsTitle)
                            .font(AppFont.interBold(14)).foregroundStyle(.white)
                        Text(L10n.Activity.setGoalsSub)
                            .font(AppFont.interBold(12)).foregroundStyle(ProfileTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(ProfileTheme.muted)
                }
                .padding(14)
                .profileCard()
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.Activity.activeGoalsTitle)
                    .font(AppFont.interBold(15)).foregroundStyle(.white)
                ForEach(service.activeGoals.prefix(4)) { g in
                    HStack {
                        Image(g.category.assetName).resizable().scaledToFit().frame(width: 32, height: 32)
                        Text(L10n.Goals.title(for: g.category))
                            .font(AppFont.interBold(13)).foregroundStyle(.white)
                        Spacer()
                    }
                }
                Button(action: onOpenGoals) {
                    Text(L10n.Activity.openGoals)
                        .font(AppFont.interBold(13))
                        .foregroundStyle(ProfileTheme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .profileCard()
        }
    }

    // MARK: - Helpers

    private func ratio(_ v: Double, _ t: Double) -> CGFloat {
        guard t > 0 else { return 0 }
        return CGFloat(min(1, max(0, v / t)))
    }

    private func weightRatio() -> CGFloat {
        guard service.metrics.weightTarget > 0, service.metrics.weightKg > 0 else { return 0 }
        let diff = abs(service.metrics.weightKg - service.metrics.weightTarget)
        return CGFloat(max(0, min(1, 1 - diff / max(service.metrics.weightTarget, 1))))
    }

    private func formatInt(_ v: Double) -> String {
        let n = Int(v.rounded())
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func formatDec(_ v: Double) -> String {
        let n = (v * 10).rounded() / 10
        return n == floor(n) ? "\(Int(n))" : String(format: "%.1f", n)
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: LanguageStoreBootstrap.bundle.preferredLocalizations.first ?? "ru")
        if Calendar.current.isDateInToday(date) {
            f.dateFormat = "HH:mm"
            return String(format: L10n.Activity.todayTime, f.string(from: date))
        }
        f.dateFormat = "d MMM, HH:mm"
        return f.string(from: date)
    }

    private func achievementSymbol(_ kind: String) -> String {
        switch kind {
        case "steps": return "figure.walk"
        case "calories": return "flame.fill"
        case "water": return "drop.fill"
        case "sleep": return "moon.fill"
        case "weight": return "scalemass.fill"
        case "workout": return "dumbbell.fill"
        default: return "star.fill"
        }
    }
}
