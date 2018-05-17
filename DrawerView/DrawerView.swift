//
//  DrawerView.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 28/10/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit

let LOGGING = false

let dateFormat = "yyyy-MM-dd hh:mm:ss.SSS"
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = dateFormat
    formatter.locale = Locale.current
    formatter.timeZone = TimeZone.current
    return formatter
}()

@objc public enum DrawerPosition: Int {
    case closed = 0
    case collapsed = 1
    case partiallyOpen = 2
    case open = 3
}

fileprivate extension DrawerPosition {
    static let activePositions: [DrawerPosition] = [
        .open,
        .partiallyOpen,
        .collapsed
    ]

    static let openPositions: [DrawerPosition] = [
        .open,
        .partiallyOpen
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

// Vertical leeway is used to cover the bottom with springy animations.
let kVerticalLeeway: CGFloat = 10.0

let kDefaultCornerRadius: CGFloat = 9.0

let kDefaultShadowRadius: CGFloat = 1.0

let kDefaultShadowOpacity: Float = 0.05

let kDefaultBackgroundEffect = UIBlurEffect(style: .extraLight)

let kDefaultBorderColor = UIColor(white: 0.2, alpha: 0.2)

@objc public protocol DrawerViewDelegate {

    @objc optional func drawer(_ drawerView: DrawerView, willTransitionFrom position: DrawerPosition)

    @objc optional func drawer(_ drawerView: DrawerView, didTransitionTo position: DrawerPosition)

    @objc optional func drawerDidMove(_ drawerView: DrawerView, drawerOffset: CGFloat)
}

@IBDesignable public class DrawerView: UIView {

    // MARK: - Private properties

    private var panGesture: UIPanGestureRecognizer! = nil

    private var panOrigin: CGFloat = 0.0

    private var startedDragging: Bool = false

    private var animator: UIViewPropertyAnimator? = nil

    private var currentPosition: DrawerPosition = .collapsed

    private var topConstraint: NSLayoutConstraint? = nil

    private var heightConstraint: NSLayoutConstraint? = nil

    private var childScrollView: UIScrollView? = nil

    private var childScrollWasEnabled: Bool = true

    private var simultaneousGestureRecognizers: [UIGestureRecognizer] = []

    private var overlay: Overlay?

    private let borderView = UIView()

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

    public var borderColor: UIColor = kDefaultBorderColor {
        didSet {
            updateVisuals()
        }
    }

    // MARK: - Public properties

    @IBOutlet
    public var delegate: DrawerViewDelegate?

    public var drawerOffset: CGFloat {
        return scrollPositionToOffset(self.topConstraint?.constant ?? 0)
    }

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

    private var topSpace: CGFloat {
        // Use only the open positions for determining the top space.
        let topPosition = DrawerPosition.openPositions
            .sorted(by: compareSnapPositions)
            .reversed()
            .first(where: self.enabledPositions.contains)
            ?? .open

        return superview.map { self.snapPosition(for: topPosition, in: $0) } ?? 0
    }

    public func attachTo(view: UIView) {

        if self.superview == nil {
            self.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(self)
        } else if self.superview !== view {
            log("Invalid state; superview already set when called attachTo(view:)")
        }

        topConstraint = self.topAnchor.constraint(equalTo: view.topAnchor, constant: self.topMargin)
        heightConstraint = self.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -self.topSpace)
        heightConstraint = self.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, multiplier: 1, constant: -self.topSpace)
        let bottomConstraint = self.bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor)

        let constraints = [
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topConstraint,
            heightConstraint,
            bottomConstraint
        ]

        for constraint in constraints {
            constraint?.isActive = true
        }

        updateVisuals()
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

    public var enabledPositions: [DrawerPosition] = DrawerPosition.activePositions {
        didSet {
            if !enabledPositions.contains(self.position) {
                // Current position is not in the given list, default to the most closed one.
                self.setInitialPosition()
            }
        }
    }

    private var enabledPositionsSorted: [DrawerPosition] {
        return self.enabledPositions.sorted(by: compareSnapPositions)
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
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 2
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)

        self.translatesAutoresizingMaskIntoConstraints = false

        setupBackgroundView()
        setupBorderView()

        updateVisuals()
    }

    func setupBackgroundView() {
        backgroundView.frame = self.bounds
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.clipsToBounds = true

        self.insertSubview(backgroundView, at: 0)

        let backgroundViewConstraints = [
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: kVerticalLeeway),
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor)
        ]

        for constraint in backgroundViewConstraints {
            constraint.isActive = true
        }

        self.backgroundColor = UIColor.clear
    }

    func setupBorderView() {
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.clipsToBounds = true
        borderView.isUserInteractionEnabled = false
        borderView.backgroundColor = UIColor.clear
        borderView.layer.cornerRadius = 10

        self.addSubview(borderView)

        let borderViewConstraints = [
            borderView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -0.5),
            borderView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0.5),
            borderView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: kVerticalLeeway),
            borderView.topAnchor.constraint(equalTo: self.topAnchor, constant: -0.5)
        ]

        for constraint in borderViewConstraints {
            constraint.isActive = true
        }
    }

    private func updateVisuals() {
        updateLayerVisuals(self.layer)
        updateBorderVisuals(self.borderView)
        updateOverlayVisuals(self.overlay)
        updateBackgroundVisuals(self.backgroundView)
        heightConstraint?.constant = -self.topSpace

        self.setNeedsDisplay()
    }

    private func updateLayerVisuals(_ layer: CALayer) {
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = shadowOpacity
        layer.cornerRadius = self.cornerRadius
    }

    private func updateBorderVisuals(_ borderView: UIView) {
        borderView.layer.cornerRadius = self.cornerRadius
        borderView.layer.borderColor = self.borderColor.cgColor
        borderView.layer.borderWidth = 0.5
    }

    private func updateOverlayVisuals(_ overlay: Overlay?) {
        overlay?.backgroundColor = UIColor.black
        overlay?.cutCornerSize = self.cornerRadius
    }

    private func updateBackgroundVisuals(_ backgroundView: UIVisualEffectView) {

         backgroundView.effect = self.backgroundEffect
        if #available(iOS 11.0, *) {
            backgroundView.layer.cornerRadius = self.cornerRadius
            backgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        } else {
            // Fallback on earlier versions
            let mask: CAShapeLayer = {
                let m = CAShapeLayer()
                let frame = backgroundView.bounds.insetBy(top: 0, bottom: -kVerticalLeeway, left: 0, right: 0)
                let path = UIBezierPath(roundedRect: frame, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: self.cornerRadius, height: self.cornerRadius))
                m.path = path.cgPath
                return m
            }()
            backgroundView.layer.mask = mask
        }
    }

    // MARK: - View methods

    public override func layoutSubviews() {
        super.layoutSubviews()

        // Update snap position, if not dragging.
        let isAnimating = animator?.isRunning ?? false
        if !isAnimating && !startedDragging {
            // Handle possible layout changes, e.g. rotation.
            self.updateSnapPosition(animated: false)
        }

        // NB: For some reason the subviews of the blur
        // background don't keep up with sudden change.
        for view in self.backgroundView.subviews {
            view.frame.origin.y = 0
        }
    }

    // MARK: - Public methods

    public func setPosition(_ position: DrawerPosition, animated: Bool) {
        guard let superview = self.superview else {
            log("ERROR: Not contained in a view.")
            log("ERROR: Could not evaluate snap position for \(position.visibleName)")
            return
        }

        updateBackgroundVisuals(self.backgroundView)
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

        let nextSnapPosition = snapPosition(for: nextPosition, in: superview)
        self.scrollToPosition(nextSnapPosition, observedPosition: nextPosition, animated: animated)
    }

    private func scrollToPosition(_ scrollPosition: CGFloat, observedPosition position: DrawerPosition, animated: Bool) {

        if animated {
            self.animator?.stopAnimation(true)

            // Create the animator.
            let springParameters = UISpringTimingParameters(dampingRatio: 0.8)
            self.animator = UIViewPropertyAnimator(duration: 0.5, timingParameters: springParameters)
            self.animator?.addAnimations {
                self.setScrollPosition(scrollPosition)
            }
            self.animator?.addCompletion({ position in
                self.superview?.layoutIfNeeded()
                self.layoutIfNeeded()
            })

            // Add extra height to make sure that bottom doesn't show up.
            self.superview?.layoutIfNeeded()

            self.animator?.startAnimation()
        } else {
            self.setScrollPosition(scrollPosition)
        }
    }

    // MARK: - Private methods

    private func setScrollPosition(_ scrollPosition: CGFloat) {
        self.topConstraint?.constant = scrollPosition
        self.setOverlayOpacity(forScrollPosition: scrollPosition)
        self.setShadowOpacity(forScrollPosition: scrollPosition)

        let drawerOffset = scrollPositionToOffset(scrollPosition)
        self.delegate?.drawerDidMove?(self, drawerOffset: drawerOffset)

        self.superview?.layoutIfNeeded()
    }

    private func setInitialPosition() {
        self.position = self.enabledPositionsSorted.last ?? .collapsed
    }

    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            self.delegate?.drawer?(self, willTransitionFrom: self.position)

            self.animator?.stopAnimation(true)

            // Get the actual position of the view.
            let frame = self.layer.presentation()?.frame ?? self.frame
            self.panOrigin = frame.origin.y

            setPosition(whileDraggingAtPoint: panOrigin)

            break
        case .changed:

            let translation = sender.translation(in: self)
            let velocity = sender.velocity(in: self)
            if velocity.y == 0 {
                break
            }

            // If scrolling upwards a scroll view, ignore the events.
            if let childScrollView = self.childScrollView {

                // Detect if directional lock should be respected.
                let simultaneousPanGestures = simultaneousGestureRecognizers
                    .flatMap { $0 as? UIPanGestureRecognizer }

                let horizontalPanOnly = simultaneousPanGestures
                    .map { $0.velocity(in: self) }
                    .all { v in
                        print(v)
                        return v.y == 0 && v.x != 0
                }

                let verticalScrollPossible = simultaneousPanGestures.count == 0
                    || horizontalPanOnly

                // If vertical scroll is disabled due to
                if !verticalScrollPossible {
                    log("Vertical pan cancelled due to direction lock")
                    sender.isEnabled = false
                    sender.isEnabled = true
                    break
                }

                // NB: With negative content offset, we don't ask the delegate as
                // we need to pan the drawer.
                let childReachedTheTop = (childScrollView.contentOffset.y <= 0)
                let isFullyOpen = self.enabledPositionsSorted.last == self.position

                let scrollingToBottom = velocity.y < 0

                let shouldScrollChildView: Bool
                if !childScrollView.isScrollEnabled {
                    shouldScrollChildView = false
                } else if !childReachedTheTop && !scrollingToBottom {
                    shouldScrollChildView = true
                } else if childReachedTheTop && !scrollingToBottom {
                    shouldScrollChildView = false
                } else if !isFullyOpen {
                    shouldScrollChildView = false
                } else {
                    shouldScrollChildView = true
                }

                // Disable child view scrolling
                if !shouldScrollChildView && childScrollView.isScrollEnabled {

                    startedDragging = true

                    sender.setTranslation(CGPoint.zero, in: self)

                    // Scrolling downwards and content was consumed, so disable
                    // child scrolling and catch up with the offset.
                    let frame = self.layer.presentation()?.frame ?? self.frame
                    if childScrollView.contentOffset.y < 0 {
                        self.panOrigin = frame.origin.y - childScrollView.contentOffset.y
                    } else {
                        self.panOrigin = frame.origin.y
                    }

                    // Also animate to the proper scroll position.
                    log("Animating to target position...")

                    self.animator?.stopAnimation(true)
                    self.animator = UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.2,
                        delay: 0.0,
                        options: [.allowUserInteraction, .beginFromCurrentState],
                        animations: {
                            // Disabling the scroll removes negative content offset
                            // in the scroll view, so make it animate here.
                            log("Disabled child scrolling")
                            childScrollView.isScrollEnabled = false
                            let pos = self.panOrigin
                            self.setPosition(whileDraggingAtPoint: pos)
                    }, completion: nil)
                } else if !shouldScrollChildView {
                    // Scroll only if we're not scrolling the subviews.
                    startedDragging = true
                    let pos = panOrigin + translation.y
                    setPosition(whileDraggingAtPoint: pos)
                }
            } else {
                startedDragging = true
                let pos = panOrigin + translation.y
                setPosition(whileDraggingAtPoint: pos)
            }

        case.failed:
            log("ERROR: UIPanGestureRecognizer failed")
            fallthrough
        case .ended:
            let velocity = sender.velocity(in: self)
            log("Ending with vertical velocity \(velocity.y)")

            if let childScrollView = self.childScrollView, childScrollView.isScrollEnabled && childScrollView.contentOffset.y > 0 {
                // Let it scroll.
                log("Let child view scroll.")
            } else if startedDragging {
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
                    let advanced = targetPosition.advance(by: advancement, inPositions: self.enabledPositionsSorted) {
                    nextPosition = advanced
                } else {
                    nextPosition = targetPosition
                }
                self.setPosition(nextPosition, animated: true)
            }

            self.childScrollView?.isScrollEnabled = childScrollWasEnabled
            self.childScrollView = nil
            self.simultaneousGestureRecognizers = []

            startedDragging = false

        default:
            break
        }
    }

    @objc private func onTapOverlay(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            self.delegate?.drawer?(self, willTransitionFrom: currentPosition)

            if let prevPosition = self.position.advance(by: -1, inPositions: self.enabledPositionsSorted) {
                self.setPosition(prevPosition, animated: true)

                // Notify
                self.delegate?.drawer?(self, didTransitionTo: prevPosition)
            }
        }
    }

    private func compareSnapPositions(first: DrawerPosition, second: DrawerPosition) -> Bool {
        if let superview = superview {
            return snapPosition(for: first, in: superview) > snapPosition(for: second, in: superview)
        } else {
            // Fall back to comparison between the enumerations.
            return first.rawValue > second.rawValue
        }
    }

    private func snapPositions(for positions: [DrawerPosition], in superview: UIView) -> [(position: DrawerPosition, snapPosition: CGFloat)]  {
        return positions
            // Group the info on position together. For the sake of
            // robustness, hide the ones without snap position.
            .map { p in (
                position: p,
                snapPosition: self.snapPosition(for: p, in: superview)
                )
        }
    }

    private func snapPosition(for position: DrawerPosition, in superview: UIView) -> CGFloat {
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
        case .open:
            return 1
        case .partiallyOpen:
            return 0
        case .collapsed:
            return 0
        case .closed:
            return 0
        }
    }

    private func shadowOpacityFactor(for position: DrawerPosition) -> Float {
        switch position {
        case .open:
            return self.shadowOpacity
        case .partiallyOpen:
            return self.shadowOpacity
        case .collapsed:
            return self.shadowOpacity
        case .closed:
            return 0
        }
    }

    private func positionFor(offset: CGFloat) -> DrawerPosition {
        guard let superview = superview else {
            return DrawerPosition.collapsed
        }
        let distances = self.enabledPositions
            .flatMap { pos in (pos: pos, y: snapPosition(for: pos, in: superview)) }
            .sorted { (p1, p2) -> Bool in
                return abs(p1.y - offset) < abs(p2.y - offset)
        }

        return distances.first.map { $0.pos } ?? DrawerPosition.collapsed
    }

    private func setPosition(whileDraggingAtPoint dragPoint: CGFloat) {
        guard let superview = superview else {
            log("ERROR: Cannot set position, no superview defined")
            return
        }
        let positions = self.enabledPositions
            .flatMap { self.snapPosition(for: $0, in: superview) }
            .sorted()

        let position: CGFloat
        if let lowerBound = positions.first, dragPoint < lowerBound {
            position = lowerBound - damp(value: lowerBound - dragPoint, factor: 50)
        } else if let upperBound = positions.last, dragPoint > upperBound {
            position = upperBound + damp(value: dragPoint - upperBound, factor: 50)
        } else {
            position = dragPoint
        }

        self.setScrollPosition(position)
    }

    private func updateSnapPosition(animated: Bool) {
        guard let superview = superview else {
            log("ERROR: Cannot update snap position, no superview defined")
            return
        }
        let expectedPos = self.snapPosition(for: currentPosition, in: superview)
        if let topConstraint = self.topConstraint, expectedPos != topConstraint.constant {
            self.setPosition(currentPosition, animated: animated)
        }
    }

    private func createOverlay() -> Overlay? {
        guard let superview = self.superview else {
            log("ERROR: Could not create overlay.")
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
        guard let superview = self.superview else {
            log("ERROR: Could not set up overlay.")
            return
        }

        let values = snapPositions(for: enabledPositions + [.closed], in: superview)
            .map {(
                position: $0.snapPosition,
                value: self.opacityFactor(for: $0.position)
                )}

        let opacityFactor = interpolate(
            values: values,
            position: position)

        let maxOpacity: CGFloat = 0.5

        self.overlay = self.overlay ?? createOverlay()
        self.overlay?.alpha = opacityFactor * maxOpacity
    }

    private func setShadowOpacity(forScrollPosition position: CGFloat) {
        guard let superview = self.superview else {
            log("ERROR: Could not set up shadow.")
            return
        }

        let values = snapPositions(for: enabledPositions + [.closed], in: superview)
            .map {(
                position: $0.snapPosition,
                value: CGFloat(self.shadowOpacityFactor(for: $0.position))
                )}

        let shadowOpacity = interpolate(
            values: values,
            position: position)

        self.layer.shadowOpacity = Float(shadowOpacity)
    }

    private func scrollPositionToOffset(_ position: CGFloat) -> CGFloat {
        guard let superview = self.superview else {
            return 0
        }

        return superview.bounds.height - position
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
//        print("gestureRecognizer(shouldRecognizeSimultaneouslyWith:): \(otherGestureRecognizer)")
        if let sv = otherGestureRecognizer.view as? UIScrollView {
            // Safety check: if we haven't resumed the previous child scroll,
            // do it now. This is bound to happen on the simulator at least, when
            // the gesture recognizer is interrupted.
            if let childScrollView = self.childScrollView {
                childScrollView.isScrollEnabled = self.childScrollWasEnabled
            }
            self.simultaneousGestureRecognizers.append(otherGestureRecognizer)
            self.childScrollView = sv
            self.childScrollWasEnabled = sv.isScrollEnabled
        }
        return true
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
    NSLog("DrawerView: \(reason)")
    abort()
}

func log(_ message: String) {
    if LOGGING {
        print("\(dateFormatter.string(from: Date())): \(message)")
    }
}

extension Collection {

    func all(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        return try self.contains(where: { try !predicate($0) })
    }
}
