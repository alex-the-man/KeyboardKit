//
//  ViewController.swift
//  StockboardApp
//
//  Created by Alex Man on 5/14/20.
//

import UIKit

import Stockboard

class ViewController: UIViewController {
    var keyboard: KeyboardViewController?
    var create: Bool = false
    
    func recreateKeyboard() {
        if let keyboard = keyboard {
            if self.create {
                keyboard.createKeyboard()
            } else {
                keyboard.destroyKeyboard()
            }
            self.create = !self.create
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1 / 30) {
            self.recreateKeyboard()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keyboard = KeyboardViewController()
        self.keyboard = keyboard
        keyboard.view.translatesAutoresizingMaskIntoConstraints = false
        
        view.backgroundColor = .systemGray5
        view.addSubview(keyboard.view)
        addChild(keyboard)
        
        NSLayoutConstraint.activate([
            keyboard.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            keyboard.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            keyboard.view.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])

        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.recreateKeyboard()
        }
 */
    }
}
