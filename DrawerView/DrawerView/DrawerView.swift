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

    var _offset: CGFloat = 0.0

    var yOrigin: CGFloat = 0.0

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
        yOrigin = self.center.y
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
            //self.originScrollView = nil
            break
        case .changed:
            let translation = sender.translation(in: self)
            sender.setTranslation(CGPoint.zero, in: self)
            _offset = _offset + translation.y
            let offset = max(_offset, 0)

            // If scrolling upwards a scroll view, ignore the events.
            if let childScrollView = self.originScrollView {
                if childScrollView.contentOffset.y < 0 {
                    //self.transform = CGAffineTransform(translationX: 0, y: translation.y)
                    self.center.y = yOrigin + offset
                    scrollViewOffset = scrollViewOffset + childScrollView.contentOffset.y
                    childScrollView.contentOffset.y = 0
//                    let o = sv.contentOffset
//                    o.y = 0
//                    sv.contentOffset = o
                } else if childScrollView.contentOffset.y > 0 && scrollViewOffset < 0 {
                    scrollViewOffset = scrollViewOffset + childScrollView.contentOffset.y
                    self.center.y = yOrigin + offset

                    if scrollViewOffset > 0 {
                        print("<, \(scrollViewOffset)")
                        childScrollView.contentOffset.y = scrollViewOffset
                        scrollViewOffset = 0
                        //self.transform = CGAffineTransform(translationX: 0, y: translation.y - scrollViewOffset)
                    } else {
                        childScrollView.contentOffset.y = 0
                        //self.transform = CGAffineTransform(translationX: 0, y: translation.y)
                    }
                }
                print("scrollViewOffset: \(scrollViewOffset)")

            } else {
                //self.center = CGPoint(x: self.center.x , y: self.center.y + translation.y)
                //self.transform = CGAffineTransform(translationX: 0, y: translation.y)
                //                sender.setTranslation(CGPoint.zero, in: self)
            }

            //print("c: \(self.center)")
            print("offset: \(offset)")
        case .ended:
            fallthrough
        case.failed:
            print("sender.state: \(sender.state.rawValue)")
            self.originScrollView = nil
            _offset = 0
            UIView.animate(withDuration: 0.2, animations: {
//                self.transform = CGAffineTransform.identity
                self.center.y = self.yOrigin
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

