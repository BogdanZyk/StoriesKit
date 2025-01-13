//
//  StackPagesView.swift
//  StoriesKit
//

import SwiftUI

/// A customizable view that displays a stack of swipeable pages, allowing navigation between pages via gestures.
/// The view supports swipe gestures, page transitions, and customizable animations and styles.
public struct StackPagesView<Item: Identifiable, Content: View>: View {
    
    @State private var currentIndex: Int
    @Binding private var externalIndex: Int
    @State private var dragOffset: CGFloat = .zero
    @State private var currentDirection: StackSwipeDirection?
    @State private var changeIndexInSelf: Bool = false
    @State private var setTask: Task<Void, Never>?
    @State private var switchPageTask: Task<Void, Never>?
    @State private var pagesStateData: [Item.ID: StackPageState]
    
    private let views: [Item]
    private let countViews: Int
    
    private var scaleFactor: CGFloat = 0.9
    private var swipeThreshold: CGFloat = 0.1
    private var animationDuration: CGFloat = 0.35
    private var cornerRadius: CGFloat = 20
    private var overlayOpacity: Double = 0.2
    
    private var onSwipe: ((StackSwipeDirection, Int) -> Void)?
    private var onReachedEnd: ((StackSwipeDirection) -> Void)?
    
    private let makeContent: (Item) -> Content
    
    public init(views: [Item],
                initPage: Int = 0,
                makeContent: @escaping (Item) -> Content) {
        self.views = views
        self._externalIndex = .constant(0)
        self._currentIndex = State(initialValue: initPage)
        self.countViews = views.count
        self.makeContent = makeContent
        
        self.pagesStateData = views.reduce(into: [:]) { dict, item in
            let id = item.id
            dict[id] = id == views[elementOrNil: initPage]?.id ? .isShowing : .hidden
        }
       
    }
        
    public var body: some View {
        
        GeometryReader { proxy in
            ZStack {
                previewCard(proxy)
                
                currentCard(proxy)
                    .simultaneousGesture(makeGesture(proxy))
                nextCard(proxy)
            }
            .onChange(of: externalIndex) {
                handleExternalIndexChange(newIndex: $0, width: proxy.size.width)
            }
        }
        .clipped()
    }
}

#Preview {
    
    
    struct Item: Identifiable {
        var id: String = UUID().uuidString
        var name: String
        var color: Color = .yellow
    }
    
    struct PageView: View {
        @Environment(\.stackPageState) private var stackPageState
        let id: String
        let color: Color
        let name: String
        var body: some View {
            ZStack {
                color
                Text(name)
                Text(stackPageState[id]?.rawValue ?? "NIL")
                    .offset(y: -100)
            }
        }
    }
    
    struct TestView2: View {
        let items = (0...10).map({Item(name: String($0))})
        @State var currentIndex: Int = 0
        var body: some View {
            StackPagesView(views: items) { content in
                PageView(id: content.id, color: content.color, name: content.name)
                
            }
                .onChangeIndex($currentIndex)
                .cardStyle(radius: 30)
                .onReachedEnd{ direction in
                    print(direction)
                }
                .ignoresSafeArea()
                .overlay(alignment: .top) {
                    HStack {
                        Text("\(currentIndex)")
                        Stepper("Index", value: $currentIndex, in: -1...11)
                    }
                   
                }
        }
    }
    
    return TestView2()

}

//MARK: - Views
extension StackPagesView {
    
    @ViewBuilder
    private func previewCard(_ proxy: GeometryProxy) -> some View {
        if let content = views[elementOrNil: currentIndex - 1] {
            
            card {
                ZStack {
                    makeContent(content)
                        .id(content.id)
                    Color.black
                        .opacity(previousCardOpacity(proxy.size.width))
                }
                
            }
            .scaleEffect(previousCardScale(proxy.size.width))
            .opacity(currentDirection == .next ? 0 : 1)
            .zIndex(0)
        }
    }
    
