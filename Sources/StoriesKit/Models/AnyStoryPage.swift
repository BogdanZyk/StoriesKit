//
//  AnyStoryPage.swift
//  StoriesKit
//

import SwiftUI

/// A type-erased implementation of the `StoryPageable` protocol.
/// This struct allows you to work with heterogeneous `StoryPageable` conforming types in a uniform way.
@MainActor
public struct AnyStoryPage: StoryPageable {
    
    /// The duration for which the page should be displayed.
    public var duration: TimeInterval
    
    /// The view content of the page, type-erased to `AnyView`.
    private var view: AnyView
    
    /// A unique identifier for the page.
    public var id: String
    
    /// Creates an instance of `AnyStoryPage` by wrapping a given `StoryPageable` instance.
    /// - Parameter page: The page to be type-erased and stored.
    public init<Page: StoryPageable>(_ page: Page) {
        self.view = AnyView(page)
        self.id = page.id
        self.duration = page.duration
    }
    
    public var content: AnyView {
        view
    }
    
    public var body: AnyView {
        view
    }
}

extension AnyStoryPage {
    
    static func makePages(_ pages: [any StoryPageable]) -> [AnyStoryPage] {
        return pages.map { AnyStoryPage($0) }
    }
    
}
