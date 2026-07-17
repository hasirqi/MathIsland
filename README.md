# MathIsland｜小小调查员：数字岛

面向小学二年级儿童的 iPad 数学理解游戏。产品重点不是口算速度，而是训练：读懂故事、识别有效信息、判断数量关系、建立算式并说明理由。

## Phase 0

当前分支完成首个苹果任务垂直切片：

1. 阅读“12 个苹果拿走 5 个”的故事；
2. 找出已知条件和问题；
3. 判断数量变多或变少；
4. 操作 12 个苹果并移走 5 个；
5. 选择 `12 - 5`；
6. 计算得到 7；
7. 选择完整理由；
8. 保存 SwiftData 学习记录；
9. 在家长报告中查看错误类型和规则总结。

## 技术栈

- SwiftUI
- Observation 状态机
- SwiftData
- 本地 JSON 内容
- Swift Testing

不使用网络、第三方依赖、AI、广告或账号系统。

## 运行

用 Xcode 打开 `MathIsland.xcodeproj`，选择 iPad Simulator，运行 `MathIsland` Scheme。

命令行验证示例：

```bash
xcodebuild -project MathIsland.xcodeproj -scheme MathIsland -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build
xcodebuild -project MathIsland.xcodeproj -scheme MathIsland -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' test
```

模拟器名称不同时先运行：

```bash
xcrun simctl list devices available
```

## 内容扩展

任务位于 `MathIsland/Missions/`。新增任务时复制现有 JSON，并保证：

- 错误算式带有明确 `LearningErrorType`；
- 提示从观察情境逐步推进，不能直接给答案；
- 理由选项必须检验数学关系，而不是数字大小；
- View 中不得硬编码完整任务内容。

## 架构

- `Domain`：领域枚举和 Codable 模型
- `Application`：状态机、错误分析和家长报告规则
- `Infrastructure`：JSON 加载、SwiftData Entity 和 Repository
- `Features`：首页、任务流程和家长报告
- `Missions`：本地任务内容

业务模型与 SwiftData Entity 分离，避免持久化实现侵入教学逻辑。任务页面由 `MissionSessionController` 的 `MissionPhase` 驱动，不使用大量互相依赖的 Bool。

## 当前限制

- 本轮解释方式为句子选择，录音仅保留服务协议骨架；
- 苹果操作使用原生 SwiftUI 交互，SpriteKit 场景将在后续视觉交互打磨中替换；
- 当前只有一个任务模板；
- GitHub 端无法运行用户 Mac 上的 Xcode 和 Simulator，合并前必须在本地执行 Build 和 Test。
