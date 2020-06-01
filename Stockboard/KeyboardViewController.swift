//
//  KeyboardViewController.swift
//  Stockboard
//
//  Created by Alex Man on 5/14/20.
//
import Foundation
import UIKit

import KeyboardKit

class AutocompleteProvider: AutocompleteSuggestionProvider {
    private let lexicon: UILexicon
    private var textChecker: UITextChecker!
    
    init(lexicon: UILexicon) {
        self.lexicon = lexicon
        
        textChecker = UITextChecker()
    }
    
    func autocompleteSuggestions(for text: String, completion: AutocompleteResponse) {
        guard text.count > 0 else { return completion(.success([])) }
        
        print(lexicon.entries.count)
        for entry in lexicon.entries {
            print(entry.documentText)
            if text == entry.userInput {
                print(entry.documentText)
            }
        }
        
        let guess = textChecker.guesses(forWordRange: NSRange(location: 0, length: text.count), in: text, language: "en")
        print(guess)
        
        let comp = textChecker.completions(forPartialWordRange: NSRange(location: 0, length: text.count), in: text, language: "en")
        print(comp)
        
        let suffixes = ["ly", "er", "ter"]
        let suggestions = suffixes.map { text + $0 }
        completion(.success(suggestions))
    }
}

class KeyboardViewController: KeyboardInputViewController, ViewStateForwarder {
    private var dynamicConstraintManager: DynamicConstraintManager = DynamicConstraintManager()
    
    private var englishKeyboardView: StockboardAlphabeticView?
    private var viewState = ViewState(screenSize: nil, darkAppearance: nil)
    private var autocompleteProvider: AutocompleteProvider?
    
    /*
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LayoutContext.shared.activeLayoutConstants = LayoutConstants.forMainScreen()
        dynamicConstraintManager.add(view.heightAnchor, equalToConstantProvider: LayoutContext.shared.bind { $0.keyboardSize.height }, priority: .defaultHigh)
        
        createKeyboard()
        
        requestSupplementaryLexicon { self.autocompleteProvider = AutocompleteProvider(lexicon: $0) }
    }
        
    /*
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LayoutContext.shared.activeLayoutConstants = LayoutConstants.getContants(screenSize: view.window!.screen.bounds.size)
    }
     */
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        let oldSize = UIScreen.main.bounds.size
        let shortEdge = min(oldSize.width, oldSize.height)
        let longEdge = max(oldSize.width, oldSize.height)
        let newSize = toInterfaceOrientation.isPortrait ? CGSize(width: shortEdge, height: longEdge) : CGSize(width: longEdge, height: shortEdge)
        
        if viewState.screenSize != newSize {
            onViewStateChanged(current: viewState, changes: ViewState(screenSize: newSize, darkAppearance: nil))
        }
        
        super.willRotate(to: toInterfaceOrientation, duration: duration)
    }
    
    func createKeyboard() {
        if englishKeyboardView == nil {
            let englishKeyboardView = StockboardAlphabeticView(frame: view.frame)
            englishKeyboardView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(englishKeyboardView)
            
            NSLayoutConstraint.activate([
                englishKeyboardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                englishKeyboardView.topAnchor.constraint(equalTo: view.topAnchor),
                englishKeyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            
            dynamicConstraintManager.add(englishKeyboardView.widthAnchor, equalToConstantProvider: LayoutContext.shared.bind { $0.keyboardSize.width })
            englishKeyboardView.delegate = self
            self.englishKeyboardView = englishKeyboardView
        }
    }
    
    func destroyKeyboard() {
        englishKeyboardView?.removeFromSuperview()
        englishKeyboardView = nil
    }
    
    internal func onViewStateChanged(current: ViewState, changes: ViewState) {
        if let screenSize = changes.screenSize {
            LayoutContext.shared.activeLayoutConstants = LayoutConstants.getContants(screenSize: screenSize)
            dynamicConstraintManager.update()
        }
        
        forwardToSubViews(current: current, changes: changes, subviews: view.subviews)
        
        viewState = viewState.mutate(changes: changes)
    }
}

extension KeyboardViewController: BaseboardViewDelegate {
    func sendKey(_ action: KeyboardAction) {
        switch(action) {
        case .moveCursorForward:
            print("moveCursorForward")
            textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
        case .moveCursorBackward:
            print("moveCursorBackward")
            textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
        case let .character(c):
            print("Typing", c)
            textDocumentProxy.insertText(c)
        case .space:
            print("Typing space")
            textDocumentProxy.insertText(" ")
            requestAutocompleteSuggestions()
        case .newLine:
            print("New line")
            textDocumentProxy.insertText("\n")
        case .backspace:
            print("Delete backward")
            textDocumentProxy.deleteBackward()
        default:
            ()
        }
    }
}

extension KeyboardViewController {
    func requestAutocompleteSuggestions() {
        let word = "does" // textDocumentProxy.currentWord ?? ""
        // print("word", word)

        autocompleteProvider?.autocompleteSuggestions(for: word) { [weak self] in
            self?.handleAutocompleteSuggestionsResult($0)
        }
    }
    
    func handleAutocompleteSuggestionsResult(_ result: AutocompleteResult) {
        switch result {
        case .failure(let error): print(error.localizedDescription)
        case .success(let result): print(result)
        }
    }
}
