//
//  ZenlyHexaView.swift
//  Hexacon
//
//  Created by Gautier Gdx on 05/02/16.
//  Copyright © 2016 Gautier. All rights reserved.
//

import UIKit

public protocol HexagonalViewDelegate: class {
    /**
     This method is called when the user has selected a view
     
     - parameter hexagonalView: The HexagonalView we are targeting
     - parameter index:         The current Index
     */
    func hexagonalView(hexagonalView: HexagonalView, didSelectItemAtIndex index: Int)
    
    /**
     This method is called when the HexagonalView will center on an item, it gives you the new value of lastFocusedViewIndex
     
     - parameter hexagonalView: The HexagonalView we are targeting
     - parameter index:         The current Index
     */
    func hexagonalView(hexagonalView: HexagonalView, willCenterOnIndex index: Int)
}

public extension HexagonalViewDelegate {
    func hexagonalView(hexagonalView: HexagonalView, didSelectItemAtIndex index: Int) { }
    func hexagonalView(hexagonalView: HexagonalView, willCenterOnIndex index: Int) { }
}

public protocol HexagonalViewDataSource: class {
    /**
     Return the number of items the view will contain
     
     - parameter hexagonalView: The HexagonalView we are targeting
     
     - returns: The number of items
     */
    func numberOfItemInHexagonalView(hexagonalView: HexagonalView) -> Int
    
    /**
     Return a view to be displayed at index, the view will be transformed in an image before being displayed
     
     - parameter hexagonalView: The HexagonalView we are targeting
     - parameter index:         The current Index
     
     - returns: The view we want to display
     */
    func hexagonalView(hexagonalView: HexagonalView,viewForIndex index: Int) -> UIView?
}

public extension HexagonalViewDataSource {
    func hexagonalView(hexagonalView: HexagonalView,imageForIndex index: Int) -> UIImage? { return nil }
    func hexagonalView(hexagonalView: HexagonalView,viewForIndex index: Int) -> UIView? { return nil }
}

public final class HexagonalView: UIScrollView {
    
    // MARK: - subviews
    
    private lazy var contentView = UIView()
    
    // MARK: - data

    /**
     An object that supports the HexagonalViewDataSource protocol and can provide views or images to configures the HexagonalView.
     */
    public weak var hexagonalDataSource: HexagonalViewDataSource?

    /**
     An object that supports the HexagonalViewDelegate protocol and can respond to HexagonalView events.
     */
    public weak var hexagonalDelegate: HexagonalViewDelegate?

    /**
     The index of the view where the HexagonalView is or was centered on.
     */
    public var lastFocusedViewIndex: Int = 0
    
    /**
     the appearance is used to configure the global apperance of the layout and the HexagonalItemView
     */
    public var itemAppearance: HexagonalItemViewAppearance
    
    //we are using a zoom cache setted to 1 to make the snap work even if the user haven't zoomed yet
    private var zoomScaleCache: CGFloat = 1
    
    //ArrayUsed to contain all the view in the Hexagonal grid
    private var viewsArray = [HexagonalItemView]()
    
    //manager to create the hexagonal grid
    private var hexagonalPattern: HexagonalPattern!
    
    //used to snap the view after scroll
    private var centerOnEndScroll = false
    
    // MARK: - init
    
    public init(frame: CGRect, itemAppearance: HexagonalItemViewAppearance) {
        self.itemAppearance = itemAppearance
        super.init(frame: frame)
     
        setUpView()
    }
    
    convenience public override init(frame: CGRect) {
        self.init(frame: frame, itemAppearance: HexagonalItemViewAppearance.defaultAppearance())
    }

    required public init?(coder aDecoder: NSCoder) {
        itemAppearance = HexagonalItemViewAppearance.defaultAppearance()
        super.init(coder: aDecoder)
        
        setUpView()
    }

    func setUpView() {
        //configure scrollView
        delaysContentTouches = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        alwaysBounceHorizontal = true
        alwaysBounceVertical = true
        bouncesZoom = false
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
        minimumZoomScale = 0.2
        maximumZoomScale = 2
        
        //add contentView
        addSubview(contentView)
    }
    
    // MARK: - configuration methods
    
