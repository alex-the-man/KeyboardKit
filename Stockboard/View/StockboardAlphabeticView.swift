
//
//  AlphabeticButtons.swift
//  Stockboard
//
//  Created by Alex Man on 5/15/20.
//

import Foundation
import UIKit

import KeyboardKit

protocol BaseboardViewDelegate: class {
    func sendKey(_ action: KeyboardAction)
    func handleInputModeList(from view: UIView, with event: UIEvent)
}

class TouchHandler {
    enum InputMode: Equatable {
        case idle, typing(oneOff: Bool), backspacing, nextKeyboard, cursorMoving
    }
    private static let KeyRepeatInterval = 0.11
    private static let cursorMovingThreshold = CGFloat(5)
    
    var handleKey: ((KeyboardAction) -> ())?
    var handleInputModeList: ((UIView, UIEvent) -> ())?
    
    private var currentTouch: (UITouch, StockboardKey)?
    private var cursorMoveStartPosition: CGPoint?
    private var movedCursor = false
    private var inputMode: InputMode = .idle
    private var keyRepeatTimer: Timer?
    private var keyRepeatCounter: Int = 0
    private var keyView: UIView
    
    init(keyView: UIView) {
        self.keyView = keyView
    }
    
    func touchBegan(_ touch: UITouch, key: StockboardKey, with event: UIEvent?) {
        keyRepeatCounter = 0
        if inputMode == .idle && key.action == .nextKeyboard {
            inputMode = .nextKeyboard
            currentTouch = (touch, key)
            guard let event = event else { return }
            handleInputModeList?(key, event)
        } else if inputMode == .idle && key.action == .backspace {
            inputMode = .backspacing
            currentTouch = (touch, key)
            handleKey?(.backspace)
        } else {
            if key.action == .shift || key.action == .shiftDown {
                // TODO Handle double tap.
                handleKey?(key.action)
            } else if case .keyboardType(_) = key.action {
                handleKey?(key.action)
            } else if
                // The the user is multi-touching multiple characters, end the older character touch.
                // Ignore any non character touch.
                case .character(_) = key.action,
                let currentTouch = currentTouch,
                case .character(_) = currentTouch.1.action {
                touchEnded(currentTouch.0, key: currentTouch.1, with: event)
            }
            
            currentTouch = (touch, key)
            inputMode = .typing(oneOff: false)
        }
        setupKeyRepeatTimer()
    }
    
    func touchMoved(_ touch: UITouch, key: StockboardKey, with event: UIEvent?) {
        if inputMode == .backspacing {
            return
        } else if
            // TODO fix tap up after small movement, send space.
            let lastAction = currentTouch?.1.action,
            case .typing(oneOff: _) = inputMode,
            lastAction == .space {
            inputMode = .cursorMoving
            cursorMoveStartPosition = touch.location(in: keyView)
            movedCursor = false
            return
        } else if let cursorMoveStartPosition = cursorMoveStartPosition, inputMode == .cursorMoving {
            let point = touch.location(in: keyView)
            var dX = point.x - cursorMoveStartPosition.x
            let isLeft = dX < 0
            dX = isLeft ? -dX : dX
            while dX > TouchHandler.cursorMovingThreshold {
                dX -= TouchHandler.cursorMovingThreshold
                handleKey?(isLeft ? .moveCursorBackward : .moveCursorForward)
                movedCursor = true
            }
            
            self.cursorMoveStartPosition = point
            self.cursorMoveStartPosition!.x -= isLeft ? -dX : dX
            return
        } else if inputMode == .nextKeyboard {
            guard let event = event, key.action == .nextKeyboard else { return }
            handleInputModeList?(key, event)
        }
        
        guard let currentTouch = currentTouch, currentTouch.0 == touch else { return }
        
        setupKeyRepeatTimer()
    }
    
