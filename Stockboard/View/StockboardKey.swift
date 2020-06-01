//
//  StockboardKey.swift
//  KeyboardKit
//
//  Created by Alex Man on 5/16/20.
//

import Foundation
import UIKit

import KeyboardKit

private class ButtonImage {
    static let globe = UIImage(systemName: "globe")
    static let backspace = UIImage(systemName: "delete.left")
    static let shift = UIImage(systemName: "shift")
    static let shiftFill = UIImage(systemName: "shift.fill")
    static let capLockFill = UIImage(systemName: "capslock.fill")
    // static let oneTwoThree = UIImage(systemName: "textformat.123")
}

extension KeyboardAction {
    var buttonFont: UIFont {
        return .preferredFont(forTextStyle: buttonFontStyle)
    }
    
    var buttonFontStyle: UIFont.TextStyle {
        switch self {
        case .character, .emoji: return .title2
        case .keyboardType(.emojis): return .title1
        default: return .body
        }
    }

    var buttonBgColor: UIColor {
        return isInputAction ? .white : .systemGray3
    }
    
    // TODO Return images < iOS 12
    var buttonImage: UIImage? {
        switch self {
        case .backspace: return ButtonImage.backspace
        case .nextKeyboard: return ButtonImage.globe
        case .shift: return ButtonImage.shift
        case .shiftDown: return ButtonImage.shiftFill
        case .capsLock: return ButtonImage.capLockFill
        // case .keyboardType(.numeric): return ButtonImage.oneTwoThree
        default: return nil
        }
    }
    
    var buttonText: String? {
        switch self {
        case .character(let text): return text
        case .newLine: return "return"
        case .space: return "space"
        case .keyboardType(.numeric): return "123"
        case .keyboardType(.symbolic): return "#+="
        case .keyboardType(.alphabetic(_)): return "ABC"
        default: return nil
        }
    }
    /*
    var buttonWidth: CGFloat {
        switch self {
        case .character: return LayoutContext.shared.activeLayoutConstants.keyButtonWidth
        // case .shift, .shiftDown, .capsLock, .backspace, .keyboardType(_): return LayoutContext.shared.activeLayoutConstants.shiftButtonWidth
        case .newLine: return LayoutContext.shared.activeLayoutConstants.systemButtonWidth * 1.5
        default: return LayoutContext.shared.activeLayoutConstants.systemButtonWidth
        }
    }*/
}

class StockboardKey: UIButton, ViewStateListener {
    private(set) var action: KeyboardAction = .none
    
    var hitTestFrame: CGRect?

    init(action: KeyboardAction) {
        super.init(frame: .zero)
        setupUIButton()
        setupAction(action)
    }
    
    private func setupUIButton() {
        let foregroundColor = UIColor(named: "keyForegroundColor")
        setTitleColor(foregroundColor, for: .normal)
        tintColor = foregroundColor
        
        isUserInteractionEnabled = true
        layer.cornerRadius = 5
        layer.shadowColor = UIColor(named: "keyShadowColor")?.resolvedColor(with: traitCollection).cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0.0
        layer.masksToBounds = false
        layer.cornerRadius = 5
    }
    
    private func setupAction(_ action: KeyboardAction) {
        backgroundColor = UIColor(named: action.isInputAction ? "inputKeyBackgroundColor" : "systemKeyBackgroundColor")
        
        if let buttonText = action.buttonText {
            setTitle(buttonText, for: .normal)
            titleLabel?.font = action.buttonFont
            titleLabel?.baselineAdjustment = .alignCenters
        } else if let buttonImage = action.buttonImage {
            setImage(buttonImage, for: .normal)
            self.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .light), forImageIn: .normal)
        }
        // isUserInteractionEnabled = action == .nextKeyboard
        self.action = action
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let hitTestFrame = hitTestFrame {
            if isHidden || window == nil { return false }
            // Translate hit test frame to hit test bounds.
            let hitTestBounds = hitTestFrame.offsetBy(dx: -frame.origin.x, dy: -frame.origin.y)
            return hitTestBounds.contains(point)
        } else {
            return super.point(inside: point, with: event)
        }
    }
    
    func onViewStateChanged(current: ViewState, changes: ViewState) {
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.shadowColor = UIColor(named: "keyShadowColor")?.resolvedColor(with: traitCollection).cgColor
    }
    
    // Forward all touch events to the superview.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesCancelled(touches, with: event)
    }
}
