//
//  ZCScanManager.swift
//  Pods-zcscan_Example
//
//  Created by lzc on 2025/7/3.
//

import Foundation

public class ZCScanManager {
    @MainActor public static let shared = ZCScanManager()
    public var conifg: ScanConfig = ScanConfig()
    init() {
        
    }
    
}
