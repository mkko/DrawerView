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

    var offset: CGFloat = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
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
            offset = 0.0
            //self.originScrollView = nil
            break
        case .changed:
            let translation = sender.translation(in: self)
            // If scrolling upwards a scroll view, ignore the events.
            if let childScrollView = self.originScrollView {
                if childScrollView.contentOffset.y < 0 {
                    self.transform = CGAffineTransform(translationX: 0, y: translation.y)
                    offset = offset + childScrollView.contentOffset.y
                    childScrollView.contentOffset.y = 0
//                    let o = sv.contentOffset
//                    o.y = 0
//                    sv.contentOffset = o
                } else if childScrollView.contentOffset.y > 0 && offset < 0 {
                    offset = offset + childScrollView.contentOffset.y

                    if offset > 0 {
                        print("<, \(offset)")
                        childScrollView.contentOffset.y = offset
                        offset = 0
                        self.transform = CGAffineTransform(translationX: 0, y: translation.y - offset)
                    } else {
                        childScrollView.contentOffset.y = 0
                        self.transform = CGAffineTransform(translationX: 0, y: translation.y)
                    }
                }
                print("offset: \(offset)")
            } else {
                //self.center = CGPoint(x: self.center.x , y: self.center.y + translation.y)
                self.transform = CGAffineTransform(translationX: 0, y: translation.y)
                //                sender.setTranslation(CGPoint.zero, in: self)
            }
            //print("c: \(self.center)")
            print("t.y: \(translation.y)")
        case .ended:
            fallthrough
        case.failed:
            print("sender.state: \(sender.state.rawValue)")
            self.originScrollView = nil
            UIView.animate(withDuration: 0.2, animations: {
                self.transform = CGAffineTransform.identity
                //print("c: \(self.center)")
                //self.transform = CGAffineTransform(translationX: 0, y: 0)
            }, completion: { _ in
                //print("c: \(self.center)")
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
            self.originScrollView = sv
        }
        return true
    }

    //gestureRecognizer
}

