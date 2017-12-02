//
//  DrawerView.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 28/10/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit

@objc public enum DrawerPosition: Int {
    case open = 1
    case partiallyOpen = 2
    case collapsed = 3
}

private extension DrawerPosition {
    static let positions: [DrawerPosition] = [
        .open,
        .partiallyOpen,
        .collapsed
    ]

    var backgroundOpacity: CGFloat {
        return 0
    }
}

let kVelocityTreshold: CGFloat = 0

let defaultBackgroundEffect = UIBlurEffect(style: .extraLight)

@objc public protocol DrawerViewDelegate {

    @objc optional func canScrollContent(drawerView: DrawerView) -> Bool

    @objc optional func drawer(_ drawerView: DrawerView, willTransitionFrom position: DrawerPosition)

    // TODO: Implement this
    @objc optional func drawer(_ drawerView: DrawerView, didTransitionTo position: DrawerPosition)

    @objc optional func drawerDidMove(_ drawerView: DrawerView, verticalPosition: CGFloat)
}

public class DrawerView: UIView {

    // MARK: - Private properties

    private var animator: UIDynamicAnimator? = nil
    private var drawerBehavior: DrawerBehavior? = nil

    var panGesture: UIPanGestureRecognizer! = nil

    var childScrollView: UIScrollView? = nil
    var childScrollWasEnabled: Bool = true
    var otherGestureRecognizer: UIGestureRecognizer? = nil

    var frameOrigin: CGPoint = CGPoint()
    var panOrigin: CGFloat = 0.0

    private var overlay: UIView?

    private var _position: DrawerPosition = .collapsed

    private var _originalHeight: CGFloat?

    private var maxHeight: CGFloat {
        return (self.superview?.bounds.height)
            .map { $0 - self.topMargin }
            ?? self.frame.height
    }

    // MARK: - Public properties

    @IBOutlet
    public var delegate: DrawerViewDelegate?

    @IBOutlet
    public var containerView: UIView? {
        didSet {
            if let containerView = containerView {
                // Adjust to full screen.
                self.frame = containerView.bounds.insetBy(top: topMargin)
                if self.superview != containerView {
                    self.removeFromSuperview()
                }
                // TODO: Should we use autolayout to adjust our position?
                containerView.addSubview(self)
            }
        }
    }

    public let backgroundView = UIVisualEffectView(effect: defaultBackgroundEffect)

    // TODO: Use size classes here
    public var topMargin: CGFloat = 68.0 {
        didSet {
            // TODO: Update position if needed
        }
    }

    // TODO: Use size classes here
    public var collapsedHeight: CGFloat = 68.0 {
        didSet {
            // TODO: Update position if needed
        }
    }

    // TODO: Use size classes here
    public var partiallyOpenHeight: CGFloat = 264.0 {
        didSet {
            // TODO: Update position if needed
        }
    }

    public var position: DrawerPosition {
        get {
            return _position
        }
        set {
            self.setPosition(newValue, animated: false)
        }
    }

    public var supportedPositions: [DrawerPosition] = DrawerPosition.positions {
        didSet {
            if supportedPositions.index(of: self.position) == nil {
                // Current position is not in the given list, default to the most closed one.
                self.setInitialPosition()
            }
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    private func setup() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)

        // Using a setup similar to Maps.app.
        self.layer.cornerRadius = 10
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 0.1

        addBorder()
        addBlurEffect()
    }

    func addBorder() {
        let border = CALayer()
        border.cornerRadius = self.layer.cornerRadius
        border.frame = self.bounds.insetBy(dx: -0.5, dy: -0.5)
        border.borderColor = UIColor(white: 0.2, alpha: 0.2).cgColor
        border.borderWidth = 0.5
        self.layer.addSublayer(border)
    }

    func addBlurEffect() {
        backgroundView.frame = self.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.layer.cornerRadius = 8
        backgroundView.clipsToBounds = true

        self.insertSubview(backgroundView, at: 0)
        self.backgroundColor = UIColor.clear
    }

    // MARK: - View methods

    override public func layoutSubviews() {
        if let superview = self.superview,
            self.animator?.referenceView != superview {
            // TODO: Handle superview changes
            self.animator = UIDynamicAnimator(referenceView: superview)
            self.animator?.delegate = self
            setInitialPosition()
        }
    }

    override public var center: CGPoint {
        didSet{
            // Expect the dynamic animator to use this property.
            let yPos = self.center.y - self.bounds.height / 2.0
            self.setOverlayOpacityForPoint(point: yPos)
        }
    }

    // MARK: - Public methods

