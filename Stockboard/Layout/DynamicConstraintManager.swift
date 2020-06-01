//
//  ConstraintUpdater.swift
//  KeyboardKit
//
//  Created by Alex Man on 5/16/20.
//

import Foundation
import UIKit

// Use this to create dynamically adjusted constraint.
// It's written to create constant constraint that has changing constant value (e.g. different width with different screen orientation).
class DynamicConstraintManager {
    // A wrapper to update NSLayoutConstraint with constant.
    // Instead of a hardcoded constant, it accepts a function returning the constant.
    // update() will re-evalulate the constant and update the constant in the constraint.
    // This owns the constantProvider.
    class ConstraintHolder {
        weak var constraint: NSLayoutConstraint? // Don't hold a strong ref to constraint to avoid mem leak.
        let constantProvider: () -> CGFloat
        
        init(_ constraint: NSLayoutConstraint, constantProvider: @escaping () -> CGFloat) {
            self.constraint = constraint
            self.constantProvider = constantProvider
        }
        
        func update() {
            if let constraint = constraint { constraint.constant = constantProvider() }
        }
    }
    
    private var constraints: [ConstraintHolder] = []
    
    func add(_ subject: NSLayoutDimension,
             equalToConstantProvider cf: @escaping () -> CGFloat,
             isActive: Bool = true,
             priority: UILayoutPriority = .required) {
        let actualConstraint = subject.constraint(equalToConstant: cf())
        actualConstraint.priority = priority
        actualConstraint.isActive = isActive
        
        constraints.append(ConstraintHolder(actualConstraint, constantProvider: cf))
    }
    
    // These methods return an inactive constraint of the form thisAnchor = otherAnchor * multiplier + constant.
    func add<AnchorType>(_ subject: NSLayoutAnchor<AnchorType>,
                         equalTo anchor: NSLayoutAnchor<AnchorType>,
                         constantProvider cf: @escaping () -> CGFloat,
                         isActive: Bool = true,
                         priority: UILayoutPriority = .required) {
        let actualConstraint = subject.constraint(equalTo: anchor, constant: cf())
        actualConstraint.priority = priority
        actualConstraint.isActive = isActive
        
        constraints.append(ConstraintHolder(actualConstraint, constantProvider: cf))
    }
    
    func update() {
        constraints.forEach { $0.update() }
    }
    
    func removeAll() {
        constraints.removeAll()
    }
}
