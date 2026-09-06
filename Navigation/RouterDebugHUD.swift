import SwiftUI
import AppBase

struct RouterDebugHUD: View {
    @Environment(Router<AppTab>.self) private var router
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 8) {
            if expanded { panel }
            capsule
        }
        .padding(.bottom, router.isDetail(router.activeTab) ? 8 : 64)
        .animation(.snappy(duration: 0.25), value: expanded)
    }

    private var capsule: some View {
        Button { expanded.toggle() } label: {
            HStack(spacing: 6) {
                Image(systemName: "ladybug").font(.caption2)
                Text("\(tabLabel(router.activeTab).name) · 栈 \(router.count)")
                    .font(.caption.bold().monospacedDigit())
                Image(systemName: expanded ? "chevron.down" : "chevron.up")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.primary.opacity(0.1)))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 10) {
            tabDepths
            Divider()
            currentStack
            Divider()
            actionButtons
            if !router.historyEntries.isEmpty {
                Divider()
                recentHistory
            }
        }
        .padding(12)
        .frame(maxWidth: 280, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1)))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private var tabDepths: some View {
        HStack(spacing: 6) {
            ForEach(router.allTabs, id: \.self) { tab in
                VStack(spacing: 2) {
                    Text(tabLabel(tab).name)
                        .font(.caption2.bold())
                        .foregroundStyle(tab == router.activeTab ? .white : .primary)
                    Text("\(router.stackPaths(for: tab).count)")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(tab == router.activeTab ? .white : .primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tab == router.activeTab ? Color.blue : Color.secondary.opacity(0.12))
                )
            }
        }
    }

    private var currentStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("当前栈 (\(router.stackPaths(for: router.activeTab).count))")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            let paths = router.stackPaths(for: router.activeTab)
            if paths.isEmpty {
                Text("(空)").font(.caption.monospaced()).foregroundStyle(.secondary)
            } else {
                ForEach(Array(paths.enumerated()), id: \.offset) { index, path in
                    HStack(spacing: 6) {
                        Text("\(index)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 14, alignment: .trailing)
                        Text(path).font(.caption.monospaced()).lineLimit(1)
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            hudButton("Pop 返回", icon: "arrow.up") { router.pop() }
                .disabled(router.count == 0)
            hudButton("Pop to Root", icon: "arrow.up.to.line", destructive: true) { router.popToRoot() }
                .disabled(router.count == 0)
            hudButton("清空历史", icon: "trash") { router.clearHistory() }
        }
    }

    private var recentHistory: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("最近历史").font(.caption2.bold()).foregroundStyle(.secondary)
            ForEach(Array(router.historyEntries.suffix(4).enumerated()), id: \.offset) { _, entry in
                HStack(spacing: 6) {
                    Image(systemName: actionIcon(entry.action))
                        .font(.caption2)
                        .foregroundStyle(actionColor(entry.action))
                        .frame(width: 12)
                    Text(entry.path).font(.caption2.monospaced()).lineLimit(1)
                    Spacer()
                    Text(entry.action.rawValue).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func tabLabel(_ tab: AppTab) -> (name: String, icon: String) {
        router.tabLabels[tab] ?? (name: "\(tab)", icon: "questionmark")
    }

    private func hudButton(_ title: String, icon: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption2.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(destructive ? Color.red.opacity(0.12) : Color.secondary.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .tint(destructive ? .red : .primary)
    }

    private func actionIcon(_ action: RouteAction) -> String {
        switch action {
        case .push: return "arrow.down"
        case .pop: return "arrow.up"
        case .replace: return "arrow.triangle.2.circlepath"
        case .reset: return "arrow.clockwise"
        }
    }

    private func actionColor(_ action: RouteAction) -> Color {
        switch action {
        case .push: return .blue
        case .pop: return .orange
        case .replace: return .purple
        case .reset: return .red
        }
    }
}
