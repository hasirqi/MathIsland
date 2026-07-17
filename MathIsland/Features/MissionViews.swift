import SwiftUI
import SwiftData

struct MissionFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var controller: MissionSessionController
    @State private var feedback: String?
    @State private var completedRecord: LearningRecord?
    private let playerID: UUID

    init(mission: Mission, playerID: UUID) {
        self.playerID = playerID
        _controller = State(initialValue: MissionSessionController(mission: mission))
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("苹果调查").font(.title2.bold())
                Spacer()
                Text("\(controller.phaseIndex + 1) / \(MissionPhase.allCases.count)").foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Group {
                switch controller.phase {
                case .introduction, .storyObservation: storyView
                case .informationSelection: informationView
                case .relationshipDecision: relationshipView
                case .modelExploration: appleModelView
                case .equationSelection: equationView
                case .calculation: calculationView
                case .explanation: explanationView
                case .reflection, .completed: summaryView
                }
            }
            .frame(maxWidth: 760)

            if let feedback {
                Text(feedback).padding().frame(maxWidth: .infinity).background(.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
            }
            if let hint = controller.currentHint {
                Text("提示：\(hint)").padding().frame(maxWidth: .infinity).background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            }
            Spacer()
        }
        .padding(28)
        .navigationBarBackButtonHidden(controller.phase != .introduction)
    }

    private var storyView: some View {
        VStack(spacing: 20) {
            Text("🐻   🧺🍎🍎🍎🍎🍎🍎🍎🍎🍎🍎🍎🍎   🐰").font(.system(size: 42))
            Text(controller.mission.story.text).font(.title2).multilineTextAlignment(.center)
            Button(controller.phase == .introduction ? "开始调查" : "我看清楚了") {
                controller.advanceFromIntroduction(); feedback = nil
            }.buttonStyle(.borderedProminent).controlSize(.large)
        }
    }

    private var informationView: some View {
        VStack(spacing: 16) {
            Text("哪些是重要信息？").font(.title.bold())
            ForEach(controller.mission.informationItems) { item in
                Button {
                    controller.toggleInformation(item.id)
                } label: {
                    HStack { Image(systemName: controller.selectedInformationIDs.contains(item.id) ? "checkmark.circle.fill" : "circle"); Text(item.text); Spacer() }
                        .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
            }
            actionButton("确认信息") {
                do { try controller.submitInformationSelection(); feedback = nil }
                catch { feedback = "还差一条重要信息，再看一遍故事。" }
            }
        }
    }

    private var relationshipView: some View {
        VStack(spacing: 16) {
            Text("小兔拿走苹果后，篮子里的苹果怎样变化？").font(.title2.bold()).multilineTextAlignment(.center)
            choiceButton("变多了", relationship: .increase)
            choiceButton("变少了", relationship: .decrease)
            choiceButton("没有变化", relationship: .combine)
            actionButton("继续") {
                do { try controller.enterModelExploration(); feedback = nil }
                catch { feedback = "拿走以后，篮子里的苹果应该变多还是变少？" }
            }
        }
    }

    private var appleModelView: some View {
        VStack(spacing: 18) {
            Text("把小兔拿走的5个苹果移出篮子").font(.title2.bold())
            Text("篮中：\((controller.mission.quantities.initial ?? 0) - controller.removedAppleCount)　已拿走：\(controller.removedAppleCount)").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(58)), count: 6), spacing: 12) {
                ForEach(0..<(controller.mission.quantities.initial ?? 0), id: \.self) { index in
                    Button(index < (controller.mission.quantities.initial ?? 0) - controller.removedAppleCount ? "🍎" : "▫️") {
                        if index < (controller.mission.quantities.initial ?? 0) - controller.removedAppleCount { controller.removeApple() }
                    }.font(.system(size: 34)).buttonStyle(.plain)
                }
            }
            HStack { Button("撤销") { controller.restoreApple() }.buttonStyle(.bordered); actionButton("完成操作") { controller.submitModelExploration(); feedback = controller.phase == .equationSelection ? nil : "请确认一共拿走了5个苹果。" } }
        }
    }

    private var equationView: some View {
        VStack(spacing: 14) {
            Text("哪个算式表示这个故事？").font(.title2.bold())
            ForEach(controller.mission.equationChoices.shuffled()) { choice in
                Button(choice.expression) {
                    controller.selectEquation(id: choice.id)
                    feedback = choice.isCorrect ? nil : "这个算式和故事还没有对应上，再想想数量是变多还是变少。"
                }.buttonStyle(.bordered).controlSize(.large)
            }
        }
    }

    private var calculationView: some View {
        VStack(spacing: 18) {
            Text("12 − 5 = ?").font(.system(size: 44, weight: .bold))
            Text(controller.enteredAnswer.map(String.init) ?? "请选择答案").font(.largeTitle)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(72)), count: 5), spacing: 12) {
                ForEach(0...20, id: \.self) { number in Button("\(number)") { controller.submitAnswer(number); feedback = number == 7 ? nil : "算式已经正确，再数一数篮子里剩下的苹果。" }.buttonStyle(.bordered) }
            }
        }
    }

    private var explanationView: some View {
        VStack(spacing: 14) {
            Text("你为什么使用减法？").font(.title2.bold())
            ForEach(controller.mission.reasoningOptions) { option in
                Button(option.text) {
                    controller.selectReasoning(id: option.id)
                    feedback = option.isCorrect ? nil : "理由要说明故事中发生了什么，以及数量怎样变化。"
                }.buttonStyle(.bordered).controlSize(.large)
            }
        }
    }

    private var summaryView: some View {
        VStack(spacing: 18) {
            Text("调查完成").font(.largeTitle.bold())
            skillCard("侦察力", "找到了故事中的重要信息", "magnifyingglass")
            skillCard("推理力", "知道拿走以后数量会变少", "brain.head.profile")
            skillCard("表达力", "能够说明为什么使用减法", "text.bubble")
            if controller.session.correctionCount > 0 { Text("你发现并修改了错误，这也是很重要的能力。") }
            if completedRecord == nil {
                actionButton("保存调查结果") {
                    do {
                        let record = try controller.completeMission(playerID: playerID)
                        try SwiftDataLearningRecordRepository(context: modelContext).save(record)
                        completedRecord = record; feedback = "学习记录已经保存。"
                    } catch { feedback = "保存失败：\(error.localizedDescription)" }
                }
            } else {
                Button("回到首页") { dismiss() }.buttonStyle(.borderedProminent).controlSize(.large)
            }
        }
    }

    private func choiceButton(_ title: String, relationship: RelationshipType) -> some View {
        Button(title) { controller.selectRelationship(relationship); feedback = relationship == .decrease ? nil : "再观察一下小兔的动作。" }
            .buttonStyle(.bordered).controlSize(.large)
    }
    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View { Button(title, action: action).buttonStyle(.borderedProminent).controlSize(.large) }
    private func skillCard(_ title: String, _ detail: String, _ icon: String) -> some View { HStack { Image(systemName: icon).font(.title); VStack(alignment: .leading) { Text(title).font(.headline); Text(detail).foregroundStyle(.secondary) }; Spacer() }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18)) }
}

