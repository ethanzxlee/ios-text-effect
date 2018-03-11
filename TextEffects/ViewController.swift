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

class TextAnimationLayer: CALayer {
    
    
    var text: NSAttributedString {
        didSet {
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
        
        self.displayIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func needsDisplay() -> Bool {
        return isTextDirty || super.needsDisplay()
    }
    
    override func display() {
        contentsScale = UIScreen.main.scale
        removeAllSublayers()
        
        let frameSetter = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let path = CGPath(rect: bounds, transform: nil)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, text.length), path, nil)
        let lines = CTFrameGetLines(frame) as NSArray
        
        for (lineIndex, line) in lines.enumerated() {
            let line = line as! CTLine
            let runs = CTLineGetGlyphRuns(line) as NSArray
            let lineOriginsPtr = UnsafeMutablePointer<CGPoint>.allocate(capacity: runs.count)
            CTFrameGetLineOrigins(frame, CFRange(location: 0, length: lines.count), lineOriginsPtr)
            
            for run in runs {
                let run = run as! CTRun
                let runAttr = CTRunGetAttributes(run) as NSDictionary
                let runFont = runAttr[NSAttributedStringKey.font] as! CTFont
                
                if isEmojiFont(runFont) {
                    displayEmoji(run: run, lineOrigin: lineOriginsPtr.advanced(by: lineIndex).pointee)
                }
                else {
                    displayGlyphs(run: run, lineOrigin: lineOriginsPtr.advanced(by: lineIndex).pointee)
                }
            }
            
            lineOriginsPtr.deinitialize(count: lines.count)
            lineOriginsPtr.deallocate(capacity: lines.count)
        }
        super.display()
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        isTextDirty = false
    }
    
    func isEmojiFont(_ font: CTFont) -> Bool {
        return CTFontCopyFamilyName(font) as String == "Apple Color Emoji"
    }
    
    func removeAllSublayers() {
        if let sublayers = self.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
            self.sublayers = nil
        }
    }
    
    func displayEmoji(run: CTRun, lineOrigin: CGPoint) {
        // Reference: https://developer.apple.com/library/content/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/CustomTextProcessing/CustomTextProcessing.html#//apple_ref/doc/uid/TP40009542-CH4-SW66
        let typographicBounds = TypographicBounds(from: run)
        
        let runPosition = UnsafeMutablePointer<CGPoint>.allocate(capacity: 1)
        CTRunGetPositions(run, CFRange(location: 0, length: 1), runPosition)
        
        let emojiLayer = CoreTextRunLayer(run: run, typographicBounds: typographicBounds)
        
        // Origin doesn't include descent & leading
        let origin = CGPoint(x: runPosition.pointee.x, y: self.frame.height - lineOrigin.y - typographicBounds.ascent)
        let size = CGSize(width: typographicBounds.width, height: typographicBounds.height)
        emojiLayer.anchorPoint = CGPoint(x: 0, y: 0)
        emojiLayer.position = origin
        emojiLayer.bounds = CGRect(origin: CGPoint.zero, size: size)
        emojiLayer.masksToBounds = false
        emojiLayer.contentsScale = contentsScale
        
        self.addSublayer(emojiLayer)
        emojiLayer.setNeedsDisplay()
        
        runPosition.deinitialize(count: 1)
        runPosition.deallocate(capacity: 1)
    }
    
    func displayGlyphs(run: CTRun, lineOrigin: CGPoint) {
        let runAttr = CTRunGetAttributes(run) as NSDictionary
        let runFont = runAttr[NSAttributedStringKey.font] as! CTFont
        let glyphsCount = CTRunGetGlyphCount(run)
        
        let glyphsPtr = UnsafeMutablePointer<CGGlyph>.allocate(capacity: glyphsCount)
        CTRunGetGlyphs(run, CFRange(location: 0, length: 0), glyphsPtr)
        
        let runPositionsPtr = UnsafeMutablePointer<CGPoint>.allocate(capacity: glyphsCount)
        CTRunGetPositions(run, CFRange(location: 0, length: 0), runPositionsPtr)
        
        for i in 0..<glyphsCount {
            guard let glyphPath = CTFontCreatePathForGlyph(runFont, glyphsPtr.advanced(by: i).pointee, nil) else {
                continue
            }
            
            let typographicBounds = TypographicBounds(from: run)
            let origin = CGPoint(x: runPositionsPtr.advanced(by: i).pointee.x, y: bounds.height - lineOrigin.y - typographicBounds.ascent)
            var pathTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -typographicBounds.ascent)
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = glyphPath.copy(using: &pathTransform)
            shapeLayer.anchorPoint = CGPoint(x: 0, y: 0)
            shapeLayer.frame = CGRect(x: origin.x, y: origin.y, width: typographicBounds.width, height: typographicBounds.height)
            shapeLayer.strokeColor = UIColor.purple.cgColor
            shapeLayer.lineWidth = 1
            shapeLayer.fillColor = UIColor(white: 0, alpha: 0).cgColor
            shapeLayer.contentsScale = contentsScale
            
            addSublayer(shapeLayer)
            shapeLayer.needsDisplay()
        }
        
        glyphsPtr.deinitialize(count: glyphsCount)
        runPositionsPtr.deinitialize(count: glyphsCount)
        glyphsPtr.deallocate(capacity: glyphsCount)
        runPositionsPtr.deallocate(capacity: glyphsCount)
    }
}

class CoreTextRunLayer : CALayer {
    
    let run : CTRun
    let typographicBounds: TypographicBounds
    
    init(run: CTRun, typographicBounds: TypographicBounds) {
        self.run = run
        self.typographicBounds = typographicBounds
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func display() {
        super.display()
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        
        // CTRunDraw seems to include the horizontal spacing before the run when drawing
        // Since we've already position this layer after the spacing, we'll need to tell
        // CoreText to minus that spacing
        ctx.textPosition = CGPoint(x: -position.x, y: typographicBounds.descent + typographicBounds.leading)
        
        // To make the CoreText drawing upside right
        ctx.translateBy(x: 0, y: frame.height)
        ctx.scaleBy(x: 1, y: -1)
        
        CTRunDraw(run, ctx, CFRange(location: 0, length: 0))
    }
    
}
