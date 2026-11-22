import SwiftUI
import DragableCards

struct TunedBoard: View {
    @StateObject private var state = DragBoardState([
        [Task(id: 1, title: "Design"), Task(id: 2, title: "Build")],
        [Task(id: 3, title: "Ship")],
        [],
    ])

    var body: some View {
        // Every config type is a struct with defaults: change only what you need.
        var timing = DragTiming()
        timing.longPress = 0.25                              // hold time before a card lifts
        timing.drop = .interpolatingSpring(mass: 1, stiffness: 600, damping: 49)

        var look = DragAppearance()
        look.liftScale = 1.06
        look.liftTilt = 6
        look.cornerRadius = 12                               // match your card so the slot has its shape

        var column = ColumnStyle()
        column.cornerRadius = 14
        column.padding = 10

        return DragBoard(
            state: state,
            columnWidth: 260,
            columnSpacing: 12,
            columnStyle: column,
            appearance: look,
            timing: timing
        ) { index, tasks in
            Text("Column \(index + 1) (\(tasks.count))")
        } card: { task in
            Text(task.title).padding(12).frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 430)
    }
}
