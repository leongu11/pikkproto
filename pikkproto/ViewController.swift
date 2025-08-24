//
//  ViewController.swift
//  pikkproto
//
//  Created by Leo Nguyen on 8/19/25.
//

import UIKit

class ViewController: UIViewController {

    let trackLogic = CameraViewController()
    let gameUI = GameViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(gameUI)
        view.addSubview(gameUI.view)
        gameUI.didMove(toParent: self)
        
        view.backgroundColor = .white
        
        trackLogic.viewDidLoad()
        
//        trackLogic.onUpdate = { [weak self] newFrame in
//            self?.gameUI.updateBoxFrame(newFrame)
        
    }
}