    func touchEnded(_ touch: UITouch, key: StockboardKey?, with event: UIEvent?) {
        guard let currentTouch = currentTouch, currentTouch.0 == touch else { return }
        defer {
            self.currentTouch = nil
            inputMode = .idle
        }
        
        // Reset key repeat timer.
        cancelKeyRepeatTimer()
        
        if self.inputMode == .backspacing {
            return
        } else if self.inputMode == .cursorMoving && !movedCursor {
            handleKey?(key!.action)
        } else if inputMode == .nextKeyboard {
            inputMode = .idle
            guard let event = event, let key = key, key.action == .nextKeyboard else { return }
            handleInputModeList?(key, event)
        }
        
        guard case .typing(oneOff: _) = inputMode else { return }
        switch key?.action {
        case .character, .space, .newLine:
            handleKey?(key!.action)
        default:
            ()
        }
    }
    
    func touchCancelled(_ touch: UITouch, with event: UIEvent?) {
        cancelKeyRepeatTimer()
        
        currentTouch = nil
        inputMode = .idle
    }
    
    private func onKeyRepeat(_ timer: Timer) {
        guard timer == self.keyRepeatTimer else { return } // Timer was invalidated.
        keyRepeatCounter += 1
        if keyRepeatCounter > 1 && self.inputMode == .backspacing {
            handleKey?(.backspace)
            return
        }
    }
    
    private func setupKeyRepeatTimer() {
        keyRepeatTimer?.invalidate()
        keyRepeatCounter = 0
        keyRepeatTimer = Timer.scheduledTimer(withTimeInterval: TouchHandler.KeyRepeatInterval, repeats: true, block: self.onKeyRepeat)
    }
    
    private func cancelKeyRepeatTimer() {
        keyRepeatTimer?.invalidate()
        keyRepeatTimer = nil
    }
}

class StockboardAlphabeticView: UIView, ViewStateForwarder {
    private var touchHandler: TouchHandler!
    private var keyRows: [StockboardKeyRow]!
    private var keyboardType = KeyboardType.alphabetic(.lowercased)
    
    weak var delegate: BaseboardViewDelegate?
    
