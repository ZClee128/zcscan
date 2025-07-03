//
//  BundleEx.swift
//  zcscan
//
//  Created by lzc on 2025/7/3.
//

import Foundation
import UIKit

extension Bundle {
    static var zcscanBundle: Bundle? {
        guard let bundleURL = Bundle(for: ZCScanViewController.self).url(forResource: "zcscan", withExtension: "bundle") else {
            return nil
        }
        return Bundle(url: bundleURL)
    }
}