private extension MissionSessionController {
    var phaseIndex: Int { MissionPhase.allCases.firstIndex(of: phase) ?? 0 }
}

struct ParentDashboardView: View {
    @Query(sort: \LearningRecordEntity.completedAt, order: .reverse) private var entities: [LearningRecordEntity]
    var body: some View {
        List {
            Section("最近一次苹果调查") {
                if let entity = entities.first, let record = try? entity.domainValue() {
                    LabeledContent("是否完成", value: record.completed ? "完成" : "未完成")
                    LabeledContent("首次关系选择", value: record.firstRelationshipSelection?.rawValue ?? "无")
                    LabeledContent("最终关系选择", value: record.finalRelationshipSelection?.rawValue ?? "无")
                    LabeledContent("首次算式", value: record.firstEquationChoice ?? "无")
                    LabeledContent("最终算式", value: record.finalEquationChoice ?? "无")
                    LabeledContent("提示次数", value: "\(record.usedHintCount)")
                    LabeledContent("修改次数", value: "\(record.correctionCount)")
                    LabeledContent("拿走苹果", value: "\(record.removedAppleCount)")
                    Text(ParentReportGenerator().summary(for: record)).padding(.vertical)
                } else { ContentUnavailableView("还没有学习记录", systemImage: "chart.bar.doc.horizontal") }
            }
        }.navigationTitle("家长报告")
    }
}
