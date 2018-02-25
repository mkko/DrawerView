//
//  DrawerView.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 28/10/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit

@objc public enum DrawerPosition: Int {
    case closed = 0
    case collapsed = 1
    case partiallyOpen = 2
    case open = 3
}

fileprivate extension DrawerPosition {
    static let allPositions: [DrawerPosition] = [
        .closed,
        .open,
        .partiallyOpen,
        .collapsed
    ]

    var visibleName: String {
        switch self {
        case .closed: return "hidden"
        case .open: return "open"
        case .partiallyOpen: return "partiallyOpen"
        case .collapsed: return "collapsed"
        }
    }
}

let kVelocityTreshold: CGFloat = 0

let kVerticalLeeway: CGFloat = 100.0

let kDefaultCornerRadius: CGFloat = 10.0

let kDefaultShadowRadius: CGFloat = 5.0

let kDefaultShadowOpacity: Float = 0.1

let kDefaultBackgroundEffect = UIBlurEffect(style: .extraLight)

@objc public protocol DrawerViewDelegate {

    @objc optional func canScrollContent(drawerView: DrawerView) -> Bool

    @objc optional func drawer(_ drawerView: DrawerView, willTransitionFrom position: DrawerPosition)

    @objc optional func drawer(_ drawerView: DrawerView, didTransitionTo position: DrawerPosition)

    @objc optional func drawerDidMove(_ drawerView: DrawerView, verticalPosition: CGFloat)
}

@IBDesignable public class DrawerView: UIView {

    // MARK: - Private properties

    private var panGesture: UIPanGestureRecognizer! = nil

    private var panOrigin: CGFloat = 0.0

    private var isDragging: Bool = false

    private var animator: UIViewPropertyAnimator? = nil

    private var currentPosition: DrawerPosition = .collapsed

    private var topConstraint: NSLayoutConstraint? = nil

    private var heightConstraint: NSLayoutConstraint? = nil

    private var childScrollView: UIScrollView? = nil

    private var childScrollWasEnabled: Bool = true

    private var otherGestureRecognizer: UIGestureRecognizer? = nil

    private var overlay: Overlay?

    private let border = CALayer()

    private let backgroundView = UIVisualEffectView(effect: kDefaultBackgroundEffect)

    // MARK: - Visual properties

    @IBInspectable public var cornerRadius: CGFloat = kDefaultCornerRadius {
        didSet {
            updateVisuals()
        }
    }

    @IBInspectable public var shadowRadius: CGFloat = kDefaultShadowRadius {
        didSet {
            updateVisuals()
        }
    }

    @IBInspectable public var shadowOpacity: Float = kDefaultShadowOpacity {
        didSet {
            updateVisuals()
        }
    }

    public var backgroundEffect: UIVisualEffect? = kDefaultBackgroundEffect {
        didSet {
            updateVisuals()
        }
    }

    // MARK: - Public properties

    @IBOutlet
    public var delegate: DrawerViewDelegate?

    // IB support, not intended to be used otherwise.
    @IBOutlet
    public var containerView: UIView? {
        willSet {
            // TODO: Instead, check if has been initialized from nib.
            if self.superview != nil {
                abort(reason: "Superview already set, use normal UIView methods to set up the view hierarcy")
            }
        }
        didSet {
            if let containerView = containerView {
                self.attachTo(view: containerView)
            }
        }
    }

    public func attachTo(view: UIView) {

        if self.superview == nil {
            self.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(self)
        } else if self.superview !== view {
            print("Invalid state; superview already set when called attachTo(view:)")
        }

        topConstraint = self.topAnchor.constraint(equalTo: view.topAnchor, constant: self.topMargin)
        heightConstraint = self.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -self.topMargin)

        let constraints = [
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topConstraint,
            heightConstraint
        ]

