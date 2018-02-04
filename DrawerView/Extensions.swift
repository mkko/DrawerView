//
//  Extensions.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 04/02/2018.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import Foundation

public extension UIViewController {

    public var drawer: DrawerView? {
        return findParentDrawerView(view: self.view)
    }
}

private func findParentDrawerView(view: UIView?) -> DrawerView? {
    switch view?.superview {
    case .none:
        return nil
    case .some(let parent):
        return parent as? DrawerView ?? findParentDrawerView(view: view)
    }
}
