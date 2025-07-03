//
//  UIimageEx.swift
//  zcscan
//
//  Created by lzc on 2025/7/3.
//

import Foundation
import UIKit

extension UIImage {
    /// 根据界面内容绘制一张图片
    static func generateByLayer(layer: CALayer, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(layer.bounds.size, layer.isOpaque, scale)
        
        let context = UIGraphicsGetCurrentContext()
        if context == nil {
            return nil
        }
        layer.render(in: context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func grayImage() -> UIImage? {
        guard let imageCG = self.cgImage else {
            return nil
        }
        let width = imageCG.width
        let height = imageCG.height
        guard width > 0, height > 0 else {
            return nil
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let pixels = UnsafeMutablePointer<UInt32>.allocate(capacity: width * height)
        let uint32Size = MemoryLayout<UInt32>.size
        guard let context = CGContext(data: pixels,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: uint32Size * width,
                                      space: colorSpace,
                                      bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            pixels.deallocate()
            return nil
        }
        context.draw(imageCG, in: CGRect(x: 0, y: 0, width: width, height: height))
        for y in 0 ..< height {
            for x in 0 ..< width {
                let offset = y * width + x
                var pixel = pixels[offset]
                let r = 255 - UInt8((pixel >> 16) & 0xFF)
                let g = 255 - UInt8((pixel >> 8) & 0xFF)
                let b = 255 - UInt8(pixel & 0xFF)
                let a = UInt8((pixel >> 24) & 0xFF)
                pixels[offset] = (UInt32(a) << 24) | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
            }
        }
        guard let image = context.makeImage() else {
            pixels.deallocate()
            return nil
        }
        pixels.deallocate()
        return UIImage(cgImage: image, scale: self.scale, orientation: self.imageOrientation)
    }
}
