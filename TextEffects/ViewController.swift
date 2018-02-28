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
        let attrString = NSAttributedString(string: "-", attributes: attr)
        
        textLayer = TextAnimationLayer(text: attrString)
        textLayer!.frame = CGRect(x: 50, y: 50, width: 300, height: 300)
        
        view.layer.addSublayer(textLayer!)
        textLayer?.setNeedsDisplay()
    }

    
    @IBAction func change(_ sender: UIButton) {
        let font = UIFont(name: "Zapfino", size: 50)
        let attr : [NSAttributedStringKey: Any] = [.font: font]
        let attrString = NSAttributedString(string: "app", attributes: attr)
        
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
                            continue
                    }
                    
                    if isEmojiFont(runFont) {
                        // Reference: https://developer.apple.com/library/content/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/CustomTextProcessing/CustomTextProcessing.html#//apple_ref/doc/uid/TP40009542-CH4-SW66
                        var ascent: CGFloat = 0
                        var descent: CGFloat = 0
                        var leading: CGFloat = 0
                        let runWidth: CGFloat = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &ascent, &descent, &leading)) + 1
                        let runHeight: CGFloat = ascent + descent + leading
                        let advancesPtr = CTRunGetAdvancesPtr(run)
                        
                        let emojiLayer = CoreTextRunLayer(run: run)
                        emojiLayer.ascent = ascent
                        emojiLayer.descent = descent
                        emojiLayer.leading = leading
                        emojiLayer.advance = advancesPtr?.pointee.width ?? 0
                        
                        let origin = CGPoint(x: runPositions.pointee.x, y: bounds.height - lineOriginsPtr.advanced(by: lineIndex).pointee.y + descent + leading)
                        let size = CGSize(width: runWidth, height: runHeight)
                        emojiLayer.anchorPoint = CGPoint(x: 0, y: 1)
                        emojiLayer.position = origin
                        emojiLayer.bounds = CGRect(origin: CGPoint.zero, size: size)
                        
                        self.addSublayer(emojiLayer)
                        emojiLayer.setNeedsDisplay()
                    }
                    else {
                        for i in 0..<glyphsCount {
                            guard let glyphPtr = CTRunGetGlyphsPtr(run) else {
                                continue
                            }
                            
                            let glyph = glyphPtr.advanced(by: i).pointee
                            
                            guard let glyphPath = CTFontCreatePathForGlyph(runFont, glyph, nil) else {
                                continue
                            }
                            
                            var ascent: CGFloat = 0
                            var descent: CGFloat = 0
                            var leading: CGFloat = 0
                            let runWidth: CGFloat = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: i, length: 1), &ascent, &descent, &leading)) + 1
                            let runHeight: CGFloat = ascent + descent + leading
                            let advancesPtr = CTRunGetAdvancesPtr(run)
                            let origin = CGPoint(x: runPositions.advanced(by: i).pointee.x, y: bounds.height - lineOriginsPtr.advanced(by: lineIndex).pointee.y)
                            print(origin, runHeight)
                            let shapeLayer = CAShapeLayer()
                            shapeLayer.path = glyphPath
//                            shapeLayer.backgroundColor = UIColor.orange.cgColor
                            shapeLayer.anchorPoint = CGPoint(x:0,y:0)
                            shapeLayer.position = CGPoint.zero
                            shapeLayer.frame = CGRect(x: origin.x, y: origin.y, width: runWidth, height: runHeight)
                            shapeLayer.strokeColor = UIColor.purple.cgColor
                            shapeLayer.lineWidth = 2.5
                            shapeLayer.fillColor = UIColor(white: 0, alpha: 0).cgColor
                            
                            let transform = CGAffineTransform(scaleX: 1, y: -1)//(translationX: 0, y: -shapeLayer.frame.height)//.scaledBy(x: 1, y: -1)
                            shapeLayer.setAffineTransform(transform)
                            
//                            shapeLayer.strokeStart = 0.05

                            
                            self.addSublayer(shapeLayer)
                            shapeLayer.needsDisplay()
                        }
                    }
                }
            }
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
        // For debugging
        ctx.setFillColor(UIColor.blue.cgColor)
        ctx.fill(bounds)
        
        // CTRunDraw seems to include the horizontal spacing before the run when drawing
        // Since we've already position this layer after the spacing, we'll need to tell
        // CoreText to minus that spacing
        ctx.textPosition = CGPoint(x: -ceil(position.x), y: descent + leading)
        
        // To make the CoreText drawing upside right
        ctx.translateBy(x: 0, y: bounds.size.height)
        ctx.scaleBy(x: 1, y: -1)
        
        CTRunDraw(run, ctx, CFRange(location: 0, length: 0))
    }
    
}
