//
//  CutCornerView.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 23/01/2018.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import UIKit

enum CutOutType {
    case left
    case right
}

internal class CutCornerView: UIView {

    private var _mask = CAShapeLayer()

    private var type: CutOutType

    init(type: CutOutType, frame: CGRect) {
        self.type = type
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Drawing

    override func layoutSubviews() {
        let path = CGMutablePath()

        _mask.frame = self.bounds

        var clipping = self.bounds
        if type == .right {
            clipping.origin = CGPoint(x: -clipping.width, y: 0)
        }
        clipping.size = CGSize(width: clipping.width * 2, height: clipping.height * 2)

        path.addRect(self.bounds)
        path.addEllipse(in: clipping)

        _mask.path = path
        #if swift(>=4.2)
        _mask.fillRule = .evenOdd
        #else
        _mask.fillRule = kCAFillRuleEvenOdd
        #endif

        self.layer.mask = _mask
    }
}
