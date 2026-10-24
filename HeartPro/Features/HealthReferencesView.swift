import SwiftUI
import HeartProCore

struct HealthReferenceLinks: View {
    var references: [HealthReference]
    var showsNotice = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("健康信息来源")).font(.subheadline.weight(.semibold))
            ForEach(references) { reference in
                Link(destination: reference.url) {
                    Text("[\(reference.id)] \(reference.title)")
                        .font(.subheadline).multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }.accessibilityIdentifier("healthReference-\(reference.id)")
            }
            if showsNotice {
                Text(HealthInformation.referenceNotice).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct HealthReferencesButton: View {
    @State private var showing = false
    var body: some View {
        Button { showing = true } label: {
            Label(L10n.text("健康信息与来源"), systemImage: "books.vertical")
                .frame(minHeight: 44)
        }.accessibilityIdentifier("openHealthReferences")
            .sheet(isPresented: $showing) {
                NavigationStack { HealthReferencesView() }
            }
    }
}

struct HealthReferencesView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List {
            Section {
                Text(HealthInformation.referenceNotice)
                Text(HealthInformation.implementationNotice)
            }
            sources(L10n.text("原始心电图"), references: [.appleECG, .healthKitECG])
            sources(L10n.text("心电分段分析"), references: [.ecg, .pWave, .qt])
            Section(L10n.text("本次 ECG 的 HRV")) {
                Text(HealthInformation.shortHRVNotice)
                ForEach(HealthReference.ecgHRV) { source($0) }
            }
            sources(L10n.text("早搏候选与节律"), references: [.prematureBeats])
            sources(L10n.text("日常心率与 HRV"), references: [.heartRate, .healthKitHRV])
        }
        .accessibilityIdentifier("healthReferenceCatalog")
        .navigationTitle(L10n.text("健康信息与来源")).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text("完成")) { dismiss() } } }
    }

    private func sources(_ title: String, references: [HealthReference]) -> some View {
        Section(title) { ForEach(references) { source($0) } }
    }

    private func source(_ reference: HealthReference) -> some View {
        Link(destination: reference.url) {
            VStack(alignment: .leading, spacing: 6) {
                Text("[\(reference.id)] \(reference.title)")
                Text(reference.citation).font(.caption).foregroundStyle(Color.secondary)
            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }.accessibilityIdentifier("healthReference-\(reference.id)")
    }
}
