//
//  DrawerPresentation.swift
//  Bussinavi
//
//  Created by Mikko Välimäki on 2019-11-24.
//

import Foundation

class DrawerPresentationController: UIPresentationController {

    private var drawerView: DrawerView? = nil

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override var presentedView: UIView? {
        return drawerView
    }

    override var presentationStyle: UIModalPresentationStyle {
        return .currentContext
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
    }

    override var shouldRemovePresentersView: Bool {
        return false
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
    }
}

extension DrawerPresentationController: DrawerViewDelegate {

    func drawer(_ drawerView: DrawerView, didTransitionTo position: DrawerPosition) {
        if position == .closed {
            presentedViewController.dismiss(animated: false)
        }
    }
}

public class DrawerPresentationManager: NSObject {
}

extension DrawerPresentationManager: UIViewControllerTransitioningDelegate {

    public func presentationController(
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

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInPresentationAnimator(presentation: .present)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInPresentationAnimator(presentation: .dismiss)
    }
}

extension DrawerPresentationManager: UIAdaptivePresentationControllerDelegate {
}

final class SlideInPresentationAnimator: NSObject {

    let presentation: PresentationType

    enum PresentationType {
      case present
      case dismiss
    }

    init(presentation: PresentationType) {
        self.presentation = presentation
        super.init()
    }
}

extension SlideInPresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        return 0.0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        switch presentation {
        case .present:
            guard let drawerView = transitionContext.view(forKey: .to) as? DrawerView else {
                return
            }

            drawerView.setPosition(.open, animated: true) { finished in
               transitionContext.completeTransition(finished)
           }
        case .dismiss:
            guard let drawerView = transitionContext.view(forKey: .from) as? DrawerView else {
                return
            }
            drawerView.setPosition(.closed, animated: true) { finished in
                drawerView.removeFromSuperview()
                transitionContext.completeTransition(finished)
            }
        }
    }
}