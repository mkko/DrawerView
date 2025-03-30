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
    private var isDismissing = false

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

        // Make callbacks backwards compatible
        if let callback = presentationDelegate?.drawerPresentationWillBegin(for:in:) {
            callback(presentedViewController, drawerView)
        } else {
            presentationDelegate?.drawerPresentationWillBegin?()
        }
    }

    public override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        // Make callbacks backwards compatible
        if let callback = presentationDelegate?.drawerPresentationDidEnd(for:in:completed:) {
            callback(presentedViewController, drawerView, completed)
        } else {
            presentationDelegate?.drawerPresentationDidEnd?(completed)
        }
    }

    public override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        isDismissing = true

        // Make callbacks backwards compatible
        if let callback = presentationDelegate?.drawerDismissalWillBegin(for:in:) {
            callback(presentedViewController, drawerView)
        } else {
            presentationDelegate?.drawerDismissalWillBegin?()
        }
    }

    public override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        isDismissing = false

        if let callback = presentationDelegate?.drawerDismissalDidEnd(for:in:completed:) {
            callback(presentedViewController, drawerView, completed)
        } else {
            presentationDelegate?.drawerDismissalDidEnd?(completed)
        }
    }

    override public var shouldRemovePresentersView: Bool {
        return false
    }
}

@objc public protocol DrawerPresentationDelegate {

    @available(*, deprecated, renamed: "drawerPresentationWillBegin(for:in:)")
    @objc optional func drawerPresentationWillBegin()
    @available(*, deprecated, renamed: "drawerPresentationDidEnd(for:in:completed:)")
    @objc optional func drawerPresentationDidEnd(_ completed: Bool)
    @available(*, deprecated, renamed: "drawerDismissalWillBegin(for:in:)")
    @objc optional func drawerDismissalWillBegin()
    @available(*, deprecated, renamed: "drawerDismissalDidEnd(for:in:completed:)")
    @objc optional func drawerDismissalDidEnd(_ completed: Bool)

    @objc optional func drawerPresentationWillBegin(for viewController: UIViewController, in drawerView: DrawerView)
    @objc optional func drawerPresentationDidEnd(for viewController: UIViewController, in drawerView: DrawerView, completed: Bool)
    @objc optional func drawerDismissalWillBegin(for viewController: UIViewController, in drawerView: DrawerView)
    @objc optional func drawerDismissalDidEnd(for viewController: UIViewController, in drawerView: DrawerView, completed: Bool)

}

extension DrawerPresentationController: DrawerViewDelegate {

    public func drawer(_ drawerView: DrawerView, willTransitionFrom startPosition: DrawerPosition, to targetPosition: DrawerPosition) {
        // Only trigger dismiss if we're not already dismissing to avoid recursion
        if targetPosition == .closed && !isDismissing {
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
    private let animationDuration: TimeInterval = 0.3  // Standard iOS animation duration

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
        return animationDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch presentation {
        case .present:
            guard let drawerView = transitionContext.view(forKey: .to) as? DrawerView else {
                transitionContext.completeTransition(false)
                return
            }

            drawerView.setPosition(.open, animated: true) { finished in
                transitionContext.completeTransition(finished)
            }
        case .dismiss:
            guard let drawerView = transitionContext.view(forKey: .from) as? DrawerView else {
                transitionContext.completeTransition(false)
                return
            }

            let originalVisibilityBehavior = drawerView.contentVisibilityBehavior
            drawerView.contentVisibilityBehavior = .never

            drawerView.setPosition(.closed, animated: true) { finished in
                drawerView.contentVisibilityBehavior = originalVisibilityBehavior
                transitionContext.completeTransition(finished)
            }
        }
    }
}