        for constraint in constraints {
            constraint?.isActive = true
        }
    }

    // TODO: Use size classes with the positions.

    public var topMargin: CGFloat = 68.0 {
        didSet {
            self.updateSnapPosition(animated: false)
        }
    }

    public var collapsedHeight: CGFloat = 68.0 {
        didSet {
            self.updateSnapPosition(animated: false)
        }
    }

    public var partiallyOpenHeight: CGFloat = 264.0 {
        didSet {
            self.updateSnapPosition(animated: false)
        }
    }

    public var position: DrawerPosition {
        get {
            return currentPosition
        }
        set {
            self.setPosition(newValue, animated: false)
        }
    }

    public var enabledPositions: [DrawerPosition] = DrawerPosition.allPositions {
        didSet {
            if !enabledPositions.contains(self.position) {
                // Current position is not in the given list, default to the most closed one.
                self.setInitialPosition()
            }
        }
    }

    // MARK: - Initialization

    init() {
        super.init(frame: CGRect())
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    convenience public init(withView view: UIView) {
        self.init()

        view.frame = self.bounds
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)

        for c in [
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            view.heightAnchor.constraint(equalTo: self.heightAnchor),
            view.topAnchor.constraint(equalTo: self.topAnchor)
        ] {
            c.isActive = true
        }
    }

    private func setup() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        panGesture.maximumNumberOfTouches = 2
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)

        self.translatesAutoresizingMaskIntoConstraints = false

        setupBorder()
        addBlurEffect()

        updateVisuals()
    }

    func setupBorder() {
        self.layer.addSublayer(border)
    }

    private var backgroundViewConstraints: [NSLayoutConstraint] = []

    func addBlurEffect() {
        backgroundView.frame = self.bounds
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.clipsToBounds = true

        self.insertSubview(backgroundView, at: 0)

        backgroundViewConstraints = [
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            backgroundView.heightAnchor.constraint(equalTo: self.heightAnchor),
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor)
        ]

        for constraint in backgroundViewConstraints {
            constraint.isActive = true
        }

        self.backgroundColor = UIColor.clear
    }

    private func updateVisuals() {
        updateLayerVisuals(self.layer)
        updateBorderVisuals(self.border)
        updateOverlayVisuals(self.overlay)
        updateBackgroundVisuals(self.backgroundView)
    }

    private func updateLayerVisuals(_ layer: CALayer) {
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = shadowOpacity
        layer.cornerRadius = self.cornerRadius
    }

    private func updateBorderVisuals(_ border: CALayer) {
        border.cornerRadius = self.cornerRadius
        border.frame = self.bounds.insetBy(dx: -0.5, dy: -0.5)
        border.borderColor = UIColor(white: 0.2, alpha: 0.2).cgColor
        border.borderWidth = 0.5
    }

    private func updateOverlayVisuals(_ overlay: Overlay?) {
        overlay?.backgroundColor = UIColor.black
        overlay?.cutCornerSize = self.cornerRadius
    }

    private func updateBackgroundVisuals(_ backgroundView: UIVisualEffectView) {
        backgroundView.effect = self.backgroundEffect
        backgroundView.layer.cornerRadius = self.cornerRadius
    }

    // MARK: - View methods

    public override func layoutSubviews() {
        super.layoutSubviews()

        // Update snap position, if not dragging.
        //let animatorRunning = animator?.isRunning ?? false
        if animator == nil && !isDragging {
            // Handle possible layout changes, e.g. rotation.
            self.updateSnapPosition(animated: false)
        }

        // NB: For some reason the subviews of the blur background
        // don't keep up with sudden change
        for view in self.backgroundView.subviews {
            view.frame.origin.y = 0
        }
    }

    public override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer == self.layer {
            border.frame = self.bounds.insetBy(dx: -0.5, dy: -0.5)
        }
    }

    // MARK: - Public methods

    public func setPosition(_ position: DrawerPosition, animated: Bool) {
        self.setPosition(position, withVelocity: CGPoint(), animated: animated)
    }

    public func setPosition(_ position: DrawerPosition, withVelocity velocity: CGPoint, animated: Bool) {

        // Get the next available position. Closed position is always supported.
        let nextPosition: DrawerPosition
        if position != .closed && !self.enabledPositions.contains(position) {
            nextPosition = position.advance(by: 1, inPositions: self.enabledPositions)
                ?? position.advance(by: -1, inPositions: self.enabledPositions)
                ?? position
        } else {
            nextPosition = position
        }

        self.currentPosition = nextPosition

        guard let snapPosition = snapPosition(for: nextPosition) else {
            print("Could not evaluate snap position for \(position.visibleName)")
            return
        }

        self.setScrollPosition(snapPosition, withVelocity: velocity, observedPosition: nextPosition, animated: animated)
    }

    private func setScrollPosition(_ scrollPosition: CGFloat, withVelocity velocity: CGPoint, observedPosition position: DrawerPosition, animated: Bool) {
        guard let heightConstraint = self.heightConstraint else {
            print("No height constraint set")
            return
        }

        if animated {
            self.animator?.stopAnimation(true)

            let m: CGFloat = 100.0
            let velocityVector = CGVector(dx: 0, dy: abs(velocity.y) / m);
            let springParameters = UISpringTimingParameters(dampingRatio: 0.8, initialVelocity: velocityVector)

            // Create the animator
            self.animator = UIViewPropertyAnimator(duration: 0.5, timingParameters: springParameters)
            self.animator?.addAnimations {
                self.setScrollPosition(scrollPosition, observedPosition: position)
            }
            self.animator?.addCompletion({ position in
                heightConstraint.constant = -self.topMargin
                self.superview?.layoutIfNeeded()
                self.layoutIfNeeded()
            })

            // Add extra height to make sure that bottom doesn't show up.
            heightConstraint.constant = heightConstraint.constant + kVerticalLeeway
            self.superview?.layoutIfNeeded()

            self.animator?.startAnimation()
        } else {
            self.setScrollPosition(scrollPosition, observedPosition: position)
        }
    }

    private func setScrollPosition(_ scrollPosition: CGFloat, observedPosition position: DrawerPosition) {
        self.topConstraint?.constant = scrollPosition
        self.setOverlayOpacity(forScrollPosition: scrollPosition)
        self.setShadowOpacity(forPosition: position)

        self.superview?.layoutIfNeeded()
    }

    // MARK: - Private methods

    private func positionsSorted() -> [DrawerPosition] {
        return self.sorted(positions: self.enabledPositions)
    }

    private func setInitialPosition() {
        self.position = self.positionsSorted().last ?? .collapsed
    }

    private func shouldScrollChildView() -> Bool {
        if let canScrollContent = self.delegate?.canScrollContent {
            return canScrollContent(self)
        }
        // By default, child scrolling is enabled only when fully open.
        return self.position == .open
    }

    @objc private func onPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            isDragging = true

            self.delegate?.drawer?(self, willTransitionFrom: self.position)

            self.animator?.stopAnimation(true)

            let frame = self.layer.presentation()?.frame ?? self.frame
            self.panOrigin = frame.origin.y

            setPosition(forDragPoint: panOrigin)

            break
        case .changed:

            let translation = sender.translation(in: self)
            // If scrolling upwards a scroll view, ignore the events.
            if let childScrollView = self.childScrollView {

                // NB: With negative content offset, we don't ask the delegate as
                // we need to pan the drawer.
                let shouldCancelChildViewScroll = (childScrollView.contentOffset.y < 0)
                let shouldScrollChildView = childScrollView.isScrollEnabled
                    ? (!shouldCancelChildViewScroll && self.shouldScrollChildView())
                    : false
                let shouldDisableChildScroll = !shouldScrollChildView && childScrollView.isScrollEnabled

                // Disable child view scrolling
                if shouldDisableChildScroll {
                    // Scrolling downwards and content was consumed, so disable
                    // child scrolling and catch up with the offset.
                    self.panOrigin = self.panOrigin - childScrollView.contentOffset.y
                    childScrollView.isScrollEnabled = false
                    //print("Disabled child scrolling")

                    // Also animate to the proper scroll position.
                    //print("Animating to target position...")

                    self.animator?.stopAnimation(true)
                    self.animator = UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.5,
                        delay: 0.0,
                        options: [.allowUserInteraction, .beginFromCurrentState],
                        animations: {
                            childScrollView.contentOffset.y = 0
                            let pos = self.panOrigin + translation.y
                            self.setPosition(forDragPoint: pos)
                    }, completion: nil)
                } else {
                    //print("Let it scroll...")
                }

                // Scroll only if we're not scrolling the subviews.
                if !shouldScrollChildView {
                    let pos = panOrigin + translation.y
                    setPosition(forDragPoint: pos)
                }
            } else {
                let pos = panOrigin + translation.y
                setPosition(forDragPoint: pos)
            }

            self.delegate?.drawerDidMove?(self, verticalPosition: panOrigin + translation.y)

        case.failed:
            print("ERROR: UIPanGestureRecognizer failed")
            fallthrough
        case .ended:
            let velocity = sender.velocity(in: self)
            // print("Ending with vertical velocity \(velocity.y)")

            if let childScrollView = self.childScrollView,
                childScrollView.contentOffset.y > 0 && self.shouldScrollChildView() {
                // Let it scroll.
                // print("Let it scroll.")
            } else {
                // Check velocity and snap position separately:
                // 1) A treshold for velocity that makes drawer slide to the next state
                // 2) A prediction that estimates the next position based on target offset.
                // If 2 doesn't evaluate to the current position, use that.
                let targetOffset = self.frame.origin.y + velocity.y * 0.15
                let targetPosition = positionFor(offset: targetOffset)

                // The positions are reversed, reverse the sign.
                let advancement = velocity.y > 0 ? -1 : 1

                let nextPosition: DrawerPosition
                if targetPosition == self.position && abs(velocity.y) > kVelocityTreshold,
                    let advanced = targetPosition.advance(by: advancement, inPositions: self.positionsSorted()) {
                    nextPosition = advanced
                } else {
                    nextPosition = targetPosition
                }
                self.setPosition(nextPosition, withVelocity: velocity, animated: true)
            }

            self.childScrollView?.isScrollEnabled = childScrollWasEnabled
            self.childScrollView = nil

            isDragging = false

        default:
            break
        }
    }

    @objc private func onTapOverlay(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            self.delegate?.drawer?(self, willTransitionFrom: currentPosition)

            if let prevPosition = self.position.advance(by: -1, inPositions: self.positionsSorted()) {
                self.setPosition(prevPosition, animated: true)

                // Notify
                self.delegate?.drawer?(self, didTransitionTo: prevPosition)
            }
        }
    }

    private func sorted(positions: [DrawerPosition]) -> [DrawerPosition] {
        return positions
            .flatMap { pos in snapPosition(for: pos).map { (pos: pos, y: $0) } }
            .sorted { $0.y > $1.y }
            .map { $0.pos }
    }

    private func snapPositionForClosed() -> CGFloat {
        return superview?.bounds.height ?? 0
    }

    private func snapPosition(for position: DrawerPosition) -> CGFloat? {
        guard let superview = self.superview else {
            return nil
        }

        switch position {
        case .open:
            return self.topMargin
        case .partiallyOpen:
            return superview.bounds.height - self.partiallyOpenHeight
        case .collapsed:
            return superview.bounds.height - self.collapsedHeight
        case .closed:
            return superview.bounds.height
        }
    }

    private func opacityFactor(for position: DrawerPosition) -> CGFloat {
        switch position {
        case .closed:
            return 0
        case .open:
            return 1
        case .partiallyOpen:
            return 0
        case .collapsed:
            return 0
        }
    }

    private func positionFor(offset: CGFloat) -> DrawerPosition {
        let distances = self.enabledPositions
            .flatMap { pos in snapPosition(for: pos).map { (pos: pos, y: $0) } }
            .sorted { (p1, p2) -> Bool in
                return abs(p1.y - offset) < abs(p2.y - offset)
        }

        return distances.first.map { $0.pos } ?? DrawerPosition.collapsed
    }

    private func setPosition(forDragPoint dragPoint: CGFloat) {
        let positions = self.enabledPositions
            .flatMap(snapPosition)
            .sorted()

        let position: CGFloat
        if let lowerBound = positions.first, dragPoint < lowerBound {
            let stretch = damp(value: lowerBound - dragPoint, factor: 50)
            position = lowerBound - damp(value: lowerBound - dragPoint, factor: 50)
            self.heightConstraint?.constant = -self.topMargin + stretch
        } else if let upperBound = positions.last, dragPoint > upperBound {
            position = upperBound + damp(value: dragPoint - upperBound, factor: 50)
        } else {
            position = dragPoint
        }
        self.topConstraint?.constant = position
        self.setOverlayOpacity(forScrollPosition: dragPoint)
        // Ignore shadow opacity update here, as this is expected to be
        // called only while user is scrolling.

        self.superview?.layoutIfNeeded()
    }

    private func updateSnapPosition(animated: Bool) {
        if let topConstraint = self.topConstraint,
            let expectedPos = self.snapPosition(for: currentPosition),
            expectedPos != topConstraint.constant
        {
            self.setPosition(currentPosition, animated: animated)
        }
    }

    private func createOverlay() -> Overlay? {
        guard let superview = self.superview else {
            return nil
        }

        let overlay = Overlay(frame: superview.bounds)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapOverlay))
        overlay.addGestureRecognizer(tap)

        superview.insertSubview(overlay, belowSubview: self)

        let constraints = [
            overlay.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            overlay.heightAnchor.constraint(equalTo: superview.heightAnchor),
            overlay.bottomAnchor.constraint(equalTo: self.topAnchor)
        ]

        for constraint in constraints {
            constraint.isActive = true
        }

        updateOverlayVisuals(overlay)

        return overlay
    }

    private func setOverlayOpacity(forScrollPosition position: CGFloat) {
        let opacityFactor = getOverlayOpacityFactor(forScrollPosition: position)
        let maxOpacity: CGFloat = 0.5

        self.overlay = self.overlay ?? createOverlay()
        self.overlay?.alpha = opacityFactor * maxOpacity
    }

    private func setShadowOpacity(forPosition position: DrawerPosition) {
        // Hide the shadow if closed.
        if self.position == .closed {
            self.layer.shadowOpacity = 0
        } else {
            self.layer.shadowOpacity = self.shadowOpacity
        }
    }

    private func getOverlayOpacityFactor(forScrollPosition scrollPosition: CGFloat) -> CGFloat {
        let positions = self.enabledPositions
            // Group the info on position together. For increased
            // robustness, hide the ones without snap position.
            .flatMap { p in self.snapPosition(for: p).map {(
                snapPosition: $0,
                opacityFactor: opacityFactor(for: p)
                )}
            }
            .sorted { (p1, p2) -> Bool in p1.snapPosition < p2.snapPosition }

        let prev = positions.last(where: { $0.snapPosition <= scrollPosition })
        let next = positions.first(where: { $0.snapPosition > scrollPosition })

        if let a = prev, let b = next {
            let n = (scrollPosition - a.snapPosition) / (b.snapPosition - a.snapPosition)
            return a.opacityFactor + (b.opacityFactor - a.opacityFactor) * n
        } else if let a = prev ?? next {
            return a.opacityFactor
        } else {
            return 0
        }
    }

    private func damp(value: CGFloat, factor: CGFloat) -> CGFloat {
        return factor * (log10(value + factor/log(10)) - log10(factor/log(10)))
    }
}

extension DrawerView: UIGestureRecognizerDelegate {

    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let sv = otherGestureRecognizer.view as? UIScrollView {
            self.otherGestureRecognizer = otherGestureRecognizer
            self.childScrollView = sv
            self.childScrollWasEnabled = sv.isScrollEnabled
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if self.position == .open {
            return false
        } else {
            return !self.shouldScrollChildView() && otherGestureRecognizer.view is UIScrollView
        }
    }
}

fileprivate extension CGRect {

    func insetBy(top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0) -> CGRect {
        return CGRect(
            x: self.origin.x + left,
            y: self.origin.y + top,
            width: self.size.width - left - right,
            height: self.size.height - top - bottom)
    }
}

fileprivate extension Array {

    func last(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return try self.filter(predicate).last
    }
}

fileprivate extension DrawerPosition {

    func advance(by: Int, inPositions positions: [DrawerPosition]) -> DrawerPosition? {
        guard !positions.isEmpty else {
            return nil
        }

        let index = (positions.index(of: self) ?? 0)
        let nextIndex = index + by
        return positions.indices.contains(nextIndex) ? positions[nextIndex] : nil
    }
}

func abort(reason: String) -> Never  {
    print(reason)
    abort()
}


