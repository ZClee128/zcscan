//
//  ScanConfig.swift
//  Pods-zcscan_Example
//
//  Created by lzc on 2025/7/3.
//

import Foundation

public class ScanConfig {
    /// 扫码的光线
    public var scanninglineImage: UIImage?
    /// 选择二维码图片的按钮图标
    public var selectQrcodeBtnImage: UIImage?
    
    public init(scanninglineImage: UIImage? = nil, selectQrcodeBtnImage: UIImage? = nil) {
        self.scanninglineImage = scanninglineImage
        self.selectQrcodeBtnImage = selectQrcodeBtnImage
    }
}
