//
//  NHRangeSlider.swift
//  NHRangeSlider
//
//  Created by Hung on 17/12/16.
//  Copyright © 2016 Hung. All rights reserved.
//

import UIKit
import QuartzCore

/// Range slider track layer. Responsible for drawing the horizontal track
public class RangeSliderTrackLayer: CALayer {

	/// owner slider
	weak var rangeSlider: NHRangeSlider?

	/// draw the track between 2 thumbs
	///
	/// - Parameter ctx: current graphics context
	public override func drawInContext(ctx: CGContext) {
		super.drawInContext(ctx)
		guard let slider = rangeSlider else {
			return
		}

		// Clip
		let cornerRadius = bounds.height * slider.curvaceousness / 2.0
		let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)

		CGContextAddPath(ctx, path.CGPath)

		// Fill the track
		CGContextSetFillColorWithColor(ctx, slider.trackTintColor.CGColor)
		CGContextAddPath(ctx, path.CGPath)
		CGContextFillPath(ctx)

		// Fill the highlighted range
		CGContextSetFillColorWithColor(ctx, slider.trackHighlightTintColor.CGColor)
		let lowerValuePosition = CGFloat(slider.positionForValue(slider.lowerValue))
		let upperValuePosition = CGFloat(slider.positionForValue(slider.upperValue))
		let rect = CGRect(x: lowerValuePosition, y: 0.0, width: upperValuePosition - lowerValuePosition, height: bounds.height)
		CGContextFillRect(ctx, rect)
	}
}

/// the thumb for upper , lower bounds
public class RangeSliderThumbLayer: CALayer {

	/// owner slider
	weak var rangeSlider: NHRangeSlider?

	/// whether this thumb is currently highlighted i.e. touched by user
	public var highlighted: Bool = false {
		didSet {
			setNeedsDisplay()
		}
	}

	/// stroke color
	public var strokeColor: UIColor = UIColor.grayColor() {
		didSet {
			setNeedsDisplay()
		}
	}

	/// line width
	public var lineWidth: CGFloat = 0.5 {
		didSet {
			setNeedsDisplay()
		}
	}

	/// draw the thumb
	///
	/// - Parameter ctx: current graphics context
	public override func drawInContext(ctx: CGContext) {
		super.drawInContext(ctx)
		guard let slider = rangeSlider else {
			return
		}

		let thumbFrame = bounds.insetBy(dx: 2.0, dy: 2.0)
		let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
		let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)

		// Fill
		CGContextSetFillColorWithColor(ctx, slider.thumbTintColor.CGColor)
		CGContextAddPath(ctx, thumbPath.CGPath)
		CGContextFillPath(ctx)

		// Outline
		CGContextSetStrokeColorWithColor(ctx, strokeColor.CGColor)
		CGContextSetLineWidth(ctx, lineWidth)
		CGContextAddPath(ctx, thumbPath.CGPath)
		CGContextStrokePath(ctx)

		if highlighted {
			CGContextSetFillColorWithColor(ctx, UIColor(white: 0.0, alpha: 0.1).CGColor)
			CGContextAddPath(ctx, thumbPath.CGPath)
			CGContextFillPath(ctx)
		}
	}
}

/// Range slider view with upper, lower bounds
@IBDesignable
public class NHRangeSlider: UIControl {

	// MARK: properties

	/// minimum value
	@IBInspectable public var minimumValue: Double = 0.0 {
		willSet(newValue) {
			assert(newValue < maximumValue, "NHRangeSlider: minimumValue should be lower than maximumValue")
		}
		didSet {
			updateLayerFrames()
		}
	}

	/// max value
	@IBInspectable public var maximumValue: Double = 100.0 {
		willSet(newValue) {
			assert(newValue > minimumValue, "NHRangeSlider: maximumValue should be greater than minimumValue")
		}
		didSet {
			updateLayerFrames()
		}
	}

	/// value for lower thumb
	@IBInspectable public var lowerValue: Double = 0.0 {
		didSet {
			if lowerValue < minimumValue {
				lowerValue = minimumValue
			}
			updateLayerFrames()
		}
	}

