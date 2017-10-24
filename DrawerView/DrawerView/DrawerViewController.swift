//
//  DrawerContentViewController.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 25/10/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit

class DrawerContentViewController: UIViewController {

    var panGesture: UIPanGestureRecognizer! = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

//        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
//        panGesture.maximumNumberOfTouches = 1
//        panGesture.minimumNumberOfTouches = 1
//        panGesture.delegate = self
//        self.view.addGestureRecognizer(panGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {

        }
        let translation = sender.translation(in: self.view)
//        sender.view?.superview? .bringSubview(toFront: sender.view!)
        sender.view?.center = CGPoint(x: (sender.view?.center.x)! + translation.x , y : (sender.view?.center.y)! + translation.y)
        sender.setTranslation(CGPoint.zero, in: self.view)

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension DrawerContentViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
