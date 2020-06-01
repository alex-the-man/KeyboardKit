//
//  KeyDimensions.swift
//  Stockboard
//
//  Created by Alex Man on 5/14/20.
//

import Foundation
import UIKit

struct LayoutConstants {
    // Fixed:
    let keyViewTopInset = CGFloat(8)
    let keyViewBottomInset = CGFloat(3)


    // Provided:
    let keyboardSize: CGSize
    let keyButtonWidth: CGFloat
    let systemButtonWidth: CGFloat
    let shiftButtonWidth: CGFloat
    let widerSymbolButtonWidth: CGFloat
    let keyHeight: CGFloat
    let autoCompleteBarHeight: CGFloat
    let edgeHorizontalInset: CGFloat
    let keyViewHeight: CGFloat
    let keyRowGap: CGFloat
          
    // Computed:
    let buttonGap: CGFloat
    
    internal init(keyboardSize: CGSize,
                  inputKeyWidth: CGFloat,
                  systemKeyWidth: CGFloat,
                  shiftKeyWidth: CGFloat,
                  keyHeight: CGFloat,
                  autoCompleteBarHeight: CGFloat,
                  edgeHorizontalInset: CGFloat) {
        self.keyboardSize = keyboardSize
        self.keyButtonWidth = inputKeyWidth
        self.edgeHorizontalInset = edgeHorizontalInset
        self.shiftButtonWidth = shiftKeyWidth
        self.systemButtonWidth = systemKeyWidth
        self.keyHeight = keyHeight
        self.autoCompleteBarHeight = autoCompleteBarHeight
        
        buttonGap = (keyboardSize.width - 2 * edgeHorizontalInset - 10 * inputKeyWidth) / 9
        keyViewHeight = keyboardSize.height - autoCompleteBarHeight - keyViewTopInset - keyViewBottomInset
        keyRowGap = (keyViewHeight - 4 * keyHeight) / 3
        widerSymbolButtonWidth = (7 * inputKeyWidth + 6 * buttonGap - 4 * buttonGap) / 5
    }
}

let layoutConstantsList: [IntDuplet: LayoutConstants] = [
    // Portrait:
    // iPhone 11 Pro, X, Xs
    IntDuplet(375, 812): LayoutConstants(
        keyboardSize: CGSize(width: 375, height: 261),
        inputKeyWidth: 95 / 3,
        systemKeyWidth: 40,
        shiftKeyWidth: 46,
        keyHeight: 42,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 3),
    // Landscape:
    // iPhone 11 Pro, X, Xs
    IntDuplet(812, 375): LayoutConstants(
        keyboardSize: CGSize(width: 812, height: 188),
        inputKeyWidth: 60,
        systemKeyWidth: 59,
        shiftKeyWidth: 80,
        keyHeight: 30,
        autoCompleteBarHeight: 38,
        edgeHorizontalInset: 78 /*67 - 17 */),
]

/*
let layoutConstantsList: [IntDuplet: LayoutConstants] = [
    // Portrait:
    // iPhone SE, 8, 7, 6s, 6
    IntDuplet(375, 667): LayoutConstants(keyboardSize: CGSize(width: 375, height: 260), keyButtonWidth: 31.5, systemButtonWidth: 42, shiftButtonWidth: 42, keyHeight: 260 / 6, autoCompleteBarHeight: 45, edgeHorizontalInset: 3),
    // iPhone 11 Pro, X, Xs
    IntDuplet(375, 812): LayoutConstants(keyboardSize: CGSize(width: 375, height: 261), keyButtonWidth: 95 / 3, systemButtonWidth: 40, shiftButtonWidth: 46, keyHeight: 42, autoCompleteBarHeight: 45, edgeHorizontalInset: 3),
    // iPhone 11 Pro max, Xs Max, 11, Xr
    IntDuplet(414, 896): LayoutConstants(keyboardSize: CGSize(width: 414, height: 271), keyButtonWidth: 36, systemButtonWidth: 46, shiftButtonWidth: 46, keyHeight: 271 / 6, autoCompleteBarHeight: 45, edgeHorizontalInset: 4),
    // Landscape:
    // iPhone SE, 8, 7, 6s, 6
    IntDuplet(667, 375): LayoutConstants(keyboardSize: CGSize(width: 667, height: 200), keyButtonWidth: 46, systemButtonWidth: 63, shiftButtonWidth: 80, keyHeight: 200 / 6, autoCompleteBarHeight: 45, edgeHorizontalInset: 72.5 - 17),
    // iPhone 11 Pro, X, Xs
    IntDuplet(812, 375): LayoutConstants(keyboardSize: CGSize(width: 812, height: 188), keyButtonWidth: 60, systemButtonWidth: 59, shiftButtonWidth: 80, keyHeight: 30, autoCompleteBarHeight: 38, edgeHorizontalInset: 78 /*67 - 17 */),
    // iPhone 11 Pro max, Xs Max, 11, Xr
    IntDuplet(896, 414): LayoutConstants(keyboardSize: CGSize(width: 690, height: 187.5), keyButtonWidth: 50, systemButtonWidth: 65, shiftButtonWidth: 80, keyHeight: 187.5 / 6, autoCompleteBarHeight: 45, edgeHorizontalInset: 71 - 17),
]
*/

extension LayoutConstants {
    static func forMainScreen() -> LayoutConstants {
        getContants(screenSize: UIScreen.main.bounds.size)
    }
    
    static func getContants(screenSize: CGSize) -> LayoutConstants {
        // TODO instead of returning an exact match, return the nearest (floorKey?) match.
        guard let ret = layoutConstantsList[IntDuplet(Int(screenSize.width), Int(screenSize.height))] else {
            NSLog("Cannot find constants for (%f, %f). Defaulting to (375, 812)", screenSize.width, screenSize.height)
            return layoutConstantsList.first!.value
        }
        
        return ret
    }
}
