import SwiftUI

@MainActor
final class CancerCarePlanStore: ObservableObject {
    enum CarePhase: String, CaseIterable, Codable, Identifiable {
        case screening = "Screening"
        case activeTreatment = "Active treatment"
        case followUp = "Follow-up"
        case survivorship = "Survivorship"
        case supportingSomeone = "Supporting someone"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .screening: return "checklist"
            case .activeTreatment: return "cross.case.fill"
            case .followUp: return "arrow.triangle.2.circlepath"
            case .survivorship: return "leaf.fill"
            case .supportingSomeone: return "person.2.fill"
            }
        }
    }

    enum ScreeningStatus: String, CaseIterable, Codable {
        case notTracked = "Not tracked"
        case planned = "Planned"
        case completed = "Completed"
        var icon: String {
            switch self {
            case .notTracked: return "circle"
            case .planned: return "calendar.badge.clock"
            case .completed: return "checkmark.circle.fill"
            }
        }
        var tint: Color {
            switch self {
            case .notTracked: return .secondary
            case .planned: return .orange
            case .completed: return .green
            }
        }
    }

    struct ScreeningItem: Identifiable, Codable {
        let id: String
        let title: String
        let detail: String
        var status: ScreeningStatus
    }

    @Published var phase: CarePhase = .screening
    @Published var appointmentDate: Date?
    @Published var screeningItems: [ScreeningItem] = []
    @Published var discussionTopics: [String] = []
    @Published var selectedSymptoms: Set<String> = []

    private let key = "oncosense.cancer-care-plan.v1"

    init() {
        screeningItems = Self.defaultScreeningItems()
        load()
    }

    func cycleScreening(_ id: String) {
        guard let index = screeningItems.firstIndex(where: { $0.id == id }) else { return }
        switch screeningItems[index].status {
        case .notTracked: screeningItems[index].status = .planned
        case .planned: screeningItems[index].status = .completed
        case .completed: screeningItems[index].status = .notTracked
        }
        persist()
    }

    func addDiscussionTopic(_ topic: String) {
        let cleaned = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        discussionTopics.insert(cleaned, at: 0)
        discussionTopics = Array(discussionTopics.prefix(20))
        persist()
    }

    func removeDiscussionTopic(_ topic: String) {
        discussionTopics.removeAll { $0 == topic }
        persist()
    }

    func toggleSymptom(_ symptom: String) {
        if selectedSymptoms.contains(symptom) { selectedSymptoms.remove(symptom) }
        else { selectedSymptoms.insert(symptom) }
        persist()
    }

    func setPhase(_ phase: CarePhase) { self.phase = phase; persist() }
    func setAppointmentDate(_ date: Date?) { appointmentDate = date; persist() }

    private func persist() {
        let payload = PersistedPlan(phase: phase, appointmentDate: appointmentDate,
                                    screeningItems: screeningItems,
                                    discussionTopics: discussionTopics,
                                    selectedSymptoms: Array(selectedSymptoms))
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let payload = try? JSONDecoder().decode(PersistedPlan.self, from: data) else { return }
        phase = payload.phase
        appointmentDate = payload.appointmentDate
        screeningItems = payload.screeningItems.isEmpty ? Self.defaultScreeningItems() : payload.screeningItems
        discussionTopics = payload.discussionTopics
        selectedSymptoms = Set(payload.selectedSymptoms)
    }

    private struct PersistedPlan: Codable {
        let phase: CarePhase
        let appointmentDate: Date?
        let screeningItems: [ScreeningItem]
        let discussionTopics: [String]
        let selectedSymptoms: [String]
    }

    private static func defaultScreeningItems() -> [ScreeningItem] {
        [
            ScreeningItem(id: "breast", title: "Breast", detail: "Mammography or clinician-directed assessment", status: .notTracked),
            ScreeningItem(id: "cervical", title: "Cervical", detail: "HPV-based or locally recommended screening", status: .notTracked),
            ScreeningItem(id: "colorectal", title: "Colorectal", detail: "Stool testing or clinician-directed examination", status: .notTracked),
            ScreeningItem(id: "lung", title: "Lung", detail: "Risk-based screening when clinically appropriate", status: .notTracked),
            ScreeningItem(id: "other", title: "Other / clinician advised", detail: "Add the screening or follow-up your care team recommends", status: .notTracked)
        ]
    }
}

struct CancerCareSection: View {
    @StateObject private var plan = CancerCarePlanStore()
    @State private var newQuestion = ""
    @FocusState private var questionFieldFocused: Bool

    private let symptoms = [
        ("New lump or swelling", "circle.grid.cross"),
        ("Unusual bleeding", "drop.fill"),
        ("Persistent cough or voice change", "lungs.fill"),
        ("Bowel or bladder change", "arrow.left.arrow.right"),
        ("Unexplained weight change", "scalemass.fill"),
        ("Persistent pain", "figure.mixed.cardio"),
        ("Persistent fatigue", "battery.25percent"),
        ("Something else I want to mention", "ellipsis.circle.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            careJourneyCard
            screeningCard
            symptomCard
            appointmentPrepCard
            careSummaryCard
        }
    }

