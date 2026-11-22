//
//  DragBoard.swift
//  DragableCards
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  A Trello-style board: long-press a card, drag it between columns, and it snaps into place.
//
import SwiftUI

/// A horizontally scrolling board of columns whose cards can be dragged between them.
///
/// ```swift
/// DragBoard(state: state) { index, tasks in
///     Text("\(titles[index]) (\(tasks.count))")
/// } card: { task in
///     Text(task.title).padding(12).background(.white)
/// }
/// .onCardMove { task, from, to, index in /* persist the move */ }   // optional, call it first
/// .frame(height: 430)
/// ```
///
/// The same `card` view draws the floating copy while you drag, so what lifts is exactly your card.
/// Give the board a bounded height.
public struct DragBoard<Item: Identifiable, Header: View, CardContent: View>: View {
    @ObservedObject private var state: DragBoardState<Item>
    private let columnWidth: CGFloat
    private let columnSpacing: CGFloat
    private let cardSpacing: CGFloat
    private let contentPadding: CGFloat
    private let columnStyle: ColumnStyle
    private let appearance: DragAppearance
    private let header: (Int, [Item]) -> Header
    private let card: (Item) -> CardContent

    /// - Parameters:
    ///   - state: The cards of every column and the drag state.
    ///   - columnWidth: Width of each column.
    ///   - columnSpacing: Gap between columns.
    ///   - cardSpacing: Gap between cards.
    ///   - contentPadding: Padding around the columns, inside the horizontal scroll.
    ///   - columnStyle: The container around each column.
    ///   - appearance: The lifted card and the empty slot.
    ///   - timing: Long-press delay and springs.
    ///   - header: Drawn at the top of each column with the column index and its items.
    ///   - card: Draws one card.
    public init(
        state: DragBoardState<Item>,
        columnWidth: CGFloat = 280,
        columnSpacing: CGFloat = 12,
        cardSpacing: CGFloat = 8,
        contentPadding: CGFloat = 16,
        columnStyle: ColumnStyle = ColumnStyle(),
        appearance: DragAppearance = DragAppearance(),
        timing: DragTiming = DragTiming(),
        @ViewBuilder header: @escaping (Int, [Item]) -> Header,
        @ViewBuilder card: @escaping (Item) -> CardContent
    ) {
        self.state = state
        self.columnWidth = columnWidth
        self.columnSpacing = columnSpacing
        self.cardSpacing = cardSpacing
        self.contentPadding = contentPadding
        self.columnStyle = columnStyle
        self.appearance = appearance
        self.header = header
        self.card = card
        state.timing = timing
    }

    /// Called after a card lands: the item, its old column, its new column and its index there.
    public func onCardMove(_ action: @escaping (Item, Int, Int, Int) -> Void) -> Self {
        state.onMove = action
        return self
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: columnSpacing) {
                            ForEach(state.columns.indices, id: \.self) { i in
                                BoardColumnView(
                                    state: state,
                                    index: i,
                                    width: columnWidth,
                                    cardSpacing: cardSpacing,
                                    style: columnStyle,
                                    appearance: appearance,
                                    header: header,
                                    card: card
                                )
                                .id(i)
                                .zIndex(state.dragging != nil && state.targetColumn == i ? 1 : 0)
                            }
                        }
                        .padding(contentPadding)
                    }
                    .scrollDisabled(state.dragging != nil)
                    .onAppear {
                        state.scrollTo = { i, anchor in
                            withAnimation(.easeInOut(duration: 0.35)) {
                                proxy.scrollTo(i, anchor: anchor)
                            }
                        }
                    }
                }

                DragOverlay(state: state, drag: state.drag, appearance: appearance, card: card)
            }
            .coordinateSpace(name: Self.space)
            .onAppear { state.boardWidth = geo.size.width }
            .onChange(of: geo.size.width) { _, w in state.boardWidth = w }
            .onPreferenceChange(FramesKey.self) { frames in
                var cards: [Item.ID: CGRect] = [:]
                var cols: [Int: CGRect] = [:]
                for (tag, rect) in frames {
                    switch tag {
                    case .card(let id):
                        if let id = id.base as? Item.ID { cards[id] = rect }
                    case .column(let i): cols[i] = rect
                    case .placeholder: state.placeholderFrame = rect
                    }
                }
                state.cardFrames = cards
                state.columnFrames = cols
            }
        }
    }

    static var space: String { "DragableCards.board" }
}

// MARK: - Column

private enum Row<Item: Identifiable>: Identifiable {
    case card(Item)
    case slot

    var id: AnyHashable {
        switch self {
        case .card(let item): return AnyHashable(item.id)
        case .slot: return AnyHashable("DragableCards.slot")
        }
    }
}

