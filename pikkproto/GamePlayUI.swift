//
//  GamePlayUI.swift
//  pikkproto
//
//  Created by Leo Nguyen on 8/19/25.
//

import Foundation
import UIKit


class GameViewController: UIViewController {
    
    var DetectedDir: String = "none"
    var SeqList: [SeqObj] = []
    var SeqView: [UIView] = []
    
    class SeqObj {
        //
        //            let leftArrowImage = UIImage(named: "")
        var size: CGSize
        var position: CGPoint
        var direct : String
        var colorfordirect : UIColor
        // for before getting sprites, just use the color to distinguish directions -- add image later
        init(size: CGSize, position: CGPoint, colorfordirect: UIColor, direct: String) {
            self.size = size
            self.position = position
            self.colorfordirect = colorfordirect
            self.direct = direct
        }
        
        func drawArrow (/*image: UIImage*/) -> UIView/* -> UIImageView*/ {
            //                let IndivArrowView = UIImageView(image: image)
            let IndivArrowRect = CGRect(origin: position, size: size)
            //                let IndivArrowView = UIImageView(frame: IndivArrowRect)
            let IndivArrowView = UIView(frame: IndivArrowRect)
            IndivArrowView.backgroundColor = colorfordirect
            return IndivArrowView
        }
        
    }

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
        
        //PLEASE CHANGE THIS TO A DIRECTION FLAG PLZ WHEN U GET THE SPRITES
                
        let OGrandSeq: [String] = ["up","left","right","down"]
        
        let randSeq: [UIColor] = [.red,.blue,.yellow,.green]
        
        func GenRandSeq (SeqLen: Int) {
            for Loop in 0..<SeqLen {
                if let chosenDir = OGrandSeq.randomElement() {
                    // will have to accomodate to arrow sizes and such
                    if let chosenindCol = OGrandSeq.firstIndex(of: chosenDir) {
                        
                        let widthChange = Int(view.bounds.width)/(8)
                        //lazy
                        let xChange = 13/10 * widthChange + Loop * 2 * widthChange - 20
                        
                        let tempVar = SeqObj(size: CGSize(width:widthChange,height:widthChange),position: CGPoint(x:xChange, y:700), colorfordirect: randSeq[chosenindCol], direct: chosenDir)
                        
                        SeqList.append(tempVar)
                    }
                }
            }
        }
        // work on detect and delete later
        //        func SeqListRemove(object: SeqObj) {
        //            SeqList.remove(object)
        //        }
        
        GenRandSeq(SeqLen: 5)
        
        for obj in SeqList {
            let arrowView = obj.drawArrow()
            arrowView.layer.cornerRadius = 12
            arrowView.layer.shadowOpacity = 0.5
            view.addSubview(arrowView)
            
            SeqView.append(arrowView)
        }
    }
    
    func updateArrowShow() {
        for (index, SeqView) in SeqView.enumerated() {
            if index < SeqList.count {
                let newPos = SeqList[index].position
                SeqView.frame.origin = newPos
            }
        }
    }
    func updateDirection(_ direction: String) {
        print("Got dir:", direction)
        DetectedDir = direction
        if SeqList.isEmpty == false {
            print(DetectedDir,SeqList[0].direct)
            if DetectedDir == SeqList[0].direct {
                SeqList.remove(at: 0)
                let remView = SeqView.removeFirst()
                remView.removeFromSuperview()
                for obj in SeqList {
                    obj.position.x -= CGFloat(2*(Int(view.bounds.width)/8))
                    updateArrowShow()
                }
            }
        }
    }
}

        //rn this is js shifting the arrow to get off the screen for each move -- may wanna remove longrun

//            if obj.direct == DetectedDir {
//                SeqListRemove(obj: SeqObj)
//            }
            
            //swipeUpdate
            
            //}
        

        
    

