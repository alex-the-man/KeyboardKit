//
//  StockboardKeyRow.swift
//  KeyboardKit
//
//  Created by Alex Man on 5/16/20.
//

import Foundation
import UIKit

import KeyboardKit

class StockboardKeyRow: UIView, ViewStateForwarder {
    enum RowLayoutMode {
        case normalRow, shiftRow, spaceBarRow
    }
    
    private var leftKeys, middleKeys, rightKeys: [StockboardKey]!
    var rowLayoutMode: RowLayoutMode = .normalRow
    
    init() {
        super.init(frame: .zero)
        
        insetsLayoutMarginsFromSafeArea = false
        preservesSuperviewLayoutMargins = true
        
        leftKeys = []
        middleKeys = []
        rightKeys = []
    }

    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    func setupRow(_ actionGroups: [[KeyboardAction]]) {
        assert(actionGroups.count == 1 || actionGroups.count == 3)
        
        // TODO Reuse keys.
        leftKeys.forEach { $0.removeFromSuperview() }
        leftKeys = []
        
        middleKeys.forEach { $0.removeFromSuperview() }
        middleKeys = []
        
        rightKeys.forEach { $0.removeFromSuperview() }
        rightKeys = []
        
        let leftActions, middleActions, rightActions: [KeyboardAction]
        if actionGroups.count == 1 {
            leftActions = []
            middleActions = actionGroups[0]
            rightActions = []
        } else {
            leftActions = actionGroups[0]
            middleActions = actionGroups[1]
            rightActions = actionGroups[2]
        }
        
        setupKeys(actions: leftActions, keys: &leftKeys)
        setupKeys(actions: middleActions, keys: &middleKeys)
        setupKeys(actions: rightActions, keys: &rightKeys)
    }
    
    private func setupKeys(actions: KeyboardActionRow?, keys: inout [StockboardKey]) {
        keys.forEach { $0.removeFromSuperview() }
        keys = actions?.map { StockboardKey(action: $0) } ?? []
        keys.forEach { addSubview($0) }
    }
    
    internal func onViewStateChanged(current: ViewState, changes: ViewState) {
        forwardToSubViews(current: current, changes: changes, subviews: subviews)
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

// Layout related coded.
extension StockboardKeyRow {
    private enum GroupLayoutDirection {
        case left, middle, right
    }
    
    override func layoutSubviews() {
        let layoutConstants = LayoutContext.shared.activeLayoutConstants
        
        // First, put the keys to where they should be.
        let leftKeyFrames = layoutKeys(leftKeys, direction: .left, layoutConstants: layoutConstants)
        let middleKeyFrames = layoutKeys(middleKeys, direction: .middle, layoutConstants: layoutConstants)
        let rightKeyFrames = layoutKeys(rightKeys, direction: .right, layoutConstants: layoutConstants)
        
        let allKeys = leftKeys + middleKeys + rightKeys
        var allFrames = leftKeyFrames + middleKeyFrames + rightKeyFrames
        
        // Special case, widen the space key to fill the empty space.
        if rowLayoutMode == .spaceBarRow && middleKeys.count == 1 && middleKeys.first!.action == .space {
            let thisKeyFrame = allFrames[leftKeyFrames.count]
            let spaceStartX = allFrames[leftKeyFrames.count - 1].maxX + layoutConstants.buttonGap
            let spaceEndX = allFrames[leftKeyFrames.count + middleKeyFrames.count].minX - layoutConstants.buttonGap
            allFrames[leftKeyFrames.count] = CGRect(x: spaceStartX, y: thisKeyFrame.minY, width: spaceEndX - spaceStartX, height: thisKeyFrame.maxY - thisKeyFrame.minY)
        }
        
        // Then, expand the keys to fill the void between keys.
        // In the stock keyboard, if the user tap between two keys, the event is sent to the nearest key.
        expandKeysToFillGap(allKeys, allFrames)
    }
    
    private func layoutKeys(_ keys: [StockboardKey], direction: GroupLayoutDirection, layoutConstants: LayoutConstants) -> [CGRect] {
        var x: CGFloat
        switch direction {
        case .left:
            x = directionalLayoutMargins.leading
        case .middle:
            let middleKeysCount = CGFloat(keys.count)
            let middleKeysWidth = keys.reduce(0, { $0 + getKeyWidth($1, layoutConstants) }) + (middleKeysCount - 1) * layoutConstants.buttonGap
            x = (bounds.width - middleKeysWidth) / 2
        case .right:
            let rightKeysCount = CGFloat(keys.count)
            let rightKeysWidth = keys.reduce(0, { $0 + getKeyWidth($1, layoutConstants) }) + (rightKeysCount - 1) * layoutConstants.buttonGap
            x = bounds.maxX - directionalLayoutMargins.trailing - rightKeysWidth
        }
        
        let frame: [CGRect] = keys.map { key in
            let keyWidth = getKeyWidth(key, layoutConstants)
            let rect = CGRect(x: x, y: layoutMargins.top, width: keyWidth, height: layoutConstants.keyHeight)
            x += keyWidth + layoutConstants.buttonGap
            
            return rect
        }
        return frame
    }
    
    private func expandKeysToFillGap(_ allKeys: [StockboardKey], _ allFrames: [CGRect]) {
        var startX = bounds.minX
        let allKeyCount = allKeys.count
        for (index, key) in allKeys.enumerated() {
            let isLastKey = index == allKeyCount - 1
            let thisKeyFrame = allFrames[index]
            
            key.frame = thisKeyFrame
            let midXBetweenThisAndNextKey = isLastKey ? bounds.maxX : (thisKeyFrame.maxX + allFrames[index + 1].minX) / 2
            let hitTestFrame = CGRect(x: startX, y: 0, width: midXBetweenThisAndNextKey - startX, height: bounds.height)
            key.hitTestFrame = hitTestFrame
            
            startX = midXBetweenThisAndNextKey
        }
    }
    
    private func getKeyWidth(_ key: StockboardKey, _ layoutConstants: LayoutConstants) -> CGFloat {
        switch rowLayoutMode {
        case .shiftRow:
            switch key.action {
            case .shift, .shiftDown, .capsLock, .backspace, .keyboardType(_):
                return layoutConstants.shiftButtonWidth
            case .character("."), .character(","), .character("?"), .character("!"), .character("'"):
                return layoutConstants.widerSymbolButtonWidth
            default:
                ()
            }
        case .spaceBarRow:
            if key.action == .newLine {
                return 1.5 * layoutConstants.systemButtonWidth
            }
        default:
            ()
        }
        return key.action.isInputAction ? layoutConstants.keyButtonWidth : layoutConstants.systemButtonWidth
    }
}