    public func setPosition(_ position: DrawerPosition, animated: Bool) {
        self.delegate?.drawer?(self, willTransitionFrom: _position)
        self.setPosition(position, withVelocity: CGPoint(), animated: animated)
    }

    public func setPosition(_ position: DrawerPosition, withVelocity velocity: CGPoint, animated: Bool) {
        // TODO: Support unanimated.
        guard let snapPosition = snapPosition(for: position),
            let animator = self.animator else {
                print("Snapping to position, but no animator.")
                return
        }

        print("Snapping to \(position) with velocity \(velocity)")

        if !animated {
            self.frame.origin.y = snapPosition
        }

        // TODO: Add extra height to make sure that bottom doesn't show up.

        if drawerBehavior == nil {
            drawerBehavior = DrawerBehavior(item: self)
        }

        let originalHeight = _originalHeight ?? {
            _originalHeight = self.frame.size.height
            return _originalHeight!
        }()

        self.frame.size.height = originalHeight * 1.5

        let snapPoint = CGPoint(x: self.bounds.width / 2.0, y: snapPosition + self.bounds.height / 2.0)

        self.drawerBehavior?.targetPoint = snapPoint
        self.drawerBehavior?.velocity = velocity

        animator.addBehavior(self.drawerBehavior!)

        _position = position
    }

    // MARK: - Private methods

    private func positionsSorted() -> [DrawerPosition] {
        return self.sorted(positions: self.supportedPositions)
    }

    private func setInitialPosition() {
        self.position = self.positionsSorted().first ?? .collapsed
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
            self.delegate?.drawer?(self, willTransitionFrom: self.position)

            self.panOrigin = self.frame.origin.y
            if let drawerBehavior = self.drawerBehavior {
                self.animator?.removeBehavior(drawerBehavior)
            }
            setPosition(forDragPoint: panOrigin)

            break
        case .changed:

            let translation = sender.translation(in: self)
            // If scrolling upwards a scroll view, ignore the events.
            if let childScrollView = self.childScrollView {

                let shouldCancelChildViewScroll = (childScrollView.contentOffset.y < 0)
                let shouldScrollChildView = !childScrollView.isScrollEnabled ?
                    false : (!shouldCancelChildViewScroll && self.shouldScrollChildView())

                if !shouldScrollChildView || childScrollView.contentOffset.y < 0 {
                    // Scrolling downwards and content was consumed, so disable
                    // child scrolling and catch up with the offset.
                    self.panOrigin = self.panOrigin - childScrollView.contentOffset.y
                    childScrollView.isScrollEnabled = false
                    print("Disabled child scrolling")

                    // Also animate to the proper scroll position.
                    print("Animating to target position...")
                    UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                        childScrollView.contentOffset.y = 0
                        self.setPosition(forDragPoint: self.panOrigin + translation.y)
                    }, completion: {_ in /*print("...animated.")*/})
                } else {
                    print("Let it scroll...")
                }

