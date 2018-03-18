//
//  TextAnimationLayer.swift
//  TextEffects
//
//  Created by Zhe Xian Lee on 19/3/18.
//  Copyright © 2018 Zhe Xian Lee. All rights reserved.
//

import QuartzCore
import CoreText
import UIKit

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
            let p = UIBezierPath(cgPath: glyphPath)
            print("-----------")
            print(glyphPath)
            print("-----------")
            let typographicBounds = TypographicBounds(from: run)
            let origin = CGPoint(x: runPositionsPtr.advanced(by: i).pointee.x, y: bounds.height - lineOrigin.y - typographicBounds.ascent)
            var pathTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -typographicBounds.ascent)
            
            //            let p = UIBezierPath(cgPath: glyphPath)
            //            p.
            //
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