    private var careJourneyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("CARE JOURNEY", icon: "cross.case.fill")
            Text("Keep OncoSense aware of the context you are in.")
                .font(.subheadline).foregroundStyle(.secondary)
            Picker("Care phase", selection: Binding(get: { plan.phase }, set: { plan.setPhase($0) })) {
                ForEach(CancerCarePlanStore.CarePhase.allCases) { phase in
                    Label(phase.rawValue, systemImage: phase.icon).tag(phase)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            HStack(spacing: 10) {
                Image(systemName: plan.phase.icon)
                    .font(.title3.weight(.semibold)).foregroundStyle(.tint)
                    .frame(width: 38, height: 38)
                    .background(Color.accentColor.opacity(0.10), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.phase.rawValue).font(.headline)
                    Text("This context personalizes Care only. It does not interpret a diagnosis.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .careCard()
    }

    private var screeningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader("SCREENING & EARLY DETECTION", icon: "checklist")
                Spacer()
                let completed = plan.screeningItems.filter { $0.status == .completed }.count
                Text("\(completed)/\(plan.screeningItems.count)")
                    .font(.caption.weight(.bold).monospacedDigit()).foregroundStyle(.secondary)
            }
            Text("Track screening conversations and completed tests in one place. Tap a row to cycle its status.")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(plan.screeningItems) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { plan.cycleScreening(item.id) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.status.icon).foregroundStyle(item.status.tint).font(.title3).frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            Text(item.detail).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 8)
                        Text(item.status.rawValue).font(.caption.weight(.semibold)).foregroundStyle(item.status.tint)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if item.id != plan.screeningItems.last?.id { Divider() }
            }
            Label("Screening is not a diagnosis. Eligibility and timing depend on factors such as age, risk and local clinical guidance.", systemImage: "info.circle")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .careCard()
    }

    private var symptomCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("WHAT I WANT TO DISCUSS", icon: "text.bubble.fill")
            Text("Record symptoms or changes you want to mention to your healthcare team. Selecting an item does not mean it is caused by cancer.")
                .font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                ForEach(symptoms, id: \.0) { item in symptomChip(title: item.0, icon: item.1) }
            }
        }
        .careCard()
    }

    private func symptomChip(title: String, icon: String) -> some View {
        let selected = plan.selectedSymptoms.contains(title)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { plan.toggleSymptom(title) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selected ? "checkmark.circle.fill" : icon).foregroundStyle(selected ? .white : Color.accentColor)
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(selected ? .white : .primary).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(11).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(selected ? Color.accentColor : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var appointmentPrepCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("APPOINTMENT PREP", icon: "calendar.badge.clock")
            Text("Keep the next conversation focused. Your questions stay on this device.")
                .font(.caption).foregroundStyle(.secondary)
            DatePicker("Next appointment", selection: Binding(get: { plan.appointmentDate ?? Date.now }, set: { plan.setAppointmentDate($0) }), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
            TextField("Add a question for your care team", text: $newQuestion, axis: .vertical)
                .focused($questionFieldFocused).lineLimit(1...4).submitLabel(.done).onSubmit { addQuestion() }
                .textFieldStyle(.plain).padding(13)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Button(action: addQuestion) {
                Label("Add question", systemImage: "plus").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if !plan.discussionTopics.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("QUESTIONS TO BRING").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(plan.discussionTopics, id: \.self) { question in
                        HStack(alignment: .top, spacing: 9) {
                            Image(systemName: "checkmark.circle").foregroundStyle(.tint)
                            Text(question).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                            Button { plan.removeDiscussionTopic(question) } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .careCard()
    }

    private var careSummaryCard: some View {
        let completed = plan.screeningItems.filter { $0.status == .completed }.count
        let planned = plan.screeningItems.filter { $0.status == .planned }.count
        let topics = plan.discussionTopics.count
        let symptomsCount = plan.selectedSymptoms.count
        return VStack(alignment: .leading, spacing: 11) {
            sectionHeader("YOUR CARE SNAPSHOT", icon: "rectangle.and.pencil.and.ellipsis")
            HStack(spacing: 10) {
                summaryMetric(value: "\(completed)", label: "screening\ncompleted", icon: "checkmark.circle.fill")
                summaryMetric(value: "\(planned)", label: "screening\nplanned", icon: "calendar")
                summaryMetric(value: "\(symptomsCount)", label: "items to\ndiscuss", icon: "text.bubble.fill")
                summaryMetric(value: "\(topics)", label: "questions\nprepared", icon: "questionmark.circle.fill")
            }
            if let date = plan.appointmentDate {
                Label("Next appointment: \(date.formatted(date: .abbreviated, time: .shortened))", systemImage: "calendar")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            } else {
                Label("Add an appointment date when you have one.", systemImage: "calendar.badge.plus")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text("OncoSense uses this information to organize your own care context. It does not diagnose cancer, estimate cancer probability, or recommend treatment.")
                .font(.caption2).foregroundStyle(.secondary).padding(.top, 2)
        }
        .careCard()
    }

    private func summaryMetric(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(.tint)
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon).font(.caption.bold()).foregroundStyle(.secondary)
    }

    private func addQuestion() {
        let trimmed = newQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        plan.addDiscussionTopic(trimmed)
        newQuestion = ""
        questionFieldFocused = false
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

private extension View {
    func careCard() -> some View {
        self.padding(18).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
