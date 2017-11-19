//
//  DrawerBehavior.swift
//  DrawerView
//
//  Created by Mikko Välimäki on 16/11/2017.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit

class DrawerBehavior: UIDynamicBehavior {

    let attachmentBehavior: UIAttachmentBehavior
    let itemBehavior: UIDynamicItemBehavior
    let item: UIDynamicItem

    var velocity: CGPoint {
        didSet {
            let currentVelocity = self.itemBehavior.linearVelocity(for: item)
            let velocityDelta = CGPoint(x: 0, y: velocity.y - currentVelocity.y)
            self.itemBehavior.addLinearVelocity(velocityDelta, for: item)
        }
    }

    var targetPoint: CGPoint {
        didSet {
            attachmentBehavior.anchorPoint = targetPoint
        }
    }

    init(item: UIDynamicItem) {
        self.item = item
        self.velocity = CGPoint()
        self.targetPoint = CGPoint()

        let attachmentBehavior = UIAttachmentBehavior(item: item, attachedToAnchor: item.center)
        attachmentBehavior.frequency = 3.5
        attachmentBehavior.damping = 0.4
        attachmentBehavior.length = 0
        self.attachmentBehavior = attachmentBehavior

        let itemBehavior = UIDynamicItemBehavior(items: [item])
        itemBehavior.density = 100
        itemBehavior.resistance = 10
        itemBehavior.allowsRotation = false
        self.itemBehavior = itemBehavior

        super.init()

        self.addChildBehavior(attachmentBehavior)
        self.addChildBehavior(itemBehavior)

    }



}
