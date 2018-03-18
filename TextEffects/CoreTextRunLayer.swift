//
//  CoreTextRunLayer.swift
//  TextEffects
//
//  Created by Zhe Xian Lee on 19/3/18.
//  Copyright © 2018 Zhe Xian Lee. All rights reserved.
//

import CoreText
import QuartzCore

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