    @ViewBuilder
    private func currentCard(_ proxy: GeometryProxy) -> some View {
        
        if let content = views[elementOrNil: currentIndex] {

            card {
                ZStack {
                    makeContent(content)
                        .id(content.id)
                    Color.black
                        .opacity(currentDirection == .next ? currentCardOpacity(proxy.size.width) : 0)
                }
            }
            .scaleEffect(currentDirection == .next ? currentCardScale(proxy.size.width) : 1, anchor: .center)
            .offset(x: currentDirection == .next ? 0 : dragOffset)
            .zIndex(1)
        }
    }
    
    @ViewBuilder
    private func nextCard(_ proxy: GeometryProxy) -> some View {
        if let content = views[elementOrNil: currentIndex + 1] {
            card {
                makeContent(content)
                    .id(content.id)
            }
            .offset(x: dragOffset + proxy.size.width)
            .zIndex(2)
        }
    }
    
    private func makeGesture(_ proxy: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { gesture in
                handleDragChanged(gesture: gesture)
            }
            .onEnded { gesture in
                onEnded(gesture, proxy)
            }
    }
    
    private func card<Card: View>(_ cardContent: () -> Card) -> some View {
        cardContent()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .environment(\.stackPageState, pagesStateData)
    }
}

extension StackPagesView {
    
    private func currentCardScale(_ weight: CGFloat) -> CGFloat {
        let widthFactor = 1 - scaleFactor
        return max(scaleFactor, 1 - abs(dragOffset) / weight * widthFactor)
    }
    
    private func previousCardScale(_ weight: CGFloat) -> CGFloat {
        let widthFactor = 1 - scaleFactor
        return min(1, scaleFactor + abs(dragOffset) / weight * widthFactor)
    }
    
    private func previousCardOpacity(_ weight: CGFloat) -> Double {
        min(overlayOpacity, 1.0 - abs(dragOffset) / weight * 1.2)
    }

    private func currentCardOpacity(_ weight: CGFloat) -> Double {
        let maxOpacity = 1 - overlayOpacity
        return 1 - max(maxOpacity, 1.0 - abs(dragOffset) / weight * 0.8)
    }
    
    private func handleDragChanged(gesture: DragGesture.Value) {
        guard setTask == nil else { return }
        
        currentDirection = currentDirection ?? StackSwipeDirection.getDirection(from: gesture.translation.width)
        
        if canMoveFurther {
            withAnimation(.linear(duration: 0.1)) {
                dragOffset = gesture.translation.width * 0.9
            }
            if pagesStateData[views[currentIndex].id] != .inSwiped {
                changePageState(for: currentIndex, .inSwiped)
            }
        }
    }
    
    private func onEnded(_ gesture: _ChangedGesture<DragGesture>.Value, _ geometry: GeometryProxy) {
        
        guard setTask == nil else { return }
        
        if !canMoveFurther {
            if let currentDirection {
                onReachedEnd?(currentDirection)
            }
            resetDragAndDirection()
            return
        }
        
        let newIndex = currentDirection == .next ? currentIndex + 1 : currentIndex - 1
        let viewWidth = geometry.size.width
        
        guard views.isIndexValid(index: newIndex), abs(gesture.predictedEndTranslation.width) > viewWidth * swipeThreshold else {
            resetDragAndDirection()
            return
        }
        
        if let currentDirection {
            onSwipe?(currentDirection, newIndex)
        }
        
        changePageState(for: currentIndex, .beforeSwitch)
        
        updateOffsetAndSetIndex(newIndex: newIndex, width: viewWidth, withExternal: true)
    }
    
    private func updateOffsetAndSetIndex(newIndex: Int, width: CGFloat, withExternal: Bool = false) {
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            dragOffset = currentDirection == .next ? -width : width
        }
        
