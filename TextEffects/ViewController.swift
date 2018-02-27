//
//  ViewController.swift
//  TextEffects
//
//  Created by Zhe Xian Lee on 27/2/18.
//  Copyright © 2018 Zhe Xian Lee. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var textLayer: TextAnimationLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let font = UIFont(name: "Menlo", size: 100)
        let attr : [NSAttributedStringKey: Any] = [.font: font]
        let attrString = NSAttributedString(string: "A*😀", attributes: attr)
        
        textLayer = TextAnimationLayer(text: attrString)
        textLayer!.frame = CGRect(x: 50, y: 50, width: 300, height: 300)
        
        view.layer.addSublayer(textLayer!)
        textLayer?.setNeedsDisplay()
    }

    
    @IBAction func change(_ sender: UIButton) {
        let font = UIFont(name: "Arial", size: 30)
        let attr : [NSAttributedStringKey: Any] = [.font: font]
        let attrString = NSAttributedString(string: "😀😍😡)", attributes: attr)
        
        textLayer?.text = attrString
        textLayer?.setNeedsDisplay()
    }
    

}

class TextAnimationLayer: CALayer {
    
    var text: NSAttributedString {
        didSet {
            
            if let sublayers = self.sublayers {
                for layer in sublayers {
                    layer.removeFromSuperlayer()
                }
                self.sublayers = nil
            }
            
            let frameSetter = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
            let path = CGPath(rect: bounds, transform: nil)
            let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, text.length), path, nil)
            let lines = CTFrameGetLines(frame) as NSArray
            
            for (lineIndex, line) in lines.enumerated() {
                let line = line as! CTLine
                let runs = CTLineGetGlyphRuns(line) as NSArray
                let lineOriginsPtr = UnsafeMutablePointer<CGPoint>.allocate(capacity: runs.count)
                CTFrameGetLineOrigins(frame, CFRange(location: 0, length: lines.count ), lineOriginsPtr)
          
                for (runIndex, run) in runs.enumerated() {
                    let run = run as! CTRun
                    let runAttr = CTRunGetAttributes(run) as NSDictionary
                    let runFont = runAttr.value(forKey: "NSFont") as! CTFont
                    let glyphsCount = CTRunGetGlyphCount(run)
                    guard let glyphsPtr = CTRunGetGlyphsPtr(run),
                        let runPositions = CTRunGetPositionsPtr(run) else {
                            return
                    }
                    
                    if isEmojiFont(runFont) {
                        // Reference: https://developer.apple.com/library/content/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/CustomTextProcessing/CustomTextProcessing.html#//apple_ref/doc/uid/TP40009542-CH4-SW66
                        var ascent: CGFloat = 0
                        var descent: CGFloat = 0
                        var leading: CGFloat = 0
                        let runWidth: CGFloat = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: 0, length: glyphsCount), &ascent, &descent, &leading)) + 1
                        let runHeight: CGFloat = ascent + descent + leading
                        let advancesPtr = CTRunGetAdvancesPtr(run)
                        let emojiLayer = CoreTextRunLayer(run: run)
                        emojiLayer.ascent = ascent
                        emojiLayer.descent = descent
                        emojiLayer.leading = leading
                        emojiLayer.advance = advancesPtr?.pointee.width ?? 0
                        addSublayer(emojiLayer)
                        
                        let r = runPositions.advanced(by: runIndex).pointee
                        let l = lineOriginsPtr.advanced(by: lineIndex).pointee
                        
                        let origin = CGPoint(x: runPositions.advanced(by: runIndex).pointee.x, y: lineOriginsPtr.advanced(by: lineIndex).pointee.y - bounds.height + runHeight)
                        let size = CGSize(width: runWidth, height: runHeight)
                        emojiLayer.position = origin
                        emojiLayer.bounds = CGRect(origin: CGPoint.zero, size: size)
                        print(origin)
                        print(size)
                        emojiLayer.setNeedsDisplay()
                    }
                    else {
                        for i in 0..<glyphsCount {
                            
                        }
                    }
                }
            }
//            setAffineTransform(CGAffineTransform.init(scaleX: 1, y: -1).translatedBy(x: 0, y: bounds.size.height))
            isTextDirty = true
        }
    }
    
    var isTextDirty: Bool
    
    
    convenience override init() {
        self.init(text: NSAttributedString())
    }
    
    init(text: NSAttributedString) {
        self.text = text
        self.isTextDirty = true
        super.init()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func needsDisplay() -> Bool {
        return isTextDirty || super.needsDisplay()
    }
    
    override func draw(in ctx: CGContext) {
        ctx.setFillColor(UIColor.yellow.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
        isTextDirty = false
    }
    
    func isEmojiFont(_ font: CTFont) -> Bool {
        return CTFontCopyFamilyName(font) as String == "Apple Color Emoji"
    }
    
}

class CoreTextRunLayer : CALayer {
    
    let run : CTRun?
    
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    var advance: CGFloat = 0
    
    override convenience init() {
        self.init(run: nil)
    }
    
    init(run: CTRun?) {
        self.run = run
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(in ctx: CGContext) {
        guard let run = run else {
            return
        }
        ctx.fill(bounds)
        let glyphsCount = CTRunGetGlyphCount(run)
        ctx.textPosition = CGPoint(x: 0, y: descent + leading)
        ctx.translateBy(x: 0, y: bounds.size.height)
        ctx.scaleBy(x: 1, y: -1)
        CTRunDraw(run, ctx, CFRange(location: 0, length: glyphsCount))
    }
    
}
