//
//  HexagonalItemView.swift
//  Hexacon
//
//  Created by Gautier Gdx on 13/02/16.
//  Copyright © 2016 Gautier. All rights reserved.
//

import UIKit

protocol HexagonalItemViewDelegate: class {
    func hexagonalItemViewClikedOnButton(forIndex index: Int)
}

public class HexagonalItemView: UIView {
    
    // MARK: - data
    
    public init(view: UIView) {
        super.init(frame: CGRectZero)
        
        addSubview(view)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public var index: Int?
    
    weak var delegate: HexagonalItemViewDelegate?
    
    // MARK: - event methods
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        guard let index = index else { return }
        
        delegate?.hexagonalItemViewClikedOnButton(forIndex: index)
    }

}