private struct BoardColumnView<Item: Identifiable, Header: View, CardContent: View>: View {
    @ObservedObject var state: DragBoardState<Item>
    let index: Int
    let width: CGFloat
    let cardSpacing: CGFloat
    let style: ColumnStyle
    let appearance: DragAppearance
    let header: (Int, [Item]) -> Header
    let card: (Item) -> CardContent

    private var items: [Item] { state.columns[index] }

    private var rows: [Row<Item>] {
        var rows: [Row<Item>] = items.map { Row.card($0) }
        guard let dragging = state.dragging, state.targetColumn == index else { return rows }
        let at = DragMath.slotRowIndex(ids: items.map(\.id), draggedID: dragging.id, targetIndex: state.targetIndex)
        rows.insert(.slot, at: at)
        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header(index, items)
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    switch row {
                    case .card(let item): cardRow(item)
                    case .slot: slotRow
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(style.padding)
        .frame(width: width)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(RoundedRectangle(cornerRadius: style.cornerRadius).fill(style.background))
        .overlay(RoundedRectangle(cornerRadius: style.cornerRadius).stroke(style.border, lineWidth: 1))
        .background(
            GeometryReader { g in
                Color.clear.preference(
                    key: FramesKey.self,
                    value: [.column(index): g.frame(in: .named(DragBoard<Item, Header, CardContent>.space))]
                )
            }
        )
    }

    private var space: String { DragBoard<Item, Header, CardContent>.space }

    @ViewBuilder
    private func cardRow(_ item: Item) -> some View {
        let isSource = state.dragging?.id == item.id
        card(item)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { g in
                    Color.clear.preference(
                        key: FramesKey.self,
                        value: [.card(AnyHashable(item.id)): g.frame(in: .named(space))]
                    )
                }
            )
            // The dragged card stays in its column, collapsed, so its gesture keeps running.
            .frame(height: isSource ? 0 : nil, alignment: .top)
            .opacity(isSource ? 0 : 1)
            .clipped()
            .padding(.bottom, isSource ? 0 : cardSpacing)
            .gesture(dragGesture(item))
    }

    @ViewBuilder
    private var slotRow: some View {
        if state.isDropping, let item = state.dragging {
            // Landing: the card renders inside its slot and springs its offset to zero.
            card(item)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    GeometryReader { g in
                        Color.clear.preference(
                            key: FramesKey.self,
                            value: [.placeholder: g.frame(in: .named(space))]
                        )
                    }
                )
                .modifier(LiftEffect(lifted: state.isLifted, appearance: appearance))
                .offset(state.landing)
                .padding(.bottom, cardSpacing)
                .zIndex(2)
        } else {
            RoundedRectangle(cornerRadius: appearance.cornerRadius)
                .fill(appearance.placeholderFill)
                .overlay(
                    RoundedRectangle(cornerRadius: appearance.cornerRadius)
                        .strokeBorder(appearance.placeholderBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
                .frame(height: state.cardSize.height)
                .background(
                    GeometryReader { g in
                        Color.clear.preference(
                            key: FramesKey.self,
                            value: [.placeholder: g.frame(in: .named(space))]
                        )
                    }
                )
                .padding(.bottom, cardSpacing)
                .transition(.opacity)
        }
    }

    private func dragGesture(_ item: Item) -> some Gesture {
        LongPressGesture(minimumDuration: state.timing.longPress)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(space)))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                state.begin(item)
                if let drag { state.move(to: drag.location, start: drag.startLocation) }
            }
            .onEnded { _ in state.drop() }
    }
}

// MARK: - Floating card

private struct LiftEffect: ViewModifier {
    let lifted: Bool
    let appearance: DragAppearance

    func body(content: Content) -> some View {
        content
            .compositingGroup()
            .shadow(
                color: .black.opacity(lifted ? appearance.liftShadowOpacity : 0),
                radius: lifted ? appearance.liftShadow : 0,
                x: 0,
                y: lifted ? appearance.liftShadow * 0.66 : 0
            )
            .scaleEffect(lifted ? appearance.liftScale : 1)
            .rotationEffect(.degrees(lifted ? appearance.liftTilt : 0))
    }
}

private struct DragOverlay<Item: Identifiable, CardContent: View>: View {
    @ObservedObject var state: DragBoardState<Item>
    @ObservedObject var drag: DragPoint
    let appearance: DragAppearance
    let card: (Item) -> CardContent

    var body: some View {
        if let item = state.dragging, !state.isDropping {
            card(item)
                .frame(width: state.cardSize.width)
                .modifier(LiftEffect(lifted: state.isLifted, appearance: appearance))
                .position(drag.center)
                .allowsHitTesting(false)
                .transition(.identity)
        }
    }
}
