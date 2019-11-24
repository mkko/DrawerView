//
//  DrawerPresentation.swift
//  Bussinavi
//
//  Created by Mikko Välimäki on 2019-11-24.
//

import Foundation
import DrawerView

class DrawerPresentationController: UIPresentationController {

    private var drawerView: DrawerView? = nil

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override var presentedView: UIView? {
        return drawerView
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView = self.containerView else {
            return
        }

        presentedViewController.view.removeFromSuperview()
        let drawer = DrawerView(withView: presentedViewController.view)
        drawer.position = .closed
        drawer.snapPositions = [.open, .closed]
        drawer.delegate = self

        drawer.attachTo(view: containerView)
        self.drawerView = drawer
        drawer.layoutSubviews()

        guard let _ = presentedViewController.transitionCoordinator else {
          drawer.setPosition(.open, animated: false)
          return
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if completed {
            // NB: Not sure if this is the right way to use custom animation, but
            // we don't want to animate alongside the transition as then it would
            // not bounce the same way the drawer does.
            DispatchQueue.main.async {
                self.drawerView?.setPosition(.open, animated: true)
            }
        }
    }
}

extension DrawerPresentationController: DrawerViewDelegate {

    func drawer(_ drawerView: DrawerView, didTransitionTo position: DrawerPosition) {
        if position == .closed {
            presentedViewController.dismiss(animated: false)
        }
    }
}

// MARK: - DrawerPresentationManager

class DrawerPresentationManager: NSObject {

}

extension DrawerPresentationManager: UIViewControllerTransitioningDelegate {

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let presentationController = DrawerPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        presentationController.delegate = self
        return presentationController
    }
}

extension DrawerPresentationManager: UIAdaptivePresentationControllerDelegate {
}
