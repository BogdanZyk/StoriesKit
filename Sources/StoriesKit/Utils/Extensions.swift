//
//  Extensions.swift
//  StoriesKit
//

import Foundation

extension Array {
    func isIndexValid(index: Index) -> Bool {
        return self.endIndex > index && self.startIndex <= index
    }
}

extension RandomAccessCollection {
    subscript(elementOrNil index: Index)-> Element? {
        if indices.contains(index), !self.isEmpty {
            return self[index]
        }else {
            return nil
        }
    }
}
