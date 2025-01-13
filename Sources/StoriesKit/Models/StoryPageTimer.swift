//
//  StoryPageTimer.swift
//  StoriesKit
//

import Foundation
import Combine

/// A timer class designed for managing and switching through a sequence of timed intervals.
/// It tracks the progress of each interval and supports pausing, resuming, and navigating between intervals.
public final class StoriesGroupTimer: ObservableObject {
    
    /// Dictionary to store the elapsed time for each interval.
    @Published private(set) var timeDict: [Int: Double] = [:]
    
    /// Array of time intervals that the timer iterates through.
    let timeIntervals: [TimeInterval]
    
    /// Index of the currently active interval.
    private(set) var currentIntervalIndex: Int = 0
    
    /// Boolean to track whether the timer is paused.
    private var isPause: Bool = false
    
    /// Publisher used for generating periodic timer ticks.
    private var timer: Timer.TimerPublisher?
    
    /// Cancellable object to manage the timer's subscription.
    private var cancellable: Cancellable?
    
    /// Total count of intervals in the timer.
    private let intervalsCount: Int
    
    /// Callback triggered when the timer reaches the end of the intervals.
    var onReachedEnd: (() -> Void)?
    
    /// Callback triggered when the timer reaches the start of the intervals.
    var onReachedStart: (() -> Void)?

    /// The interval at which the timer ticks (default: 0.2 seconds).
    static let tickInterval = 0.2
    
    /// Initializes the timer with the given time intervals.
    /// - Parameter timeIntervals: An array of time intervals to iterate through.
    public init(timeIntervals: [TimeInterval]) {
        self.timeIntervals = timeIntervals
        self.timer = Timer.publish(every: Self.tickInterval, on: .main, in: .default)
        self.intervalsCount = timeIntervals.count
    }

    deinit {
        stop()
    }

    /// Starts the timer from the current interval.
    func start() {
        guard !timeIntervals.isEmpty else {
            onReachedEnd?()
            return
        }
        
        isPause = false
        
        startCurrentInterval()
    }
    
    /// Computes the relative progress for a specific interval.
    /// - Parameter index: The index of the interval.
    /// - Returns: The progress of the interval as a value between 0 and 1.
    func relativeProgress(for index: Int) -> Double {
        guard index < timeIntervals.count else { return 0 }

        if index > currentIntervalIndex {
            return 0
        } else if index < currentIntervalIndex {
            return 1
        } else {
            return min(timeDict[index, default: 0] / timeIntervals[index], 1.0)
        }
    }
    
    /// Starts the timer for the current interval.
    private func startCurrentInterval() {
        guard currentIntervalIndex <= intervalsCount - 1 else {
            onReachedEnd?()
            stop()
            return
        }

        cancellable = nil
        let currentIntervalTime = timeIntervals[currentIntervalIndex]
        
        cancellable = timer?.autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !isPause else { return }
                
                self.timeDict[currentIntervalIndex, default: 0] += Self.tickInterval

                if self.timeDict[currentIntervalIndex, default: 0] >= currentIntervalTime {
                    let nextIntervalIndex = currentIntervalIndex + 1

                    if nextIntervalIndex <= self.intervalsCount - 1 {
                        toNextInterval()
                    } else {
                        self.onReachedEnd?()
                        self.stop()
                    }
                }
            }
    }

    /// Stops the timer and cleans up resources.
    func stop() {
        timer?.connect().cancel()
        cancellable?.cancel()
        cancellable = nil
    }
    
    /// Pauses the timer.
    func pause() {
        isPause = true
    }
    
    /// Resumes the timer.
    func resume() {
        isPause = false
    }
    
    /// Resets the elapsed time for the current interval.
    func resetCurentInterval() {
        timeDict[currentIntervalIndex] = 0
    }

    /// Advances the timer to the next interval.
    @discardableResult
    func toNextInterval() -> Int {
        stop()
        let nextIndex = currentIntervalIndex + 1
        let timeInterval = timeIntervals[currentIntervalIndex]
        let currentTime = timeDict[currentIntervalIndex] ?? 0
        
        timeDict[currentIntervalIndex] = min(currentTime + timeInterval, timeInterval)
        
        if nextIndex > timeIntervals.count - 1 {
            timeDict[currentIntervalIndex] = timeInterval
            onReachedEnd?()
            stop()
            return currentIntervalIndex
        } else {
            currentIntervalIndex = nextIndex
        }
        startCurrentInterval()
        
        return nextIndex
    }
    
    /// Moves the timer to the previous interval or resets it based on elapsed time.
    func toPreviewInterval() -> Int {
        stop()
        let previewIndex = currentIntervalIndex - 1
        
        if previewIndex < 0 {
            currentIntervalIndex = 0
            timeDict.removeAll()
            onReachedStart?()
            stop()
            return currentIntervalIndex
        } else {
            timeDict[currentIntervalIndex] = 0
            timeDict[previewIndex] = 0
            currentIntervalIndex = previewIndex
            self.startCurrentInterval()
            return previewIndex
        }
    }
}