                // Scroll only if we're not scrolling the subviews.
                if !shouldScrollChildView {
                    setPosition(forDragPoint: panOrigin + translation.y)
                }
            } else {
                setPosition(forDragPoint: panOrigin + translation.y)
            }

            self.delegate?.drawerDidMove?(self, verticalPosition: panOrigin + translation.y)

        case.failed:
            print("ERROR: UIPanGestureRecognizer failed")
            fallthrough
        case .ended:
            let velocity = sender.velocity(in: self)
            print("Ending with vertical velocity \(velocity.y)")

            if let childScrollView = self.childScrollView,
                childScrollView.contentOffset.y > 0 && self.shouldScrollChildView() {
                // Let it scroll.
                print("Let it scroll.")
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
                if targetPosition == self.position && abs(velocity.y) > kVelocityTreshold {
                    nextPosition = targetPosition.advance(by: advancement, inPositions: self.positionsSorted())
                } else {
                    nextPosition = targetPosition
                }
                self.setPosition(nextPosition, withVelocity: velocity, animated: true)
            }

            self.childScrollView?.isScrollEnabled = childScrollWasEnabled
            self.childScrollView = nil

        default:
            break
        }
    }

    @objc private func onTapOverlay(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            // TODO: self.delegate?.drawer?(self, willTransitionTo: prevPosition) ?

            let prevPosition = self.position.advance(by: -1, inPositions: self.positionsSorted())
            self.setPosition(prevPosition, animated: true)

            // Notify
            self.delegate?.drawer?(self, didTransitionTo: prevPosition)
        }
    }

    private func sorted(positions: [DrawerPosition]) -> [DrawerPosition] {
        return positions
            .flatMap { pos in snapPosition(for: pos).map { (pos: pos, y: $0) } }
            .sorted { $0.y > $1.y }
            .map { $0.pos }
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
        }
    }

    private func opacity(for position: DrawerPosition) -> CGFloat {
        switch position {
        case .open:
            return 1
        case .partiallyOpen:
            return 0
        case .collapsed:
            return 0
        }
    }

    private func snapPositionForHidden() -> CGFloat {
        return superview?.bounds.height ?? 0
    }

    private func positionFor(offset: CGFloat) -> DrawerPosition {
        //let distanceFromOpen = offset
        let distances = self.supportedPositions
            .flatMap { pos in snapPosition(for: pos).map { (pos: pos, y: $0) } }
            .sorted { (p1, p2) -> Bool in
                return abs(p1.y - offset) < abs(p2.y - offset)
        }

        return distances.first.map { $0.pos } ?? DrawerPosition.collapsed
    }

    private func setPosition(forDragPoint dragPoint: CGFloat) {
        let positions = self.supportedPositions
            .flatMap(snapPosition)
            .sorted()
        if let lowerBound = positions.first, dragPoint < lowerBound {
            let stretch = damp(value: lowerBound - dragPoint, factor: 50)
            self.frame.origin.y = lowerBound - damp(value: lowerBound - dragPoint, factor: 50)
            self.frame.size.height = self.maxHeight + stretch
        } else if let upperBound = positions.last, dragPoint > upperBound {
            self.frame.origin.y = upperBound + damp(value: dragPoint - upperBound, factor: 50)
        } else {
            self.frame.origin.y = dragPoint
        }

        self.setOverlayOpacityForPoint(point: self.frame.origin.y)
    }

    private func setOverlayOpacityForPoint(point: CGFloat) {
        guard let superview = self.superview else {
            return
        }

        let opacity = getOverlayOpacityForPoint(point: point)

        if opacity > 0 {
            self.overlay = self.overlay ?? {
                let overlay = createOverlay()
                superview.insertSubview(overlay, belowSubview: self)
                return overlay
            }()
            self.overlay?.backgroundColor = UIColor.black
            self.overlay?.alpha = opacity * 0.5
        } else if let overlay = self.overlay {
            overlay.removeFromSuperview()
            self.overlay = nil
        }
    }

    private func createOverlay() -> UIView {
        let overlay = UIView(frame: superview?.bounds ?? CGRect())
        overlay.backgroundColor = UIColor.black
        overlay.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapOverlay))
        overlay.addGestureRecognizer(tap)
        return overlay
    }

    private func getOverlayOpacityForPoint(point: CGFloat) -> CGFloat {
        let positions = self.supportedPositions
            // Group the info on position together. For increased
            // robustness, hide the ones without snap position.
            .flatMap { p in self.snapPosition(for: p).map {(
                snapPosition: $0,
                opacity: opacity(for: p)
                )}
            }
            .sorted { (p1, p2) -> Bool in p1.snapPosition < p2.snapPosition }

        let prev = positions.last(where: { $0.snapPosition <= point })
        let next = positions.first(where: { $0.snapPosition > point })

        if let a = prev, let b = next {
            let n = (point - a.snapPosition) / (b.snapPosition - a.snapPosition)
            return a.opacity + (b.opacity - a.opacity) * n
        } else if let a = prev ?? next {
            return a.opacity
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
        //        print("gestureRecognizer:shouldRecognizeSimultaneouslyWith:\(otherGestureRecognizer)")
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

extension DrawerView: UIDynamicAnimatorDelegate {

    public func dynamicAnimatorWillResume(_ animator: UIDynamicAnimator) {
    }

    public func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        self.delegate?.drawer?(self, didTransitionTo: position)
        if let h = _originalHeight {
            self.frame.size.height = h
            _originalHeight = nil
        }
    }
}

extension CGRect {

    func insetBy(top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0) -> CGRect {
        return CGRect(
            x: self.origin.x + left,
            y: self.origin.y + top,
            width: self.size.width - left - right,
            height: self.size.height - top - bottom)
    }
}

extension Array {

    public func last(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return try self.filter(predicate).last
    }

}

extension DrawerPosition {

    func advance(by: Int, inPositions positions: [DrawerPosition]) -> DrawerPosition {
        guard !positions.isEmpty else {
            return self
        }

        let index = (positions.index(of: self) ?? 0)
        let nextIndex = max(0, min(positions.count - 1, index + by))

        return positions[nextIndex]
    }

}
