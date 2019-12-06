//
//  DrawerPresentation.swift
//  Bussinavi
//
//  Created by Mikko Välimäki on 2019-11-24.
//

import Foundation

public class DrawerPresentationController: UIPresentationController {

    private let drawerView: DrawerView

    init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?,
                  drawerView: DrawerView) {
        self.drawerView = drawerView
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override public var presentedView: UIView? {
        return drawerView
    }

    override public var presentationStyle: UIModalPresentationStyle {
        return .currentContext
    }

    override public func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView = self.containerView else {
            return
        }

        presentedViewController.view.removeFromSuperview()
        drawerView.embed(view: presentedViewController.view)

        drawerView.position = .closed
        drawerView.snapPositions = [.open, .closed]
        drawerView.delegate = self

        drawerView.attachTo(view: containerView)
        drawerView.layoutSubviews()
    }

    override public var shouldRemovePresentersView: Bool {
        return false
    }

    override public func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
    }
}

extension DrawerPresentationController: DrawerViewDelegate {

    public func drawer(_ drawerView: DrawerView, didTransitionTo position: DrawerPosition) {
        if position == .closed {
            presentedViewController.dismiss(animated: false)
        }
    }
}

public class DrawerPresentationManager: NSObject {
    public let drawer = DrawerView()
}

extension DrawerPresentationManager: UIViewControllerTransitioningDelegate {

    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let presentationController = DrawerPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            drawerView: self.drawer
        )
        presentationController.delegate = self
        return presentationController
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DrawerPresentationAnimator(presentation: .present)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DrawerPresentationAnimator(presentation: .dismiss)
    }
}

extension DrawerPresentationManager: UIAdaptivePresentationControllerDelegate {
}

public final class DrawerPresentationAnimator: NSObject {

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

extension DrawerPresentationAnimator: UIViewControllerAnimatedTransitioning {
    public func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        return 0.0
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

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
