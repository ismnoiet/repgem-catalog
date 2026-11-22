import SwiftUI
import DragableCards

struct Task: Identifiable {
    let id: Int
    let title: String
}

struct BoardView: View {
    @StateObject private var state = DragBoardState([
        [Task(id: 1, title: "Design"), Task(id: 2, title: "Build")],   // To do
        [Task(id: 3, title: "Ship")],                                  // Doing
        [],                                                            // Done
    ])
    private let titles = ["To do", "Doing", "Done"]

    var body: some View {
        DragBoard(state: state) { index, tasks in
            Text("\(titles[index]) (\(tasks.count))")
        } card: { task in
            Text(task.title)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white)
        }
        .onCardMove { task, from, to, index in /* persist the move */ }
        .frame(height: 430)
    }
}
