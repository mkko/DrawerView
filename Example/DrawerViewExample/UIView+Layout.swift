//
//  UIView+Layout.swift
//
//  Created by Mikko Välimäki on 2018-06-27.
//

import UIKit

enum UIViewEdge {
    case top(margin: CGFloat)
    case bottom(margin: CGFloat)
    case leading(margin: CGFloat)
    case trailing(margin: CGFloat)
}

extension UIViewEdge: Equatable {}

extension UIView {

    func autoPinEdgesToSuperview(margin: CGFloat = 0) {
        autoPinToSuperview(edges: [
            .top(margin: margin),
            .bottom(margin: margin),
            .leading(margin: margin),
            .trailing(margin: margin)
            ])
    }

    func autoPinToSuperview(edges: [UIViewEdge]) {
        guard let superview = superview else {
            NSLog("No superview set")
            abort()
        }
        var constraints: [NSLayoutConstraint] = []
        for edge in edges {
            switch edge {
            case .top(let margin):
                constraints.append(
                    superview.topAnchor.constraint(equalTo: self.topAnchor, constant: -margin)
                )
            case .bottom(let margin):
                constraints.append(
                    superview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: margin)
                )
            case .leading(let margin):
                constraints.append(
                    superview.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -margin)
                )
            case .trailing(let margin):
                constraints.append(
                    superview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: margin)
                )
            }
        }

        NSLayoutConstraint.activate(constraints)
        superview.setNeedsLayout()
    }
}

extension UIView {
    var userAddedConstraints: [NSLayoutConstraint] {
        return constraints.filter { c in
            guard let cId = c.identifier else { return true }
            return !cId.contains("UIView-Encapsulated-Layout")
        }
    }
}