    private func createHexagonalGrid() {
        //instantiate the hexagonal pattern with the number of views
        hexagonalPattern = HexagonalPattern(size: viewsArray.count, itemSpacing: itemAppearance.itemSpacing, itemSize: itemAppearance.itemSize)
        hexagonalPattern.repositionCenter = { [weak self] (center, ring, index) in
            self?.positionAndAnimateItemView(forCenter: center, ring: ring, index: index)
        }
        
        //set the contentView frame with the theorical size of th hexagonal grid
        let contentViewSize = hexagonalPattern.sizeForGridSize()
        contentView.bounds = CGRectMake(0, 0, contentViewSize, 1.5*contentViewSize)
        contentView.center = center
        
        //start creating hte grid
        hexagonalPattern.createGrid(FromCenter: CGPoint(x: contentView.frame.width/2, y: contentView.frame.height/2))
    }

    private func createHexagonalViewItem(index: Int) -> HexagonalItemView {
        //instantiate the userView with the user
        
        var itemView: HexagonalItemView

        let view = (hexagonalDataSource?.hexagonalView(self, viewForIndex: index))!
        itemView = HexagonalItemView(view: view)
        
        itemView.frame = CGRect(x: 0, y: 0, width: itemAppearance.itemSize, height: itemAppearance.itemSize)
        itemView.userInteractionEnabled = true
        //setting the delegate
        itemView.delegate = self
        
        //adding index in order to retrive the view later
        itemView.index = index
        
        if itemAppearance.animationType != .None {
            //setting the scale to 0 to perform lauching animation
            itemView.transform = CGAffineTransformMakeScale(0, 0)
        }
        
        //add to content view
        self.contentView.addSubview(itemView)
        return itemView
    }
    
