//
//  Extensions.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 04/02/2018.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import Foundation

public extension UIViewController {

    public func addDrawerView(withViewController viewController: UIViewController, parentView: UIView? = nil) -> DrawerView {
        self.addChildViewController(viewController)
        let drawer = DrawerView(withView: viewController.view)
        drawer.attachTo(view: self.view)
        return drawer
    }
}


