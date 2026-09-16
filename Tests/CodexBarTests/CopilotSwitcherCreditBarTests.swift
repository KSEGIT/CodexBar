import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

struct CopilotSwitcherCreditBarTests {
    private func makeSnapshot(
        used: Double,
        total: Double? = 3800,
        primary: RateWindow? = nil,
        rowID: String = CopilotCreditDetailRows.seatRowID) throws -> UsageSnapshot
    {
        let progress = try total.map { try ProviderDetailSection.Row.Progress(used: used, total: $0) }
        let row = try ProviderDetailSection.Row(
            id: rowID,
            label: "Credits used",
            value: "Credits",
            progress: progress,
            usageValue: used)
        return try UsageSnapshot(
            primary: primary,
            secondary: nil,
            details: [ProviderDetailSection(title: "Credits", rows: [row])],
            updatedAt: Date())
    }

    @Test(arguments: [0.0, 1351.0, 3800.0, 4000.0])
    func `copilot switcher uses seat credits in both display modes`(used: Double) throws {
        let snapshot = try self.makeSnapshot(used: used)
        let usedPercent = used / 3800 * 100

        #expect(StatusItemController.switcherWeeklyMetricPercent(
            for: .copilot, snapshot: snapshot, showUsed: true) == usedPercent)
        #expect(StatusItemController.switcherWeeklyMetricPercent(
            for: .copilot, snapshot: snapshot, showUsed: false) == max(0, 100 - usedPercent))
    }

    @Test
    func `copilot switcher preserves metered quota before seat credits`() throws {
        let primary = RateWindow(usedPercent: 28, windowMinutes: nil, resetsAt: nil, resetDescription: nil)
        let snapshot = try self.makeSnapshot(used: 1351, primary: primary)

        #expect(StatusItemController.switcherWeeklyMetricPercent(
            for: .copilot, snapshot: snapshot, showUsed: false) == 72)
        #expect(StatusItemController.switcherWeeklyMetricPercent(
            for: .copilot, snapshot: snapshot, showUsed: true) == 28)
    }

    @Test
    func `copilot switcher hides bar without a credit entitlement`() throws {
        let snapshot = try self.makeSnapshot(used: 1351, total: nil)

        #expect(StatusItemController.switcherWeeklyMetricPercent(
            for: .copilot, snapshot: snapshot, showUsed: false) == nil)
        #expect(StatusItemController.switcherWeeklyMetricPercent(
            for: .copilot, snapshot: nil, showUsed: true) == nil)
    }

    @Test
    func `switcher credit fallback only reads copilot seat credits`() throws {
        let snapshot = try self.makeSnapshot(used: 1351)
        let unrelatedRow = try self.makeSnapshot(used: 1351, rowID: "other-credits")

        #expect(StatusItemController.switcherWeeklyMetricPercent(
            for: .claude, snapshot: snapshot, showUsed: false) == nil)
        #expect(StatusItemController.switcherWeeklyMetricPercent(
            for: .copilot, snapshot: unrelatedRow, showUsed: false) == nil)
    }
}
