//
//  GamePlayUI.swift
//  pikkproto
//
//  Created by Leo Nguyen on 8/19/25.
//

import Foundation
import UIKit

class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let myBox = UIView()
        
        myBox.backgroundColor = .systemBlue
        myBox.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        myBox.layer.cornerRadius = 12
        myBox.layer.shadowOpacity = 0.5
        
        view.addSubview (myBox)
        
        myBox.center = view.center
        myBox.center.y -= 50
        
        var SeqList: [SeqObj] = []
        
        //PLEASE CHANGE THIS TO A DIRECTION FLAG PLZ WHEN U GET THE SPRITES
        
//        let randSeq: [String] = ["up","left","right","down"]
        let randSeq: [UIColor] = [.red,.blue,.yellow,.green]
        class SeqObj {
//
//            let leftArrowImage = UIImage(named: "")
            var size: CGSize
            var position: CGPoint
            var direct : UIColor
            // for before getting sprites, just use the color to distinguish directions -- add image later
            init(size: CGSize, position: CGPoint, direct: UIColor) {
                self.size = size
                self.position = position
                self.direct = direct
            }
            
            func drawArrow (/*image: UIImage*/) -> UIView/* -> UIImageView*/ {
//                let IndivArrowView = UIImageView(image: image)
                let IndivArrowRect = CGRect(origin: position, size: size)
//                let IndivArrowView = UIImageView(frame: IndivArrowRect)
                let IndivArrowView = UIView(frame: IndivArrowRect)
                IndivArrowView.backgroundColor = direct
                return IndivArrowView
            }
            
        }
        func GenRandSeq (SeqLen: Int) {
            for Loop in 0..<SeqLen {
                if let chosenDir = randSeq.randomElement() {
                    
                    let widthChange = Int(view.bounds.width)/(2*SeqLen+1)
                    let xChange = 3/2 * widthChange + Loop * 2 * widthChange
                    
                    let tempVar = SeqObj(size: CGSize(width:widthChange,height:widthChange),position: CGPoint(x:xChange, y:700), direct: chosenDir)
                    
                    SeqList.append(tempVar)
                }
            }
        }
        
        GenRandSeq(SeqLen: 5)
        
        for obj in SeqList {
            let arrowView = obj.drawArrow()
            arrowView.layer.cornerRadius = 12
            arrowView.layer.shadowOpacity = 0.5
            view.addSubview(arrowView)
        }
    }
}
