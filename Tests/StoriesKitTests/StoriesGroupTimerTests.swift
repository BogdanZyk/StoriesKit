//
//  StoriesGroupTimerTests.swift
//  StoriesKit
//

import Testing
@testable import StoriesKit
import Foundation

struct StoriesGroupTimerTests {

    @Test func testInitialization() {
        let timer = StoriesGroupTimer(timeIntervals: [10, 20, 30])
        #expect(timer.timeIntervals == [10, 20, 30])
        #expect(timer.currentIntervalIndex == 0)
        #expect(timer.timeDict.isEmpty)
    }

    @Test func testStartEmptyIntervals() {
        
        let timer = StoriesGroupTimer(timeIntervals: [])
        var didReachEnd = false
        
        timer.onReachedEnd = { didReachEnd = true }
        timer.start()
        
        #expect(didReachEnd)
    }
    
    @Test func testPauseAndResume() {
        let timer = StoriesGroupTimer(timeIntervals: [10])
        
        timer.start()
        timer.pause()
        #expect(timer.relativeProgress(for: 0) < 1.0)
        #expect(timer.isPause)
        
        timer.resume()
        #expect(!timer.isPause)
        #expect(timer.relativeProgress(for: 0) == 0)
    }
    
    @Test func testToNextInterval() {
        let timeIntervals: [TimeInterval] = [5, 10, 15]
        let timer = StoriesGroupTimer(timeIntervals: timeIntervals)
        
        timer.start()
        let nextIndex = timer.toNextInterval()
        
        #expect(timer.relativeProgress(for: nextIndex) == 0)
        #expect(nextIndex == 1)
        #expect(timeIntervals[nextIndex] == timeIntervals[1])
    }
    
    @Test func testToPreviousInterval() {
        let timeIntervals: [TimeInterval] = [5, 10, 15]
        let timer = StoriesGroupTimer(timeIntervals: timeIntervals)
        
        timer.start()
        timer.toNextInterval()
        let previousIndex = timer.toPreviewInterval()
        
        #expect(previousIndex == 0)
        #expect(timer.relativeProgress(for: previousIndex) == 0)
        #expect(timer.relativeProgress(for: previousIndex + 1) == 0)
        #expect(timer.currentIntervalIndex == 0)
        #expect(timeIntervals[previousIndex] == timeIntervals[0])
    }
    
    @Test func testResetCurrentInterval() {
        let timer = StoriesGroupTimer(timeIntervals: [5, 10, 15])
        
        timer.start()
        timer.resetCurentInterval()
        
        #expect(timer.currentIntervalIndex == 0)
        #expect(timer.relativeProgress(for: 0) == 0)
    }
    
    @Test func testRelativeProgress() async {
        let interval: TimeInterval = 3
        let timer = StoriesGroupTimer(timeIntervals: [interval])
        
        timer.start()
        #expect(timer.relativeProgress(for: 0) == 0)
        
        try? await Task.sleep(for: .seconds(2))
        #expect(timer.relativeProgress(for: 0) == 2 / interval)
    }
    
    @Test func testEndReached() async {
        let timer = StoriesGroupTimer(timeIntervals: [1])
        var didReachEnd = false
        
        timer.onReachedEnd = { didReachEnd = true }
        timer.start()
        
        try? await Task.sleep(for: .seconds(2))
        
        #expect(didReachEnd)
    }
    
    @Test func testStartReached() async {
        let timer = StoriesGroupTimer(timeIntervals: [2, 3])
        var didReachStart = false
        
        timer.onReachedStart = { didReachStart = true }
        timer.start()
        let previewIndex = timer.toPreviewInterval()
        
        #expect(previewIndex == timer.currentIntervalIndex )
        #expect(timer.currentIntervalIndex == 0)
        #expect(didReachStart)
    }
    
    @Test func testCompleteAllIntervals() async {
        let timeIntervals: [TimeInterval] = [1, 1, 1]
        let timer = StoriesGroupTimer(timeIntervals: timeIntervals)
        var didReachEnd = false
        
        timer.onReachedEnd = { didReachEnd = true }
        timer.start()
        
        for index in 0..<timeIntervals.count {
            #expect(timer.currentIntervalIndex == index)
            try? await Task.sleep(for: .seconds(timeIntervals[index]))
            #expect(timer.relativeProgress(for: index) == 1.0)
        }
        
        #expect(didReachEnd)
    }
    
    @Test func testPausePreservesProgress() async {
        let interval: TimeInterval = 5
        let timer = StoriesGroupTimer(timeIntervals: [interval])
        
        timer.start()
        try? await Task.sleep(for: .seconds(0.5))
        timer.pause()
        #expect(timer.isPause)
        
        let progress = timer.relativeProgress(for: 0)
        try? await Task.sleep(for: .seconds(1))
        timer.resume()
        #expect(!timer.isPause)
        #expect(timer.relativeProgress(for: 0) == progress)
    }
}
