//
//  Overlay.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 04/01/2018.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import UIKit

class Overlay: UIView {

    public var cutCornerSize: CGFloat = 0 {
        didSet {
            cutCornerSizeConstraint?.constant = max(cutCornerSize, 0)
        }
    }

    override var backgroundColor: UIColor? {
        didSet {
            leftCut.backgroundColor = self.backgroundColor
            rightCut.backgroundColor = self.backgroundColor
        }
    }

    private let leftCut = CutCornerView(type: .left, frame: CGRect())

    private let rightCut = CutCornerView(type: .right, frame: CGRect())

    private var cutCornerSizeConstraint: NSLayoutConstraint? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        leftCut.translatesAutoresizingMaskIntoConstraints = false

        leftCut.backgroundColor = self.backgroundColor
        rightCut.backgroundColor = self.backgroundColor

        leftCut.translatesAutoresizingMaskIntoConstraints = false
        rightCut.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(leftCut)
        self.addSubview(rightCut)

        let c: CGFloat = 50

        let h = leftCut.heightAnchor.constraint(equalToConstant: c)
        cutCornerSizeConstraint = h

        let constraints = [
            leftCut.topAnchor.constraint(equalTo: self.bottomAnchor),
            leftCut.leftAnchor.constraint(equalTo: self.leftAnchor),
            h,
            leftCut.widthAnchor.constraint(equalTo: leftCut.heightAnchor),

            rightCut.topAnchor.constraint(equalTo: self.bottomAnchor),
            rightCut.rightAnchor.constraint(equalTo: self.rightAnchor),
            rightCut.heightAnchor.constraint(equalTo: leftCut.heightAnchor),
            rightCut.widthAnchor.constraint(equalTo: leftCut.heightAnchor)
        ]

        for c in constraints {
            c.isActive = true
        }

        self.clipsToBounds = false
    }

}
