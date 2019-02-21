//
//  Interpolation.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 2018-03-10.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import Foundation

internal func interpolate<T: FloatingPoint>(values: [(position: T, value: T)], position: T) -> T {

    let sorted = values.sorted { (p1, p2) -> Bool in p1.position < p2.position }

    let prev = sorted.last(where: { $0.position <= position })
    let next = sorted.first(where: { $0.position > position })

    if let a = prev, let b = next {
        let n = (position - a.position) / (b.position - a.position)
        return a.value + (b.value - a.value) * n
    } else if let a = prev ?? next {
        return a.value
    } else {
        return 0
    }
}

fileprivate extension Array {

    func last(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return try self.filter(predicate).last
    }
}

