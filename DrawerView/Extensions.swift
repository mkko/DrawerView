//
//  Extensions.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 2018-02-04.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import Foundation
import UIKit

public extension UIViewController {

    func addDrawerView(withViewController viewController: UIViewController, parentView: UIView? = nil) -> DrawerView {
        #if swift(>=4.2)
        self.addChild(viewController)
        #else
        self.addChildViewController(viewController)
        #endif
        let drawer = DrawerView(withView: viewController.view)
        drawer.attachTo(view: self.view)
        return drawer
    }
}


