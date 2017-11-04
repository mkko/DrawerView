//
//  DrawerView.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 28/10/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit

class DrawerView: UIView {

    var panGesture: UIPanGestureRecognizer! = nil

    var originScrollView: UIScrollView? = nil
    var otherGestureRecognizer: UIGestureRecognizer? = nil

    var _offset: CGFloat = 0.0

    var topOrigin: CGFloat = 0.0

    var scrollViewOffset: CGFloat = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    override func layoutSubviews() {
        topOrigin = self.frame.minY
    }

    private func setup() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }


    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            scrollViewOffset = 0.0
            break
        case .changed:
            let translation = sender.translation(in: self)
            sender.setTranslation(CGPoint.zero, in: self)
            _offset = _offset + translation.y
            let offset = max(_offset, 0)

            // If scrolling upwards a scroll view, ignore the events.
            if let childScrollView = self.originScrollView {
                if childScrollView.contentOffset.y < 0 {
                    // Scrolling downwards and content was consumed, disable child scrolling
                    childScrollView.isScrollEnabled = false
                    childScrollView.contentOffset.y = 0
                }

                if !childScrollView.isScrollEnabled || childScrollView.contentOffset.y <= 0 {
                    self.frame.origin.y = topOrigin + offset
                }
                print("scrollViewOffset: \(scrollViewOffset)")

            }
        case .ended:
            fallthrough
        case.failed:
            print("sender.state: \(sender.state.rawValue)")
            self.originScrollView?.isScrollEnabled = true
            self.originScrollView = nil
            _offset = 0

            // Add extra height to make sure that bottom doesn't show up.
            let originalHeight = self.frame.size.height
            self.frame.size.height = self.frame.size.height * 1.5

            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: [], animations: {
                self.frame.origin.y = self.topOrigin
            }, completion: { (completed) in
                self.frame.size.height = originalHeight
            })
        default:
            break
        }

    }
}

extension DrawerView: UIGestureRecognizerDelegate {

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        //        print("gestureRecognizer:shouldRecognizeSimultaneouslyWith:\(otherGestureRecognizer)")
        if let sv = otherGestureRecognizer.view as? UIScrollView {
            self.otherGestureRecognizer = otherGestureRecognizer
            self.originScrollView = sv
        }
        return true
    }
}

