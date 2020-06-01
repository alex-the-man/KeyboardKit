//
//  ViewState.swift
//  KeyboardKit
//
//  Created by Alex Man on 5/16/20.
//

import Foundation
import UIKit

// This is the view state of the application.
// KeyboardVIewController owns the the view state.
// UIView instances observe for changes of the view state and update their views.
struct ViewState {
    let screenSize: CGSize?
    let darkAppearance: Bool?
    
    func mutate(changes: ViewState) -> ViewState {
        return ViewState(
            screenSize: changes.screenSize ?? screenSize,
            darkAppearance: changes.darkAppearance ?? darkAppearance)
    }
}

protocol ViewStateListener {
    func onViewStateChanged(current: ViewState, changes: ViewState)
}

// Forward ViewState events to subviews.
protocol ViewStateForwarder: ViewStateListener { }

extension ViewStateForwarder {
    func forwardToSubViews(current: ViewState, changes: ViewState, subviews: [UIView]) {
        subviews.forEach { subview in
            if let viewStateListeningSubView = subview as? ViewStateListener {
                viewStateListeningSubView.onViewStateChanged(current: current, changes: changes)
            }
        }
    }
}
