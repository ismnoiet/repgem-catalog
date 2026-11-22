import DustDissolve

// Many views at once: one scope, one controller per view.
struct Tiles: View {
    @StateObject private var holder = Holder()
    final class Holder: ObservableObject {
        let dusts = (0..<9).map { _ in DustDissolveController(.snap) }
    }
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)

    var body: some View {
        DustDissolveScope(holder.dusts) {
            LazyVGrid(columns: columns) {
                ForEach(Array(holder.dusts.enumerated()), id: \.element.id) { i, dust in
                    Tile(i)
                        .dustSource(dust)               // each tile has its own controller
                        .onTapGesture { dust.fire() }
                }
            }
        }
    }
}
