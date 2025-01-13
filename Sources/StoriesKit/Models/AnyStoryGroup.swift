//
//  AnyStoryGroup.swift
//  StoriesKit
//

import SwiftUI

/// A type representing a group of story pages, uniquely identifiable and associated with a timer.
/// This struct provides a way to group and manage story pages and their durations.
@MainActor
public struct AnyStoryGroup: Identifiable {
    
    /// A unique identifier for the story group.
    public let id: String
    
    /// The collection of story pages in the group, type-erased to `AnyStoryPage`.
    public let pages: [AnyStoryPage]
    
    /// A timer associated with the group, managing the durations of each page.
    public let timer: StoriesGroupTimer
    
    /// Initializes a story group with an array of `StoryPageable` pages.
    /// - Parameters:
    ///   - pages: An array of `StoryPageable` conforming objects.
    ///   - id: A unique identifier for the group. Defaults to a randomly generated UUID string.
    public init(pages: [any StoryPageable], id: String = UUID().uuidString) {
        self.pages = AnyStoryPage.makePages(pages)
        self.id = id
        self.timer = .init(timeIntervals: pages.map(\.duration))
    }
    
    /// Initializes a story group with an array of `AnyStoryPage` pages.
    /// - Parameters:
    ///   - pages: An array of `AnyStoryPage` instances.
    ///   - id: A unique identifier for the group. Defaults to a randomly generated UUID string.
    public init(pages: [AnyStoryPage], id: String = UUID().uuidString) {
        self.pages = pages
        self.id = id
        self.timer = .init(timeIntervals: pages.map(\.duration))
    }
}
