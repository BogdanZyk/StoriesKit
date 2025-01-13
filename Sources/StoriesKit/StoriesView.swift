//
//  StoriesView.swift
//  StoriesKit
//

import SwiftUI

/// `StoriesView` is a customizable view for displaying story groups in a stacked, paginated interface.
/// It supports animations, swipe gestures, long gesture and customizable styles
public struct StoriesView: View {
    
    /// A collection of story groups to display.
    private let groups: [AnyStoryGroup]

    /// The current index of the displayed story group.
    @State private var currentIndex: Int = 0
    
    /// An external binding to synchronize the current index with an external source.
    @Binding private var externalIndex: Int
    
    /// A callback triggered when all stories in all groups are reached.
    private var onReachedAllStories: ((PageReachedDirection) -> Void)?
    
    /// A callback triggered when a story group is completed.
    private var onEndGroup: ((AnyStoryGroup) -> Void)?
    
    /// A closure to customize the appearance of the progress bar for each story group.
    private var makeProgressView: ((StoryProgressView, AnyStoryGroup) -> AnyView)?
    
    /// The visual style configuration for story cards.
    private var style = StoryCardStyle()

    /// Creates a `StoriesView` with a given array of story groups.
    ///
    /// - Parameters:
    ///   - groups: The story groups to display.
    ///   - startIndex: The initial index to display. Defaults to 0.
    public init(groups: [AnyStoryGroup], startIndex: Int = 0) {
        self.groups = groups
        self._externalIndex = .constant(startIndex)
        self._currentIndex = .init(initialValue: startIndex)
    }

    public var body: some View {
        StackPagesView(views: groups, initPage: currentIndex) { group in
            StoryPageGroupView(group: group, onReached: { onReachedGroup($0, group: group) }) { progressView in
                Group {
                    if let makeProgressView {
                        makeProgressView(progressView, group)
                    } else {
                        progressView
                    }
                }
            }
        }
        .swipeThreshold(style.swipeThreshold)
        .slideDuration(style.animationDuration)
        .cardStyle(radius: style.cornerRadius, scaleFactor: style.scaleFactor)
        .opacityOverlay(style.opacityOverlay)
        .onChangeIndex($currentIndex)
        .onReachedEnd(onReachedAllStories)
        .onChange(of: externalIndex) {
            setCurrentIndex($0)
        }
        .onChange(of: currentIndex) {
            setExternalIndex($0)
        }
    }
}

extension StoriesView {
    
    /// Handles navigation when a story group is reached.
    private func onReachedGroup(_ direction: PageReachedDirection, group: AnyStoryGroup) {
        let newIndex = direction == .end ? currentIndex + 1 : currentIndex - 1

        if newIndex > currentIndex {
            onEndGroup?(group)
        }

        currentIndex = direction == .end ? min(newIndex, groups.count - 1) : max(0, newIndex)

        if newIndex < 0 {
            onReachedAllStories?(.start)
        } else if newIndex >= groups.count {
            onReachedAllStories?(.end)
        }
    }

    /// Converts `StackSwipeDirection` to `PageReachedDirection` and invokes the callback.
    private func onReachedAllStories(_ direction: StackSwipeDirection) {
        onReachedAllStories?(direction == .next ? .end : .start)
    }

    /// Synchronizes the external index with the internal state.
    private func setExternalIndex(_ newIndex: Int) {
        guard newIndex != externalIndex else { return }
        externalIndex = newIndex
    }

    /// Synchronizes the internal state with the external index.
    private func setCurrentIndex(_ newIndex: Int) {
        guard newIndex != currentIndex else { return }
        currentIndex = newIndex
    }
}

extension StoriesView {
    
    /// Allows customization of the progress bar for story groups.
    ///
    /// - Parameter view: A closure providing a custom `View` for the progress bar.
    /// - Returns: A modified `StoriesView` with the custom progress bar.
    public func makeProgressBar<Content: View>(@ViewBuilder _ view: @escaping (StoryProgressView, AnyStoryGroup?) -> Content) -> Self {
        var copy = self
        copy.makeProgressView = { AnyView(view($0, $1)) }
        return copy
    }

