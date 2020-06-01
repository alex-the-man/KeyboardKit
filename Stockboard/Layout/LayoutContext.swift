//
//  LayoutContext.swift
//  KeyboardKit
//
//  Created by Alex Man on 5/16/20.
//

import Foundation
import UIKit

class LayoutContext {
    // TODO Is this thread safe?
    static let shared: LayoutContext = LayoutContext(activeLayoutConstants: LayoutConstants.forMainScreen())
    
    var activeLayoutConstants: LayoutConstants
    
    private init(activeLayoutConstants: LayoutConstants) {
        self.activeLayoutConstants = activeLayoutConstants
    }
    
    func bind(_ f: @escaping (LayoutConstants) -> CGFloat) -> (() -> CGFloat) {
        return { return f(self.activeLayoutConstants) }
    }
}
