//
//  ViewController.swift
//  UIViewPropertyAnimatorTest
//
//  Created by Mikko Välimäki on 16/01/2018.
//  Copyright © 2018 Mikko Välimäki. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var top: NSLayoutConstraint!

    @IBOutlet weak var box: UIView!

    private var panRecognizer: UIPanGestureRecognizer! = nil

    private var animator: UIViewPropertyAnimator? = nil

    private var panOrigin: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        panRecognizer.maximumNumberOfTouches = 2
        panRecognizer.minimumNumberOfTouches = 1
        self.view.addGestureRecognizer(panRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc private func onPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            self.animator?.stopAnimation(true)
            let frame = box.layer.presentation()?.frame ?? box.frame
            self.panOrigin = frame.origin.y

        case .changed:
            let translation = sender.translation(in: self.view)
            let pos = panOrigin + translation.y
            self.top.constant = pos

        case.failed:
            print("ERROR: UIPanGestureRecognizer failed")
            fallthrough

        case .ended:
            let velocity = sender.velocity(in: self.box)

            let h = self.view.bounds.height - 240

            let nextPos: CGFloat
            if velocity.y < 0 {
                nextPos = 0
            } else if velocity.y > 0 {
                nextPos = h
            } else {
                nextPos = 0
            }

            let m: CGFloat = 100.0
            let velocityVector = CGVector(dx: 0, dy: abs(velocity.y) / m);
            let springParameters = UISpringTimingParameters(dampingRatio: 0.8, initialVelocity: velocityVector)

            self.animator = UIViewPropertyAnimator(duration: 2.5, timingParameters: springParameters)
            self.animator?.addAnimations {
                self.top.constant = nextPos
                self.view.layoutIfNeeded()
            }
            self.animator?.addCompletion({ position in
                self.view.layoutIfNeeded()
            })

            self.animator?.startAnimation()

        default:
            break
        }
    }
}