        setTask = Task {
            try? await Task.sleep(for: .seconds(animationDuration + 0.05))
            dragOffset = .zero
            if newIndex <= views.count - 1 {
                changePageState(for: currentIndex, .hidden)
                currentIndex = newIndex
                if withExternal {
                    externalIndex = newIndex
                }
                changePageState(for: newIndex, .isShowing)
            }
            currentDirection = nil
            setTask = nil
        }
    }
    
    private func changePageState(for index: Int, _ state: StackPageState?) {
                
        guard let id = views[elementOrNil: index]?.id else { return }
        
        pagesStateData[id] = state
    }
    
    private func resetDragAndDirection() {
        withAnimation(.easeInOut) {
            dragOffset = .zero
        }
        currentDirection = nil
        changePageState(for: currentIndex, .isShowing)
    }
    
    private var canMoveFurther: Bool {
        currentDirection == .next ? (currentIndex < views.count - 1) : currentIndex > 0
    }
    
    private func handleExternalIndexChange(newIndex: Int, width: CGFloat) {
        
        guard newIndex != currentIndex, switchPageTask == nil else { return }
        
        switchPageTask = Task {
            
            defer {
                switchPageTask = nil
            }
            
            self.currentDirection = newIndex > currentIndex ? .next : .previous
            
            if !canMoveFurther {
                if let currentDirection {
                    onReachedEnd?(currentDirection)
                    externalIndex = currentIndex
                }
                resetDragAndDirection()
                return
            }
            
            guard views.isIndexValid(index: newIndex) else {
                resetDragAndDirection()
                return
            }
            
            updateOffsetAndSetIndex(newIndex: newIndex, width: width)
            
        }
    
    }
}

public enum StackSwipeDirection {
    
    case next, previous
    
    static func getDirection(from translation: CGFloat) -> StackSwipeDirection {
        translation < 0 ? .next : .previous
    }
}

public extension StackPagesView {
    
    /// Sets the threshold for detecting a swipe gesture.
    /// - Parameter threshold: The threshold, expressed as a fraction of the view's width, beyond which a swipe is registered.
    /// - Returns: A modified `StackPagesView` with the updated swipe threshold.
    func swipeThreshold(_ threshold: CGFloat) -> Self {
        var copy = self
        copy.swipeThreshold = threshold
        return copy
    }
    
    /// Sets the duration of the slide animation for page transitions.
    /// - Parameter duration: The duration of the animation in seconds.
    /// - Returns: A modified `StackPagesView` with the updated animation duration.
    func slideDuration(_ duration: CGFloat) -> Self {
        var copy = self
        copy.animationDuration = duration
        return copy
    }
    
    /// Configures the card style with a specific corner radius and scale factor for non-active pages.
    /// - Parameters:
    ///   - radius: The corner radius applied to the cards. Defaults to 20.
    ///   - scaleFactor: The scale factor applied to non-active cards. Defaults to 0.9.
    /// - Returns: A modified `StackPagesView` with the updated card style.
    func cardStyle(radius: CGFloat = 20, scaleFactor: CGFloat = 0.9) -> Self {
        var copy = self
        copy.cornerRadius = radius
        copy.scaleFactor = scaleFactor
        return copy
    }
    
    /// Sets a closure to be called when the end of the stack is reached.
    /// - Parameter action: The closure to execute when the stack's end is reached.
    ///   - direction: The direction of the swipe that triggered the end.
    /// - Returns: A modified `StackPagesView` with the `onReachedEnd` action configured.
    func onReachedEnd(_ action: @escaping (StackSwipeDirection) -> Void) -> Self {
        var copy = self
        copy.onReachedEnd = action
        return copy
    }
    
    /// Sets a closure to be called when a swipe gesture is detected.
    /// - Parameter action: The closure to execute on a swipe.
    ///   - direction: The direction of the swipe.
    ///   - index: The index of the new page after the swipe.
    /// - Returns: A modified `StackPagesView` with the `onSwipe` action configured.
    func onSwipe(_ action: @escaping ((StackSwipeDirection, Int) -> Void)) -> Self {
        var copy = self
        copy.onSwipe = action
        return copy
    }
    
    /// Sets the opacity of the overlay applied to non-visible cards.
    /// - Parameter opacity: The opacity value for the overlay.
    /// - Returns: A modified `StackPagesView` with the updated overlay opacity.
    func opacityOverlay(_ opacity: CGFloat) -> Self {
        var copy = self
        copy.overlayOpacity = opacity
        return copy
    }
    
    /// Binds the view's page index to an external `Binding`.
    /// - Parameter index: A binding to an external integer that tracks the current page index.
    /// - Returns: A modified `StackPagesView` with the external index binding applied.
    func onChangeIndex(_ index: Binding<Int>) -> Self {
        var copy = self
        copy._externalIndex = index
        return copy
    }
}

