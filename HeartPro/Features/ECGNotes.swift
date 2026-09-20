import SwiftUI
import HeartProCore

struct NoteCard: View {
    var note: JournalNote
    var body: some View {
        Surface {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Image(systemName: "note.text").foregroundStyle(HP.coral)
                    Text(note.date.formatted(.dateTime.month().day().hour().minute().locale(L10n.locale))).font(.subheadline.weight(.semibold))
                    Spacer()
                    if note.healthRequested { Image(systemName: note.pendingSymptoms.isEmpty ? "checkmark.icloud" : "icloud.slash").foregroundStyle(.secondary).font(.caption) }
                }
                if !note.symptoms.isEmpty {
                    Text(L10n.list(note.symptoms.map(\.title))).font(.caption.weight(.medium)).foregroundStyle(HP.coral)
                }
                if let duration = note.duration { Text(L10n.text("持续 \(Int(duration / 60)) 分钟")).font(.caption).foregroundStyle(.secondary) }
                if !note.text.isEmpty { Text(note.text).font(.subheadline).foregroundStyle(.secondary).lineLimit(5) }
                if let error = note.healthError { Text(L10n.text("本地已保存，健康写入未完成\n\(AnalysisText.readable(error))")).font(.caption).foregroundStyle(HP.amber) }
            }
        }
    }
}

