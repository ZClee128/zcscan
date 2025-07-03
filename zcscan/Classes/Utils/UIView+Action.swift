//
//  UIView+Action.swift
//  zcscan
//
//  Created by lzc on 2025/7/3.
//

import Foundation
import UIKit

public protocol AssociatedObjectStore { }

public extension AssociatedObjectStore {
    func associatedObject<T>(forKey key: UnsafeRawPointer) -> T? {
        return objc_getAssociatedObject(self, key) as AnyObject as? T
    }
    
    func associatedObject<T>(forKey key: UnsafeRawPointer, default: @autoclosure () -> T, ploicy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) -> T {
        if let object: T = self.associatedObject(forKey: key) {
            return object
        }
        let object = `default`()
        self.setAssociatedObject(object, forKey: key, ploicy: ploicy)
        return object
    }
    
    func setAssociatedObject<T>(_ object: T?, forKey key: UnsafeRawPointer, ploicy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        objc_setAssociatedObject(self, key, object, ploicy)
    }
}

private var viewDidSelectedKey: Void?
private var viewDidTapKey: Void?
private var isHighlightHandlerKey: UInt8 = 0
extension NSObject: AssociatedObjectStore {}

public extension UIView {
    typealias AVATapAction = (_ isSelected: Bool) -> Void
    var zc_isSelected: Bool {
        get { return associatedObject(forKey: &viewDidSelectedKey) ?? false }
        set { setAssociatedObject(newValue, forKey: &viewDidSelectedKey) }
    }
    
    private var tapBlock: AVATapAction? {
        return associatedObject(forKey: &viewDidTapKey)
    }

    @objc func tapAction() {
        self.zc_isSelected = !zc_isSelected
        self.tapBlock?(zc_isSelected)
    }
}

public typealias TapView = UIView

public class WecoTapWrapper: NSObject {
    public let view: TapView
    public var isSelected: Bool {
        return view.zc_isSelected
    }
    
    public init(view: TapView) {
        self.view = view
    }
    
    /// 为UIView添加点击回调，并设置选中状态
    public func tap(tapBlock: @escaping (Bool) -> Void) {
        self.view.setAssociatedObject(tapBlock, forKey: &viewDidTapKey)
        let tap = UITapGestureRecognizer.init(target: self.view, action: #selector(TapView.tapAction))
        tap.delegate = self.view
        self.view.addGestureRecognizer(tap)
    }
}

extension TapView: @retroactive UIGestureRecognizerDelegate {
    public var zc: WecoTapWrapper {
        return WecoTapWrapper(view: self)
    }
    
    public func zcHighlight(isHighlightHandler: ((UITouch) -> Bool)? = nil) -> WecoTapWrapper {
        setAssociatedObject(isHighlightHandler, forKey: &isHighlightHandlerKey)
        return WecoTapWrapper(view: self)
    }
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let isHighlightHandler = associatedObject(forKey: &isHighlightHandlerKey) as ((UITouch) -> Bool)? {
            return isHighlightHandler(touch)
        }
        return true
    }
}

private var activityIndicatorKey: UInt8 = 0

extension UIViewController {
    func showLoading() {
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.color = .white
        indicator.center = self.view.center
        indicator.startAnimating()
        indicator.tag = 9999
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(indicator)

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }

    func hideLoading() {
        self.view.viewWithTag(9999)?.removeFromSuperview()
    }
}