    private func positionAndAnimateItemView(forCenter center: CGPoint, ring: Int, index: Int) {
        guard itemAppearance.animationType != .None else { return }
        
        //set the new view's center
        let view = viewsArray[index]
        view.center = CGPoint(x: center.x,y: center.y)
        
        let animationIndex = Double(itemAppearance.animationType == .Spiral ? index : ring)
        
        //make a pop animation
        UIView.animateWithDuration(0.3, delay: NSTimeInterval(animationIndex*itemAppearance.animationDuration), usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: { () -> Void in
            view.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
    private func transformView(view: HexagonalItemView) {
        let spacing = itemAppearance.itemSize + itemAppearance.itemSpacing/2
        
        //convert the ivew rect in the contentView coordinate
        var frame = convertRect(view.frame, fromView: view.superview)
        //substract content offset to it
        frame.origin.x -= contentOffset.x
        frame.origin.y -= contentOffset.y
        
        //retrieve the center
        let center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        let distanceToBeOffset = spacing * zoomScaleCache
        let	distanceToBorder = getDistanceToBorder(center: center,distanceToBeOffset: distanceToBeOffset,insets: contentInset)
        
        //if we are close to a border
        if distanceToBorder < distanceToBeOffset * 2 {
        //if ere are out of bound
            if distanceToBorder < CGFloat(-(Int(spacing*2.5))) {
                //hide the view
                view.transform = CGAffineTransformMakeScale(0, 0)
            } else {
                //find the new scale
                var scale = max(distanceToBorder / (distanceToBeOffset * 2), 0)
                scale = 1-pow(1-scale, 2)
                
                //transform the view
                view.transform = CGAffineTransformMakeScale(scale, scale)
            }
        } else {
            view.transform = CGAffineTransformIdentity
        }
    }
    
    private func centerScrollViewContents() {
        let boundsSize = bounds.size
        var contentsFrame = contentView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        contentView.frame = contentsFrame
    }
    
    private func getDistanceToBorder(center center: CGPoint,distanceToBeOffset: CGFloat,insets: UIEdgeInsets) -> CGFloat {
        let size = bounds.size
        var	distanceToBorder: CGFloat = size.width
        
        //check if the view is close to the left
        //changing the distance to border and the offset accordingly
        let leftDistance = center.x - insets.left
        if leftDistance < distanceToBeOffset && leftDistance < distanceToBorder {
            distanceToBorder = leftDistance
        }
        
        //same for top
        let topDistance = center.y - insets.top
        if topDistance < distanceToBeOffset && topDistance < distanceToBorder {
            distanceToBorder = topDistance
        }
        
        //same for right
        let rightDistance = size.width - center.x - insets.right
        if rightDistance < distanceToBeOffset && rightDistance < distanceToBorder {
            distanceToBorder = rightDistance
        }
        
        //same for bottom
        let bottomDistance = size.height - center.y - insets.bottom
        if bottomDistance < distanceToBeOffset && bottomDistance < distanceToBorder {
            distanceToBorder = bottomDistance
        }
        
        return distanceToBorder*2
    }
    
    private func centerOnIndex(index: Int, zoomScale: CGFloat) {
        guard centerOnEndScroll else { return }
        centerOnEndScroll = false

        //calling delegate 
        hexagonalDelegate?.hexagonalView(self, willCenterOnIndex: index)
        
        //the view to center
        let view = viewsArray[Int(index)]

        //find the rect of the view in the contentView scale
        let rectInSelfSpace = HexagonalView.rectInContentView(point: view.center, zoomScale: zoomScale, size: bounds.size)
        scrollRectToVisible(rectInSelfSpace, animated: true)
    }
    
    
    // MARK: - public methods
    
    /**
     This function load or reload all the view from the dataSource and refreshes the display
     */
    public func reloadData() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        viewsArray = [HexagonalItemView]()
        
        guard let datasource = hexagonalDataSource else { return }
        
        let numberOfItems = datasource.numberOfItemInHexagonalView(self)
        
        guard numberOfItems > 0 else { return }
        
        for index in 0...numberOfItems {
            viewsArray.append(createHexagonalViewItem(index))
        }
        
        self.createHexagonalGrid()
    }
    
    /**
    retrieve the HexagonalItemView from the HexagonalView if it's exist
    
    - parameter index: the current index of the HexagonalItemView
    
    - returns: an optionnal HexagonalItemView
    */
    public func viewForIndex(index: Int) -> HexagonalItemView? {
        guard index < viewsArray.count else { return nil }
        
        return viewsArray[index]
    }
    
    
    // MARK: - class methods
    
    private static func rectInContentView(point point: CGPoint,zoomScale: CGFloat, size: CGSize) -> CGRect {
        let center = CGPointMake(point.x * zoomScale, point.y * zoomScale)
        
        return CGRectMake(center.x-size.width*0.5, center.y-size.height*0.5, size.width, size.height)
    }

    private static func closestIndexToContentViewCenter(contentViewCenter: CGPoint,currentIndex: Int,views: [UIView]) -> Int {
        var hasItem = false
        var distance: CGFloat = 0
        var index = currentIndex
        
        views.enumerate().forEach { (viewIndex: Int, view: UIView) -> () in
            let center = view.center
            let potentialDistance = distanceBetweenPoint(point1: center, point2: contentViewCenter)
            
            if potentialDistance < distance || !hasItem {
                hasItem = true
                distance = potentialDistance
                index = viewIndex
            }
        }
        return index
    }
    
    private static func distanceBetweenPoint(point1 point1: CGPoint, point2: CGPoint) ->  CGFloat {
        let distance = Double((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y))
        let squaredDistance = sqrt(distance)
        return CGFloat(squaredDistance)
    }
}

// MARK: - UIScrollViewDelegate

extension HexagonalView: UIScrollViewDelegate {
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    public func scrollViewDidZoom(scrollView: UIScrollView) {
        zoomScaleCache = zoomScale
        
        //center the contentView each time we zoom
        centerScrollViewContents()
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        //for each view snap if close to border
        for view in viewsArray {
            transformView(view)
        }
    }

    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let size = self.bounds.size
        
        //the new contentView offset
        let newOffset: CGPoint = targetContentOffset.memory
        
        //put proposedTargetCenter in coordinates relative to contentView
        var proposedTargetCenter = CGPointMake(newOffset.x+size.width/2, newOffset.y+size.height/2)
        proposedTargetCenter.x /= zoomScale
        proposedTargetCenter.y /= zoomScale
        
        //find the closest userView relative to contentView center
        lastFocusedViewIndex = HexagonalView.closestIndexToContentViewCenter(proposedTargetCenter, currentIndex: lastFocusedViewIndex, views: viewsArray)
        
        //tell that we need to center on new index
        centerOnEndScroll = true
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //if we don't need do decelerate
        guard  !decelerate else { return }
        
        //center the userView
        centerOnIndex(lastFocusedViewIndex, zoomScale: zoomScale)
    }
        
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        //center the userView
        centerOnIndex(lastFocusedViewIndex, zoomScale: zoomScale)
    }
}


extension HexagonalView: HexagonalItemViewDelegate {
    
    func hexagonalItemViewClikedOnButton(forIndex index: Int) {
        hexagonalDelegate?.hexagonalView(self, didSelectItemAtIndex: index)
    }
}
