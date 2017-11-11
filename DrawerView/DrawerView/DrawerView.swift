//
//  DrawerView.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 28/10/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit

public enum DrawerPosition: Int {
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
}

let kVelocityTreshold: CGFloat = 10.0

public class DrawerView: UIView {

    var panGesture: UIPanGestureRecognizer! = nil

    var originScrollView: UIScrollView? = nil
    var otherGestureRecognizer: UIGestureRecognizer? = nil

    var panOrigin: CGFloat = 0.0

    private var _position: DrawerPosition = .collapsed

    // MARK: Public properties

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    override public func layoutSubviews() {
        self.setPosition(self.position, animated: false)
    }

    private func setup() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)

        setInitialPosition()
    }

    private func setInitialPosition() {
        self.position = self.sorted(positions: self.supportedPositions).first ?? .collapsed
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            self.panOrigin = self.frame.origin.y
            break
        case .changed:
            let translation = sender.translation(in: self)

            // If scrolling upwards a scroll view, ignore the events.
            if let childScrollView = self.originScrollView {
                if childScrollView.contentOffset.y < 0 && childScrollView.isScrollEnabled {
                    // Scrolling downwards and content was consumed, so disable
                    // child scrolling and catch up with the offset.
                    self.panOrigin = self.panOrigin - childScrollView.contentOffset.y
                    childScrollView.isScrollEnabled = false

                    // Also animate to the proper scroll position.
                    UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                        childScrollView.contentOffset.y = 0
                        self.setPosition(forDragPoint: self.panOrigin + translation.y)
                    }, completion: nil)
                }

                // Scroll only if we're not scrolling the subviews.
                if !childScrollView.isScrollEnabled || childScrollView.contentOffset.y <= 0 {
                    setPosition(forDragPoint: panOrigin + translation.y)
                }
            } else {
                setPosition(forDragPoint: panOrigin + translation.y)
            }

        case.failed:
            fallthrough
        case .ended:
            let velocity = sender.velocity(in: self)

            if let childScrollView = self.originScrollView,
                childScrollView.contentOffset.y > 0 {
                // Let it scroll.
            } else {
                self.originScrollView?.isScrollEnabled = true
                self.originScrollView = nil

                // Check velocity and snap position separately:
                // 1) A treshold for velocity that makes drawer slide to the next state
                // 2) A prediction that estimates the next position based on target offset.
                // If 2 doesn't evaluate to the current position, use that.
                let targetOffset = self.frame.origin.y + velocity.y * 0.15
                let targetPosition = positionFor(offset: targetOffset)

                let velocitySign = velocity.y > 0 ? 1 : -1

                let nextPosition: DrawerPosition
                if targetPosition == self.position && abs(velocity.y) > kVelocityTreshold,
                    let pos = advance(from: targetPosition, by: velocitySign) {
                    nextPosition = pos
                } else {
                    nextPosition = targetPosition
                }

                self.setPosition(nextPosition, animated: true)
            }
        default:
            break
        }
    }

    private func advance(from position: DrawerPosition, by: Int) -> DrawerPosition? {
        let positions = self.sorted(positions: self.supportedPositions)

        let index = (positions.index(of: position) ?? 0)
        let nextIndex = max(0, min(positions.count - 1, index + by))

        return positions.isEmpty ? nil : positions[nextIndex]
    }

    private func sorted(positions: [DrawerPosition]) -> [DrawerPosition] {
        return positions
            .flatMap { pos in snapPosition(for: pos).map { (pos: pos, y: $0) } }
            .sorted { $0.y < $1.y }
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

    private func snapPositionForHidden() -> CGFloat? {
        return superview?.bounds.height
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

    func setPosition(forDragPoint dragPoint: CGFloat) {
        let bounds = self.supportedPositions
            .flatMap(snapPosition)
            .sorted()
        if let lowerBound = bounds.first, dragPoint < lowerBound {
            self.frame.origin.y = lowerBound - damp(value: lowerBound - dragPoint, factor: 50)
        } else if let upperBound = bounds.last, dragPoint > upperBound {
            self.frame.origin.y = upperBound + damp(value: dragPoint - upperBound, factor: 50)
        } else {
            self.frame.origin.y = dragPoint
        }
    }

    public func setPosition(_ position: DrawerPosition, animated: Bool) {
        guard let snapPosition = snapPosition(for: position) else {
            return
        }

        if animated {
            // Add extra height to make sure that bottom doesn't show up.
            let originalHeight = self.frame.size.height
            self.frame.size.height = self.frame.size.height * 1.5

            UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                self.frame.origin.y = snapPosition
            }, completion: { (completed) in
                self.frame.size.height = originalHeight
            })
        } else {
            self.frame.origin.y = snapPosition
        }

        _position = position
    }

    func damp(value: CGFloat, factor: CGFloat) -> CGFloat {
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
            self.originScrollView = sv
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.position == .open
            ? false
            : otherGestureRecognizer.view is UIScrollView
    }
}

extension CGPoint {

}
