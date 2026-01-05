// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

public typealias AL = AutoLayout

public struct AutoLayout : Sendable{
    let insets: UIEdgeInsets
    let size: Size?
    let center: [Center]?
    let types: [Connectors]
    
    public init(insets: UIEdgeInsets = .zero, center: [Center]? = nil, size: Size? = nil, types: [Connectors] = [.all]) {
        self.insets = insets
        self.size = size
        self.types = types
        self.center = center
    }
    
    init(horizontal: CGFloat = 0, vertical: CGFloat = 0, center: [Center]? = nil, size: Size? = nil, types: [Connectors] = [.all]) {
        self.insets = UIEdgeInsets(horizontal: horizontal, vertical: vertical)
        self.size = size
        self.types = types
        self.center = center
    }
}

// MARK: - Computed Properties
extension AutoLayout {
    var top: CGFloat { insets.top }
    var bottom: CGFloat { insets.bottom }
    var leading: CGFloat { insets.left }
    var trailing: CGFloat { insets.right }
    var horizontal: CGFloat { max(insets.left, insets.right) }
    var vertical: CGFloat { max(insets.top, insets.bottom) }
}

// MARK: - Static Constructors
extension AutoLayout {
    static let controllerInset: AutoLayout =
        .init(insets: UIEdgeInsets(top: 0, left: 20, bottom: 24, right: 20), types: [.all])
    
    static func top(_ value: CGFloat) -> AutoLayout {
        .init(insets: UIEdgeInsets.top(value), types: [.top])
    }
    
    static func bottom(_ value: CGFloat) -> AutoLayout {
        .init(insets: UIEdgeInsets.bottom(value), types: [.bottom])
    }
    
    static func leading(_ value: CGFloat) -> AutoLayout {
        .init(insets: UIEdgeInsets.left(value), types: [.leading])
    }
    
    static func trailing(_ value: CGFloat) -> AutoLayout {
        .init(insets: UIEdgeInsets.right(value), types: [.trailing])
    }
    
    static func all(_ value: CGFloat) -> AutoLayout {
        .init(insets: UIEdgeInsets(top: value, left: value, bottom: value, right: value), types: [.all])
    }
    
    static func height(_ value: CGFloat) -> AutoLayout {
        .init(size: .height(value), types: [.height])
    }
    
    static func width(_ value: CGFloat) -> AutoLayout {
        .init(size: .width(value), types: [.width])
    }
}

extension UIView {
    func setupConstraints(of content: UIView, layout: AutoLayout = .init()) {
        let constraints = AL.Builder.buildConstraints(
            for: content,
            in: self,
            layout: layout
        )
        NSLayoutConstraint.activate(constraints)
    }
    
    func constraints(for content: UIView, layout: AutoLayout = .init()) -> [NSLayoutConstraint] {
        AL.Builder.buildConstraints(for: content, in: self, layout: layout)
    }
}

// MARK: - UIEdgeInsets Extensions
extension UIEdgeInsets {
    static func top(_ value: CGFloat) -> UIEdgeInsets {
        UIEdgeInsets(top: value, left: 0, bottom: 0, right: 0)
    }
    
    static func bottom(_ value: CGFloat) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 0, bottom: value, right: 0)
    }
    
    static func left(_ value: CGFloat) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: value, bottom: 0, right: 0)
    }
    
    static func right(_ value: CGFloat) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 0, bottom: 0, right: value)
    }
    
    init(horizontal: CGFloat = 0, vertical: CGFloat = 0) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
    
    static func options (top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> UIEdgeInsets {
        .init(top: top, left: left, bottom: bottom, right: right)
    }
    
    static func all (_ value: CGFloat = 0) -> UIEdgeInsets {
        .init(top: value, left: value, bottom: value, right: value)
    }
}
