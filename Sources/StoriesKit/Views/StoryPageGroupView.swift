//
//  StoryPageGroupView.swift
//  StoriesKit
//

import SwiftUI

public struct StoryPageGroupView<Content: View>: View {
    
    @Environment(\.stackPageState) private var stackPageState
    @State private var index: Int = 0
    @State private var isAnimateProgress: Bool = true
    @State private var isPaused: Bool = false
    @StateObject private var timer: StoriesGroupTimer
    
    private let pages: [AnyStoryPage]
    private let pagesCount: Int
    private let groupId: String
    private let onReached: (PageReachedDirection) -> Void
    
    private var progressBarHeight: CGFloat = 4
    
    private var progressContent: (StoryProgressView) -> Content
    
    public init(group: AnyStoryGroup,
                onReached: @escaping (PageReachedDirection) -> Void,
                progressContent: @escaping (StoryProgressView) -> Content) {
        self.pages = group.pages
        self.pagesCount = group.pages.count
        self.groupId = group.id
        self._timer = StateObject(wrappedValue: group.timer)
        self.progressContent = progressContent
        self.onReached = onReached
    }
    
    private var pageState: StackPageState {
        stackPageState[groupId] ?? .hidden
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                controlsView
                if let page = pages[elementOrNil: index] {
                    page
                        .environment(\.storyInPause, $isPaused)
                        .id(page.id)
                }
            }
            .onAppear {
                index = timer.currentIntervalIndex
                setTimer(for: pageState)
            }
            .onChange(of: pageState) {
                setTimer(for: $0)
            }
            .onChange(of: isPaused) {
                $0 ? timer.pause() : timer.resume()
            }
            .onChange(of: timer.currentIntervalIndex) {
                onChangeIndex($0)
            }
        }
        .overlay(alignment: .top, content: {
            topHeader
        })
    }
    
    private var controlsView: some View {
        HStack(spacing: 0) {
            controlButton(preview: true)
            controlButton(preview: false)
        }
    }
    
    private func controlButton(preview: Bool) -> some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .onTapAndLongPress(tapAction: {
                isAnimateProgress = false
                if preview {
                    index = timer.toPreviewInterval()
                } else {
                    index = timer.toNextInterval()
                }
                resetAnimateProgress()
            }, longPressAction: { isPress in
                isPaused = isPress
            })
    }
    
    private func setTimer(for state: StackPageState) {
        switch state {
        case .isShowing:
            isPaused = false
            setTimer()
            timer.start()
        case .hidden:
            isPaused = true
            timer.stop()
            timer.resetCurentInterval()
        case .inSwiped:
            isPaused = true
            timer.stop()
        default: break
        }
    }
    
    private func setTimer() {
        timer.onReachedEnd = { onReached(.end) }
        timer.onReachedStart = { onReached(.start) }
    }
    
    private func onChangeIndex(_ next: Int) {
        guard hasNext, next != index else { return }
        index = next
    }
        
    private func resetAnimateProgress() {
        Task {
            try? await Task.sleep(for: .seconds(0.05))
            isAnimateProgress = true
        }
    }
    
    private var hasNext: Bool { index < pagesCount - 1 }
    
    private var hasPrevious: Bool { index > 0 }
    
    public enum Direction {
        case forward
        case backward
    }
    
    private var topHeader: some View {
        progressContent(StoryProgressView(timer: timer, isAnimateProgress: isAnimateProgress))
    }
}

public enum PageReachedDirection {
    case start
    case end
}

extension StoryPageGroupView.Direction {
    var transition: AnyTransition {
        switch self {
        case .forward:
            return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .backward:
            return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        }
    }
}


#Preview {
    
    TestView()
    
}


struct TestView: View {
    let group = AnyStoryGroup(pages: [TestPage2(num: 1), TestPage(num: 2), TestPage(num: 3)])
    var body: some View {
        StoryPageGroupView(group: group, onReached: {_ in}) { progressView in
            VStack {
                progressView
                    .style(height: 6, fillColor: .black, backgroundColor: .white.opacity(0.1), itemsSpacing: 2)
            }
            .padding()
        }
    }
    
    struct TestPage: StoryPageable {
        @Environment(\.storyInPause) var isPaused
        var duration: TimeInterval = 4
        
        let num: Int
        var id: String {
            "\(num)"
        }
        
        var content: some View {
            ZStack {
                Color.red
                    .allowsHitTesting(false)
                VStack {
                    Text("Page \(num)")
                    Button {
                        isPaused.wrappedValue.toggle()
                    } label: {
                        Text(isPaused.wrappedValue ? "Resume" : "Pause")
                    }
                    .zIndex(100)
                }
               
            }
            
        }
    }
    
    struct TestPage2: StoryPageable {
        
        var duration: TimeInterval = 2
        let num: Int
        var id: String {
            "\(num)"
        }
        
        var content: some View {
            ZStack {
                Color.green
                    .allowsHitTesting(false)
                Text("Page \(num)")
                
            }
        }
        
    }
}


public struct StoryProgressView: View {
    @ObservedObject var timer: StoriesGroupTimer
    let isAnimateProgress: Bool
    private var progressBarHeight: CGFloat = 4
    private var fillColor: Color = .white.opacity(0.9)
    private var backgroundColor: Color = .white.opacity(0.2)
    private var itemsSpacing: CGFloat = 6
    
    public init(timer: StoriesGroupTimer, isAnimateProgress: Bool) {
        self.timer = timer
        self.isAnimateProgress = isAnimateProgress
    }
    
    public var body: some View {
        HStack(spacing: itemsSpacing) {
            ForEach(timer.timeIntervals.indices, id: \.self) { index in
                let progress = timer.relativeProgress(for: index)
                TimerBar(fillColor: fillColor,
                         backgroundColor: backgroundColor,
                         progress: progress,
                         isAnimate: isAnimateProgress)
                .frame(height: progressBarHeight)
            }
        }
    }
    
    public func style(height: CGFloat = 4,
                      fillColor: Color = .blue,
                      backgroundColor: Color = .white,
                      itemsSpacing: CGFloat = 6) -> Self {
        var copy = self
        copy.backgroundColor = backgroundColor
        copy.fillColor = fillColor
        copy.progressBarHeight = height
        copy.itemsSpacing = itemsSpacing
        return copy
    }
    
    private struct TimerBar: View {
        let fillColor: Color
        let backgroundColor: Color
        let progress: CGFloat
        let isAnimate: Bool
        var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .foregroundColor(backgroundColor)
                    Capsule()
                        .frame(width: proxy.size.width * progress, alignment: .leading)
                        .foregroundColor(fillColor)
                        .opacity(!isAnimate && progress < 0.1 ? 0 : 1)
                        .animation(.linear(duration: isAnimate ? 0.2 : 0.01), value: progress)
                }
            }
        }
    }
}

private struct TapAndLongPressModifier: ViewModifier {
    @State private var isStillPressing: Bool = false
    let tapAction: (()->())
    let longPressAction: ((Bool)->())
    func body(content: Content) -> some View {
        content
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged({ _ in
                    isStillPressing = true
                    Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        if isStillPressing {
                            longPressAction(true)
                        }
                    }
                }).onEnded({ _ in
                    isStillPressing = false
                    longPressAction(false)
                }))
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        tapAction()
                    }
            )
    }
}

private extension View {
    
    func onTapAndLongPress(tapAction: @escaping () -> Void,
                           longPressAction: @escaping (Bool) -> Void) -> some View {
        self
            .modifier(TapAndLongPressModifier(tapAction: tapAction, longPressAction: longPressAction))
    }
}
