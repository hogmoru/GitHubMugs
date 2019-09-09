//
//  MugDecorator.swift
//  GitHubMugs
//
//  Created by Hugues Moreau on 09/09/2019.
//  Copyright © 2019 Hugues Moreau. All rights reserved.
//

import Foundation
import UIKit

private struct ScaleFactor {
  static let retinaToEye: CGFloat = 0.5
  static let faceBoundsToEye: CGFloat = 4.0
}

class MugDecorator {
    
    static func faceOverlayImageFrom(_ image: UIImage) -> UIImage {
      let detector = CIDetector(ofType: CIDetectorTypeFace,
          context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
      
      // Get features from the image
      let newImage = CIImage(cgImage: image.cgImage!)
      let features = detector?.features(in: newImage) as! [CIFaceFeature]
      
      UIGraphicsBeginImageContext(image.size)
      let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
      
      // Draws this in the upper left coordinate system
      image.draw(in: imageRect, blendMode: .normal, alpha: 1.0)
      
      let context = UIGraphicsGetCurrentContext()
      for faceFeature in features {
        let faceRect = faceFeature.bounds
        context!.saveGState()
        
        // CI and CG work in different coordinate systems, we should translate to
        // the correct one so we don't get mixed up when calculating the face position.
        context!.translateBy(x: 0.0, y: imageRect.size.height)
        context!.scaleBy(x: 1.0, y: -1.0)
        
        if faceFeature.hasLeftEyePosition {
          let leftEyePosition = faceFeature.leftEyePosition
          let eyeWidth = faceRect.size.width / ScaleFactor.faceBoundsToEye
          let eyeHeight = faceRect.size.height / ScaleFactor.faceBoundsToEye
          let eyeRect = CGRect(x: leftEyePosition.x - eyeWidth / 2.0,
                               y: leftEyePosition.y - eyeHeight / 2.0,
                               width: eyeWidth,
                               height: eyeHeight)
          drawEyeBallForFrame(eyeRect)
        }
        
        if faceFeature.hasRightEyePosition {
          let leftEyePosition = faceFeature.rightEyePosition
          let eyeWidth = faceRect.size.width / ScaleFactor.faceBoundsToEye
          let eyeHeight = faceRect.size.height / ScaleFactor.faceBoundsToEye
          let eyeRect = CGRect(x: leftEyePosition.x - eyeWidth / 2.0,
                               y: leftEyePosition.y - eyeHeight / 2.0,
                               width: eyeWidth,
                               height: eyeHeight)
          drawEyeBallForFrame(eyeRect)
        }
        
        context!.restoreGState();
      }
      
      let overlayImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      
      return overlayImage!
    }
    
    static func faceRotationInRadians(leftEyePoint startPoint: CGPoint, rightEyePoint endPoint: CGPoint) -> CGFloat {
      let deltaX = endPoint.x - startPoint.x
      let deltaY = endPoint.y - startPoint.y
      let angleInRadians = CGFloat(atan2f(Float(deltaY), Float(deltaX)))
      
      return angleInRadians;
    }
    
    static func drawEyeBallForFrame(_ rect: CGRect) {
      let context = UIGraphicsGetCurrentContext()
      context?.addEllipse(in: rect)
      context?.setFillColor(UIColor.white.cgColor)
      context?.fillPath()
      
      let eyeSizeWidth = rect.size.width * ScaleFactor.retinaToEye
      let eyeSizeHeight = rect.size.height * ScaleFactor.retinaToEye
      
      var x = CGFloat(arc4random_uniform(UInt32(rect.size.width - eyeSizeWidth)))
      var y = CGFloat(arc4random_uniform(UInt32(rect.size.height - eyeSizeHeight)))
      x += rect.origin.x
      y += rect.origin.y
      
      let eyeSize = min(eyeSizeWidth, eyeSizeHeight)
      let eyeBallRect = CGRect(x: x, y: y, width: eyeSize, height: eyeSize)
      context?.addEllipse(in: eyeBallRect)
      context?.setFillColor(UIColor.black.cgColor)
      context?.fillPath()
    }
}