    /// Configures the visual style of the story cards.
    ///
    /// - Parameter style: A `StoryCardStyle` instance defining the visual appearance.
    /// - Returns: A modified `StoriesView` with the new style.
    public func style(_ style: StoryCardStyle) -> Self {
        var copy = self
        copy.style = style
        return copy
    }

    /// Adds a callback to be invoked when all stories are reached.
    ///
    /// - Parameter action: A closure triggered when reaching the start or end.
    /// - Returns: A modified `StoriesView` with the callback set.
    public func onReachedAllStories(_ action: @escaping (PageReachedDirection) -> Void) -> Self {
        var copy = self
        copy.onReachedAllStories = action
        return copy
    }

    /// Adds a callback to be invoked when a story group is completed.
    ///
    /// - Parameter action: A closure triggered at the end of a group.
    /// - Returns: A modified `StoriesView` with the callback set.
    public func onEndGroup(_ action: @escaping (AnyStoryGroup) -> Void) -> Self {
        var copy = self
        copy.onEndGroup = action
        return copy
    }

    /// Binds the external index to synchronize the current group index.
    ///
    /// - Parameter currentIndex: A binding to the external index.
    /// - Returns: A modified `StoriesView` with the binding set.
    public func onChangeGroupIndex(_ currentIndex: Binding<Int>) -> Self {
        var copy = self
        copy._externalIndex = currentIndex
        return copy
    }
}

extension StoriesView {
    
    /// Represents the visual style configuration for story cards.
    public struct StoryCardStyle {
        
        /// The corner radius of the story cards.
        var cornerRadius: CGFloat
        
        /// The scale factor applied to the story cards during swipe gestures.
        var scaleFactor: CGFloat
        
        /// The opacity of the background overlay.
        var opacityOverlay: Double
        
        /// The animation duration for transitions.
        var animationDuration: CGFloat
        
        /// The swipe threshold to trigger a page change.
        var swipeThreshold: CGFloat

        /// Initializes a `StoryCardStyle` with optional parameters.
        ///
        /// - Parameters:
        ///   - cornerRadius: The corner radius of the story cards. Default is 20.
        ///   - scaleFactor: The scale factor for swipe gestures. Default is 0.9.
        ///   - opacityOverlay: The opacity of the overlay. Default is 0.2.
        ///   - animationDuration: The duration of animations. Default is 0.35 seconds.
        ///   - swipeThreshold: The swipe threshold to change pages. Default is 0.1.
        public init(cornerRadius: CGFloat = 20,
                    scaleFactor: CGFloat = 0.9,
                    opacityOverlay: Double = 0.2,
                    animationDuration: CGFloat = 0.35,
                    swipeThreshold: CGFloat = 0.1) {
            self.cornerRadius = cornerRadius
            self.scaleFactor = scaleFactor
            self.opacityOverlay = opacityOverlay
            self.animationDuration = animationDuration
            self.swipeThreshold = swipeThreshold
        }
    }
}

#Preview {
    
    struct TestView2: View {
        @State var index: Int = 0
        let groups: [AnyStoryGroup] = [
            
            .init(pages: (0...1).map({StoryPage(name: "\($0)")})),
            .init(pages: (0...5).map({StoryPage(name: "\($0)")})),
            .init(pages: (0...4).map({StoryPage(name: "\($0)")})),
            .init(pages: (0...6).map({StoryPage(name: "\($0)")})),
        ]
        var body: some View {
            StoriesView(groups: groups, startIndex: index)
                .style(.init(cornerRadius: 30, scaleFactor: 0.95, opacityOverlay: 0.1, animationDuration: 0.35))
                .makeProgressBar { progress, group in
                    progress
                        .padding()
                }
                .onChangeGroupIndex($index)
                .onEndGroup { group in
                    print("onEndGroup", group.id)
                }
                .onReachedAllStories {
                    print("onReachedAllStories", $0)
                }
                
        }
        
        struct StoryPage: StoryPageable {
            
            var duration: TimeInterval = 5
            
            let name: String
            
            var id: String { name }
            
            var content: some View {
                ZStack {
                    Color.yellow
                        .allowsHitTesting(false)
                    VStack {
                        Text(name)
                        Button("Button") {
                            print("send")
                        }
                    }
                }
            }
        }
    }
    
    return TestView2()
}
