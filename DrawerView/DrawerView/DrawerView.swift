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
    case hidden = 4
}

private extension DrawerPosition {
    static let allValues: [DrawerPosition] = [
        .open,
        .partiallyOpen,
        .collapsed,
        .hidden
    ]
}

public class DrawerView: UIView {

    var panGesture: UIPanGestureRecognizer! = nil

    var originScrollView: UIScrollView? = nil
    var otherGestureRecognizer: UIGestureRecognizer? = nil

    var _offset: CGFloat = 0.0

    var scrollViewOffset: CGFloat = 0.0

    private var _position: DrawerPosition = .collapsed

    // MARK: Public properties

    public var topMargin: CGFloat = 68.0 {
        didSet {
            // TODO: Update position if collapsed.
        }
    }

    public var collapsedHeight: CGFloat = 68.0 {
        didSet {
            // TODO: Update position if collapsed.
        }
    }

    public var partiallyOpenHeight: CGFloat = 264.0 {
        didSet {
            // TODO: Update position if collapsed.
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    override public func layoutSubviews() {
    }

    private func setup() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            scrollViewOffset = 0.0
            self.isUserInteractionEnabled = false
            break
        case .changed:
            let translation = sender.translation(in: self)
            sender.setTranslation(CGPoint.zero, in: self)

//            _offset = _offset + translation.y
//            let offset = max(_offset, 0)

            // If scrolling upwards a scroll view, ignore the events.
            if let childScrollView = self.originScrollView {
                if childScrollView.contentOffset.y < 0 {
                    // Scrolling downwards and content was consumed, disable child scrolling
                    childScrollView.isScrollEnabled = false
                    childScrollView.contentOffset.y = 0
                }

                if !childScrollView.isScrollEnabled || childScrollView.contentOffset.y <= 0 {
                    self.frame.origin.y = self.frame.origin.y + translation.y
                }

                print("scrollViewOffset: \(scrollViewOffset)")
            } else {
                self.frame.origin.y = self.frame.origin.y + translation.y
            }


        case.failed:
            fallthrough
        case .ended:
            let velocity = sender.velocity(in: self)
            print("sender.state: \(sender.state.rawValue)")
            self.isUserInteractionEnabled = true
            self.originScrollView?.isScrollEnabled = true
            self.originScrollView = nil
            _offset = 0

            let pos = positionFor(offset: self.frame.origin.y)
            self.setPosition(pos, animated: true)
        default:
            break
        }

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
        case .hidden:
            return superview.bounds.height
        }
    }

    private func positionFor(offset: CGFloat) -> DrawerPosition {
        //let distanceFromOpen = offset
        let distances = DrawerPosition.allValues
            .flatMap { pos in snapPosition(for: pos).map { (pos: pos, y: $0) } }
            .sorted { (p1, p2) -> Bool in
                return abs(p1.y - offset) < abs(p2.y - offset)
        }

        return distances.first.map { $0.pos } ?? DrawerPosition.collapsed
    }

    public func setPosition(_ position: DrawerPosition, animated: Bool) {
        guard let superview = self.superview,
            let snapPosition = snapPosition(for: position) else {
            return
        }

        // Add extra height to make sure that bottom doesn't show up.
        let originalHeight = self.frame.size.height
        self.frame.size.height = self.frame.size.height * 1.5

        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: [], animations: {
            self.frame.origin.y = snapPosition
        }, completion: { (completed) in
            self.frame.size.height = originalHeight
        })

        _position = position
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