struct NoteEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let recordID: UUID
    let existing: JournalNote?
    @State private var date: Date
    @State private var text: String
    @State private var symptoms: Set<Symptom>
    @State private var severity: Int
    @State private var durationMinutes: Int
    @State private var writeToHealth: Bool
    @State private var isSaving = false
    @State private var confirmDelete = false
    private var externalLocked: Bool { !(existing?.writtenSymptoms.isEmpty ?? true) }

    init(recordID: UUID, date: Date, existing: JournalNote? = nil) {
        self.recordID = recordID; self.existing = existing
        _date = State(initialValue: existing?.date ?? date)
        _text = State(initialValue: existing?.text ?? "")
        _symptoms = State(initialValue: Set(existing?.symptoms ?? []))
        _severity = State(initialValue: existing?.severity ?? 1)
        _durationMinutes = State(initialValue: Int((existing?.duration ?? 0) / 60))
        _writeToHealth = State(initialValue: existing?.healthRequested ?? false)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Surface {
                    VStack(spacing: 16) {
                        DatePicker(L10n.text("发生时间"), selection: $date, displayedComponents: [.date, .hourAndMinute]).font(.subheadline)
                        Divider()
                        Stepper(value: $durationMinutes, in: 0...1440) {
                            LabeledContent(L10n.text("持续时间"), value: durationMinutes == 0 ? L10n.text("未记录") : L10n.text("\(durationMinutes) 分钟"))
                        }.font(.subheadline).accessibilityIdentifier("noteDuration")
                    }.disabled(externalLocked)
                }
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeading(title: L10n.text("快速记录"), subtitle: L10n.text("可多选"))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 10) {
                        ForEach(Symptom.allCases) { symptom in
                            Button { toggle(symptom) } label: {
                                Text(symptom.title).font(.subheadline.weight(symptoms.contains(symptom) ? .semibold : .regular))
                                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                                    .background(symptoms.contains(symptom) ? HP.coral.opacity(0.12) : HP.paper, in: Capsule())
                                    .overlay(Capsule().strokeBorder(symptoms.contains(symptom) ? HP.coral.opacity(0.4) : .primary.opacity(0.05)))
                            }.foregroundStyle(symptoms.contains(symptom) ? HP.coral : .primary).disabled(externalLocked)
                                .accessibilityIdentifier("symptom-\(symptom.rawValue)")
                        }
                    }
                }
                if symptoms.contains(where: \.canWriteToHealth) {
                    Surface {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(L10n.text("不适程度")).font(.subheadline.weight(.semibold))
                            Picker(L10n.text("不适程度"), selection: $severity) { Text(L10n.text("轻微")).tag(1); Text(L10n.text("中等")).tag(2); Text(L10n.text("明显")).tag(3) }.pickerStyle(.segmented).disabled(externalLocked)
                        }
                    }
                }
                if symptoms.contains(where: \.needsAttention) {
                    Label(L10n.text("如有持续胸痛、明显气短或晕厥，请立即寻求急救帮助，不要等待本应用分析。"), systemImage: "cross.case")
                        .font(.caption).foregroundStyle(HP.amber).padding(16).background(HP.amber.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                }
                Surface {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("补充说明")).font(.subheadline.weight(.semibold))
                        TextField(L10n.text("例如：午后喝过咖啡，静坐时感觉心跳明显…"), text: $text, axis: .vertical)
                            .lineLimit(5...10).font(.subheadline).accessibilityIdentifier("noteText")
                    }
                }
                if model.isDemo { Label(L10n.text("演示备忘只在本次体验中保留，不会写入健康。"), systemImage: "info.circle").font(.caption).foregroundStyle(.secondary) }
                else {
                    Surface {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(L10n.text("同时记录到 Apple 健康"), isOn: $writeToHealth).font(.subheadline.weight(.medium)).disabled(externalLocked || !symptoms.contains(where: \.canWriteToHealth))
                            Text(L10n.text("仅写入你选定的受支持症状、程度与时间，来源为 HeartPro。自由文本保留在本地，不会修改原始 ECG 或它的备注。"))
                                .font(.caption).foregroundStyle(.secondary)
                            if writeToHealth {
                                Text(L10n.text("将写入：\(L10n.list(symptoms.filter(\.canWriteToHealth).sorted { $0.rawValue < $1.rawValue }.map(\.title)))"))
                                    .font(.caption).foregroundStyle(HP.teal)
                            }
                            if externalLocked {
                                Text(L10n.text("已写入健康的症状在此保留原状；你可以继续编辑本地文字。需要更改这些症状时，请在健康 App 中管理。"))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if let existing, existing.healthRequested, !existing.pendingSymptoms.isEmpty {
                    Button(L10n.text("重试未完成的健康写入")) { Task { await model.writeNote(existing) } }.buttonStyle(.bordered).buttonBorderShape(.capsule)
                }
                if existing != nil { Button(L10n.text("删除本地备忘"), role: .destructive) { confirmDelete = true }.frame(maxWidth: .infinity).padding(.top, 12) }
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(AppBackground()).navigationTitle(existing == nil ? L10n.text("添加备忘") : L10n.text("编辑备忘")).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.text("取消")) { dismiss() }.disabled(isSaving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: { if isSaving { ProgressView() } else { Text(L10n.text("保存")).bold() } }
                        .disabled(isSaving || (symptoms.isEmpty && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)).accessibilityIdentifier("saveNote")
                }
            }
            .interactiveDismissDisabled(isSaving)
            .confirmationDialog(L10n.text("删除本地备忘？已写入 Apple 健康的独立症状会保留。"), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(L10n.text("删除本地备忘"), role: .destructive) { if let existing { Task { await model.deleteNote(existing); dismiss() } } }
            }
    }

    private func toggle(_ symptom: Symptom) {
        if symptoms.contains(symptom) { symptoms.remove(symptom) }
        else {
            if symptom == .none { symptoms = [.none] }
            else { symptoms.remove(.none); symptoms.insert(symptom) }
        }
        if !symptoms.contains(where: \.canWriteToHealth) { writeToHealth = false }
    }
    private func save() {
        isSaving = true
        let note = JournalNote(id: existing?.id ?? UUID(), recordID: recordID, date: date,
                               text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                               symptoms: symptoms.sorted { $0.rawValue < $1.rawValue }, severity: severity,
                               revision: (existing?.revision ?? 0) + 1, healthRequested: writeToHealth && !model.isDemo,
                               writtenSymptoms: existing?.writtenSymptoms ?? [], duration: durationMinutes == 0 ? nil : Double(durationMinutes * 60))
        Task { let saved = await model.saveNote(note); isSaving = false; if saved { dismiss() } }
    }
}