    private let englishLettersKeyCapRows: [[[KeyboardAction]]] = [
        [["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]],
        [["a", "s", "d", "f", "g", "h", "j", "k", "l"]],
        [[.shift], ["z", "x", "c", "v", "b", "n", "m"], [.backspace]],
        [[.keyboardType(.numeric), .nextKeyboard], [.space], [".", .newLine]]
    ]
    
    private let numbersKeyCapRows: [[[KeyboardAction]]] = [
        [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]],
        [["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""]],
        [[.keyboardType(.symbolic)], [".", ",", "?", "!", "'"], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space], [".", .newLine]]
    ]
    
    private let symbolsKeyCapRows: [[[KeyboardAction]]] = [
        [["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]],
        [["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"]],
        [[.keyboardType(.numeric)], [".", ",", "?", "!", "'"], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space], [".", .newLine]]
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clearInteractable
        insetsLayoutMarginsFromSafeArea = false
        isMultipleTouchEnabled = true
        preservesSuperviewLayoutMargins = false

        touchHandler = TouchHandler(keyView: self)
        touchHandler.handleKey = handleKey
        touchHandler.handleInputModeList = handleInputModeList
        
        keyRows = (0..<4).map { i in StockboardKeyRow() }
        keyRows[2].rowLayoutMode = .shiftRow
        keyRows[3].rowLayoutMode = .spaceBarRow
        keyRows.forEach { addSubview($0) }
        
        setupRows()
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    internal func onViewStateChanged(current: ViewState, changes: ViewState) {
        forwardToSubViews(current: current, changes: changes, subviews: subviews)
    }
    
    override func layoutSubviews() {
        let layoutContext = LayoutContext.shared.activeLayoutConstants
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: layoutContext.keyViewTopInset,
                                                           leading: layoutContext.edgeHorizontalInset,
                                                           bottom: layoutContext.keyViewBottomInset,
                                                           trailing: layoutContext.edgeHorizontalInset)
        
        let keyRowsMargin: [NSDirectionalEdgeInsets] = (0..<keyRows.count).map {
            switch $0 {
            case 0: // First key row
                return NSDirectionalEdgeInsets(top: layoutContext.keyViewTopInset, leading: 0, bottom: layoutContext.keyRowGap / 2, trailing: 0)
            case keyRows.count - 1: // Last key row
                return NSDirectionalEdgeInsets(top: layoutContext.keyRowGap / 2, leading: 0, bottom: layoutContext.keyViewBottomInset, trailing: 0)
            default: // Middle rows
                return NSDirectionalEdgeInsets(top: layoutContext.keyRowGap / 2, leading: 0, bottom: layoutContext.keyRowGap / 2, trailing: 0)
            }
        }
        
        let keyRowsHeight: [CGFloat] = keyRowsMargin.map { $0.top + layoutContext.keyHeight + $0.bottom }
        
        var currentY: CGFloat = layoutContext.autoCompleteBarHeight
        let keyRowsY: [CGFloat] = (0..<keyRows.count).map { (currentY, currentY += keyRowsHeight[$0]).0 }
                
        for (index, keyRowY) in keyRowsY.enumerated() {
            let keyRow = keyRows[index]
            keyRow.frame = CGRect(x: 0, y: keyRowY, width: frame.width, height: keyRowsHeight[index])
            keyRow.directionalLayoutMargins = keyRowsMargin[index]
        }
    }
    
    private func setupRows() {
        switch keyboardType {
        case let .alphabetic(shiftState):
            for (index, var keyCaps) in englishLettersKeyCapRows.enumerated() {
                if shiftState != .lowercased {
                    keyCaps = keyCaps.map { $0.map {
                        switch $0 {
                        case let .character(c):
                            return .character(c.uppercased())
                        case .shift:
                            return shiftState == .capsLocked ? .capsLock : .shiftDown
                        default:
                            return $0
                        }
                    } }
                }
                keyRows[index].setupRow(keyCaps)
            }
        case .numeric:
            for (index, keyCaps) in numbersKeyCapRows.enumerated() {
                keyRows[index].setupRow(keyCaps)
            }
        case .symbolic:
            for (index, keyCaps) in symbolsKeyCapRows.enumerated() {
                keyRows[index].setupRow(keyCaps)
            }
        default:
            ()
        }
    }
}

extension StockboardAlphabeticView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        for touch in touches {
            guard let key = findTouchingKey(touches, with: event) else { continue }
            touchHandler.touchBegan(touch, key: key, with: event)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        for touch in touches {
            guard let key = findTouchingKey(touches, with: event) else { continue }
            touchHandler.touchMoved(touch, key: key, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        for touch in touches {
            let key = findTouchingKey(touches, with: event)
            touchHandler.touchEnded(touch, key: key, with: event)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        for touch in touches {
            touchHandler.touchCancelled(touch, with: event)
        }
    }
    
    private func findTouchingKey(_ touches: Set<UITouch>, with event: UIEvent?) -> StockboardKey? {
        guard let touch = touches.first else { return nil }
        let touchPoint = touch.location(in: self)
        let touchingView = super.hitTest(touchPoint, with: event)
        return touchingView as? StockboardKey
    }
    
    private func findTouchingKeys(_ touches: Set<UITouch>, with event: UIEvent?) -> [StockboardKey] {
        return touches.compactMap { touch in
            let touchPoint = touch.location(in: self)
            let touchingView = super.hitTest(touchPoint, with: event)
            return touchingView as? StockboardKey
        }
    }
    
    private func handleKey(_ action: KeyboardAction) {
        switch action {
        case .shift:
            keyboardType = .alphabetic(.uppercased)
            setupRows()
        case .shiftDown:
            keyboardType = .alphabetic(.lowercased)
            setupRows()
        case .keyboardType(.alphabetic(_)):
            keyboardType = .alphabetic(.lowercased)
            setupRows()
        case .keyboardType(.numeric):
            keyboardType = .numeric
            setupRows()
        case .keyboardType(.symbolic):
            keyboardType = .symbolic
            setupRows()
        default:
            delegate?.sendKey(action)
        }
    }
    
    private func handleInputModeList(view: UIView, event: UIEvent) {
        delegate?.handleInputModeList(from: view, with: event)
    }
}
