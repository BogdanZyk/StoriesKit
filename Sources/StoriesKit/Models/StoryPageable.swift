//
//  StoryPageable.swift
//  StoriesKit
//

import SwiftUI

/// A protocol representing a page within a story page view component.
/// Conforming types must define the page's unique identifier, its duration,
/// and the content to be displayed.
@MainActor
public protocol StoryPageable: View {
    
    /// The type of the content displayed by the page.
    associatedtype ContentType: View
    
    /// A unique identifier for the page.
    var id: String { get }
    
    /// The duration for which the page should be displayed.
    var duration: TimeInterval { get }
    
    /// The view content to be displayed on the page.
    @ViewBuilder var content: ContentType { get }
}

/// Default implementation of the `StoryPageable` protocol.
public extension StoryPageable {
    
    /// Provides a default identifier for the page, based on the type's name.
    var id: String {
        String(describing: Self.self)
    }
    
    /// Uses the page's content as the body of the view.
    var body: some View {
        self.content
    }
}
