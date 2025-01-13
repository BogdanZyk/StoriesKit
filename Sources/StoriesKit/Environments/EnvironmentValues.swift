//
//  EnvironmentValues.swift
//  StoriesKit
//

import SwiftUI

private struct StoryPauseEnvironmentKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: Binding<Bool> = .constant(false)
}

private struct StackPageStateEnvironmentKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: [AnyHashable: StackPageState] = [:]
}

public extension EnvironmentValues {
    
    /// A dictionary storing the state of each stack page in a paged view.
    /// - The key is a hashable identifier for a page.
    /// - The value is the corresponding `StackPageState` for that page.
    var stackPageState: [AnyHashable: StackPageState] {
        get {
            self[StackPageStateEnvironmentKey.self]
        }
        set {
            self[StackPageStateEnvironmentKey.self] = newValue
        }
    }
    
    /// A binding to a Boolean value indicating whether a story is currently paused.
    /// - `true`: The story timer is paused.
    /// - `false`: The story timer is playing.
    var storyInPause: Binding<Bool> {
        get {
            self[StoryPauseEnvironmentKey.self]
        }
        set {
            self[StoryPauseEnvironmentKey.self] = newValue
        }
    }
}
