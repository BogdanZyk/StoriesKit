//
//  StackPageState.swift
//  StoriesKit
//

import Foundation

/// An enumeration representing the state of a stack page within a paged view.
public enum StackPageState: String {
    
    /// The page is currently visible and being displayed.
    case isShowing
    
    /// The page is in a transitional state before switching to a new page.
    case beforeSwitch
    
    /// The page is located during a swipe
    case inSwiped
    
    /// The page is hidden and not currently visible.
    case hidden
}