	/// value for upper thumb
	@IBInspectable public var upperValue: Double = 100.0 {
		didSet {
			if upperValue > maximumValue {
				upperValue = maximumValue
			}
			updateLayerFrames()
		}
	}

	/// stepValue. If set, will snap to discrete step points along the slider . Default to nil
	@IBInspectable public var stepValue: Double? = nil {
		willSet(newValue) {
			if newValue != nil {
				assert(newValue! > 0, "NHRangeSlider: stepValue must be positive")
			}
		}
		didSet {
			if let val = stepValue {
				if val <= 0 {
					stepValue = nil
				}
			}

			updateLayerFrames()
		}
	}

	/// minimum distance between the upper and lower thumbs.
	@IBInspectable public var gapBetweenThumbs: Double = 2.0

	/// tint color for track between 2 thumbs
	@IBInspectable public var trackTintColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
		didSet {
			trackLayer.setNeedsDisplay()
		}
	}

	/// track highlight tint color
	@IBInspectable public var trackHighlightTintColor: UIColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
		didSet {
			trackLayer.setNeedsDisplay()
		}
	}

	/// thumb tint color
	@IBInspectable public var thumbTintColor: UIColor = UIColor.whiteColor() {
		didSet {
			lowerThumbLayer.setNeedsDisplay()
			upperThumbLayer.setNeedsDisplay()
		}
	}

	/// thumb border color
	@IBInspectable public var thumbBorderColor: UIColor = UIColor.grayColor() {
		didSet {
			lowerThumbLayer.strokeColor = thumbBorderColor
			upperThumbLayer.strokeColor = thumbBorderColor
		}
	}

	/// thumb border width
	@IBInspectable public var thumbBorderWidth: CGFloat = 0.5 {
		didSet {
			lowerThumbLayer.lineWidth = thumbBorderWidth
			upperThumbLayer.lineWidth = thumbBorderWidth
		}
	}

	/// set 0.0 for square thumbs to 1.0 for circle thumbs
	@IBInspectable public var curvaceousness: CGFloat = 1.0 {
		didSet {
			if curvaceousness < 0.0 {
				curvaceousness = 0.0
			}

			if curvaceousness > 1.0 {
				curvaceousness = 1.0
			}

			trackLayer.setNeedsDisplay()
			lowerThumbLayer.setNeedsDisplay()
			upperThumbLayer.setNeedsDisplay()
		}
	}

	/// previous touch location
	private var previouslocation = CGPoint()

	/// track layer
	private let trackLayer = RangeSliderTrackLayer()

	/// lower thumb layer
	public let lowerThumbLayer = RangeSliderThumbLayer()

	/// upper thumb layer
	public let upperThumbLayer = RangeSliderThumbLayer()

	/// thumb width
	private var thumbWidth: CGFloat {
		return CGFloat(bounds.height)
	}

	/// frame
	override public var frame: CGRect {
		didSet {
			updateLayerFrames()
		}
	}

	// MARK: init methods
	override public init(frame: CGRect) {
		super.init(frame: frame)
		initializeLayers()
	}

	required public init?(coder: NSCoder) {
		super.init(coder: coder)
		initializeLayers()
	}

	// MARK: layers

	/// layout sub layers
	///
	/// - Parameter of: layer
	public override func layoutSublayersOfLayer(layer: CALayer) {
		super.layoutSublayersOfLayer(layer)
		updateLayerFrames()
	}

	/// init layers
	private func initializeLayers() {
		layer.backgroundColor = UIColor.clearColor().CGColor

		trackLayer.rangeSlider = self
		trackLayer.contentsScale = UIScreen.mainScreen().scale
		layer.addSublayer(trackLayer)

		lowerThumbLayer.rangeSlider = self
		lowerThumbLayer.contentsScale = UIScreen.mainScreen().scale
		layer.addSublayer(lowerThumbLayer)

		upperThumbLayer.rangeSlider = self
		upperThumbLayer.contentsScale = UIScreen.mainScreen().scale
		layer.addSublayer(upperThumbLayer)
	}

	/// update layer frames
	public func updateLayerFrames() {
		CATransaction.begin()
		CATransaction.setDisableActions(true)

		trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height / 3)
		trackLayer.setNeedsDisplay()

		let lowerThumbCenter = CGFloat(positionForValue(lowerValue))
		lowerThumbLayer.frame = CGRect(x: lowerThumbCenter - thumbWidth / 2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
		lowerThumbLayer.setNeedsDisplay()

		let upperThumbCenter = CGFloat(positionForValue(upperValue))
		upperThumbLayer.frame = CGRect(x: upperThumbCenter - thumbWidth / 2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
		upperThumbLayer.setNeedsDisplay()

		CATransaction.commit()
	}

	/// thumb x position for new value
	public func positionForValue(value: Double) -> Double {
		if (maximumValue == minimumValue) {
			return 0
		}

		return Double(bounds.width - thumbWidth) * (value - minimumValue) / (maximumValue - minimumValue)
			+ Double(thumbWidth / 2.0)
	}

	/// bound new value within lower and upper value
	///
	/// - Parameters:
	/// - value: value to set
	/// - lowerValue: lower value
	/// - upperValue: upper value
	/// - Returns: current value
	public func boundValue(value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
		return min(max(value, lowerValue), upperValue)
	}

	// MARK: - Touches

	/// begin tracking
	public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
		super.beginTrackingWithTouch(touch, withEvent: event)
        
        print("beginTrackingWithTouch")
        
        let location = touch.locationInView(self)
        // set highlighted positions for lower and upper thumbs
        if lowerThumbLayer.frame.contains(location) {
            lowerThumbLayer.highlighted = true
        }
        
        if upperThumbLayer.frame.contains(location) {
            upperThumbLayer.highlighted = true
        }
        
        return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
	}

	/// update positions for lower and upper thumbs
	public override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
		super.continueTrackingWithTouch(touch, withEvent: event)

		let location = touch.locationInView(self)

		// Determine by how much the user has dragged
		let deltaLocation = Double(location.x - previouslocation.x)
		var deltaValue: Double = 0

		if (bounds.width != bounds.height) {
			deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - bounds.height)
		}

		previouslocation = location

		// if both are highlighted. we need to decide which direction to drag
		if lowerThumbLayer.highlighted && upperThumbLayer.highlighted {

			if deltaLocation > 0 {
				// left to right
				upperValue = boundValue(upperValue + deltaValue, toLowerValue: lowerValue + gapBetweenThumbs, upperValue: maximumValue)
			}
			else {
				// right to left
				lowerValue = boundValue(lowerValue + deltaValue, toLowerValue: minimumValue, upperValue: upperValue - gapBetweenThumbs)
			}
		}
		else {

			// Update the values
			if lowerThumbLayer.highlighted {
				lowerValue = boundValue(lowerValue + deltaValue, toLowerValue: minimumValue, upperValue: upperValue - gapBetweenThumbs)
			} else if upperThumbLayer.highlighted {
				upperValue = boundValue(upperValue + deltaValue, toLowerValue: lowerValue + gapBetweenThumbs, upperValue: maximumValue)
			}
		}

		// only send changed value if stepValue is not set. We will trigger this later in endTracking
		if stepValue == nil {
			sendActionsForControlEvents(.ValueChanged)
		}

		return true
	}

	/// end touch tracking. Unhighlight the two thumbs
	public override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
		super.endTrackingWithTouch(touch, withEvent: event)

		lowerThumbLayer.highlighted = false
		upperThumbLayer.highlighted = false

		// let slider snap after user stop dragging
		if let stepValue = stepValue {
			lowerValue = round(lowerValue / stepValue) * stepValue
			upperValue = round(upperValue / stepValue) * stepValue
			sendActionsForControlEvents(.ValueChanged)
		}
	}

}
