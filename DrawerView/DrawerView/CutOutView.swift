//
//  CutOutView.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 04/01/2018.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import UIKit

class CutOutView: UIView {

    public var bottomCutHeight: CGFloat = 0

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let layer = CAShapeLayer()
        let path = CGMutablePath()

        let clipping = CGRect(x: 0,
                              y: self.bounds.height - bottomCutHeight,
                              width: self.bounds.width,
                              height: bottomCutHeight * 2)
        path.addRoundedRect(in: clipping,
                            cornerWidth: bottomCutHeight,
                            cornerHeight: bottomCutHeight)
        path.addRect(self.bounds)

        layer.path = path

        layer.fillRule = kCAFillRuleEvenOdd
        self.layer.mask = layer
    }
}
