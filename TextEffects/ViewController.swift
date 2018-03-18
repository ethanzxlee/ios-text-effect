//
//  ViewController.swift
//  TextEffects
//
//  Created by Zhe Xian Lee on 27/2/18.
//  Copyright © 2018 Zhe Xian Lee. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    
    var textLayer: TextAnimationLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        let font = UIFont(name: "Menlo", size: 20)
        let attr : [NSAttributedStringKey: Any] = [.font: font]
        let attrString = NSAttributedString(string: "abc rdefg😇😇", attributes: attr)
        textLayer = TextAnimationLayer(text: attrString)
        textLayer!.frame = CGRect(x: 40, y: 80, width: 300, height: 300)

        view.layer.addSublayer(textLayer!)
        textLayer?.setNeedsDisplay()
    }

    @IBAction func addText(_ sender: UIButton) {
        let font = UIFont(name: "Menlo", size: 20)
        let attr : [NSAttributedStringKey: Any] = [.font: font]
        let attrString = NSAttributedString(string: "Zapfino\nMenlo😇😇w\nwh😍at", attributes: attr)

        textLayer?.text = attrString
        textLayer?.setNeedsDisplay()
    }
    
    @IBAction func animateText(_ sender: UIButton) {
    }
    
}

struct TypographicBounds {
    
    var ascent: CGFloat = 0
    
    var descent: CGFloat = 0
    
    var leading: CGFloat = 0
    
    var width: CGFloat = 0
    
    var height: CGFloat {
        return ascent + descent + leading + 1
    }
    
    init() {
        
    }
    
    init(from run: CTRun) {
        let range = CFRange(location: 0, length: 0)
        width = CGFloat(CTRunGetTypographicBounds(run, range, &self.ascent, &self.descent, &self.leading)) + 1
    }
}


