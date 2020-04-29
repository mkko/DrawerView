//
//  DrawerPresentation.swift
//  Bussinavi
//
//  Created by Mikko Välimäki on 2019-11-24.
//
import UIKit

public protocol DrawerPresenter {
    func presentDrawerModal(_ presentedViewController: UIViewController, openHeightBehavior: DrawerView.OpenHeightBehavior)
}

extension UIViewController: DrawerPresenter {
    public func presentDrawerModal(_ presentedViewController: UIViewController, openHeightBehavior: DrawerView.OpenHeightBehavior) {

    }
}

public class DrawerPresentationController: UIPresentationController {

    private let drawerView: DrawerView

    private var presentationDelegate: DrawerPresentationDelegate?

    init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?,
                  drawerView: DrawerView,
                  presentationDelegate: DrawerPresentationDelegate?
    ) {
        self.drawerView = drawerView
        self.presentationDelegate = presentationDelegate
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
        drawerView.layoutIfNeeded()

        presentationDelegate?.drawerPresentationWillBegin?()
    }

    public override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        presentationDelegate?.drawerPresentationnDidEnd?(completed)
    }

    public override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentationDelegate?.drawerDismissalWillBegin?()
    }

    public override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        // Clean up the drawer for reuse.
        presentedViewController.view.removeFromSuperview()
        drawerView.removeFromSuperview()

        presentationDelegate?.drawerDismissalDidEnd?(completed)
    }

    override public var shouldRemovePresentersView: Bool {
        return false
    }

    override public func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
    }
}

@objc public protocol DrawerPresentationDelegate {

    @objc optional func drawerPresentationWillBegin()
    @objc optional func drawerPresentationnDidEnd(_ completed: Bool)
    @objc optional func drawerDismissalWillBegin()
    @objc optional func drawerDismissalDidEnd(_ completed: Bool)
}

extension DrawerPresentationController: DrawerViewDelegate {

    public func drawer(_ drawerView: DrawerView, willTransitionFrom startPosition: DrawerPosition, to targetPosition: DrawerPosition) {
        if targetPosition == .closed {
            presentedViewController.dismiss(animated: true)
        }
    }
}

public class DrawerPresentationManager: NSObject {
    public var drawer = DrawerView()

    public var presentationDelegate: DrawerPresentationDelegate?
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
            drawerView: self.drawer,
            presentationDelegate: self.presentationDelegate
        )
        return presentationController
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DrawerPresentationAnimator(presentation: .present)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DrawerPresentationAnimator(presentation: .dismiss)
    }
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
                transitionContext.completeTransition(finished)
            }
        }
    }
}
