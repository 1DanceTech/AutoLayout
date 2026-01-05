//
//  AutoLayoutBuilder.swift
//  AutoLayout
//
//  Created by Moses A. on 29/10/2025.
//

import UIKit

class AutoLayoutBuilder {
    private var constraints: [(view: UIView, layout: AutoLayout)] = []
    private var currentView: UIView?
    private var currentLayout: AutoLayout?
    private var linkedTags: [Int]? = nil
    
    @MainActor static func with(_ view: UIView,
                    insets: UIEdgeInsets = .zero,
                    size: AutoLayout.Size? = nil,
                     constraints: [AutoLayout.Connectors] = []) -> AutoLayoutBuilder {
        let builder = AutoLayoutBuilder()
        let constraints = size?.extendConstraints(constraints) ?? constraints
        return builder.with(view, insets: insets, size: size, constraints: constraints)
    }
    
    @MainActor private func appendCurrentItem() {
        if let currentView = currentView, let currentLayout = currentLayout {
            let previousTag = constraints.count + 1
            currentView.tag = previousTag
            constraints.append((currentView, currentLayout))
            linkedTags?.append(previousTag)
        }
    }
    
    @MainActor @discardableResult
    func with(_ view: UIView,
             insets: UIEdgeInsets = .zero,
             size: AutoLayout.Size? = nil,
              constraints: [AutoLayout.Connectors] = []) -> Self {
        
        let constraints = size?.extendConstraints(constraints) ?? constraints
        appendCurrentItem()
        
        self.currentView = view
        self.currentLayout = AutoLayout(insets: insets, size: size, types: constraints)
        return self
    }
    
    @discardableResult
    func vertical(spacing: CGFloat,
                 order: VerticalOrder) -> Self {
        guard let _ = currentView,
              let currentLayout = currentLayout else {
            return self
        }
        
        let (fromView, fromAttribute, toView, toAttribute) = order.components
        let connectorOrder = order.connectorOrder
        
        let fromConnector = AutoLayout.Connector(type: fromAttribute.connectorType, content: fromView)
        let toConnector = AutoLayout.Connector(type: toAttribute.connectorType, content: toView)
        
        let verticalConnector = AutoLayout.VerticalConnector(
            top: fromConnector,
            bottom: toConnector,
            spacing: spacing,
            order: connectorOrder
        )
        
        var newTypes = currentLayout.types
        newTypes.append(.vertical(verticalConnector))
        
        self.currentLayout = AutoLayout(
            insets: currentLayout.insets,
            size: currentLayout.size,
            types: newTypes
        )
        
        return self
    }
    
    @discardableResult
    func horizontal(spacing: CGFloat,
                   order: HorizontalOrder) -> Self {
        guard let _ = currentView,
              let currentLayout = currentLayout else {
            return self
        }
        
        let (fromView, fromAttribute, toView, toAttribute) = order.components
        let connectorOrder = order.connectorOrder
        
        let fromConnector = AutoLayout.Connector(type: fromAttribute.connectorType, content: fromView)
        let toConnector = AutoLayout.Connector(type: toAttribute.connectorType, content: toView)
        
        let horizontalConnector = AutoLayout.HorizontalConnector(
            leading: fromConnector,
            trailing: toConnector,
            spacing: spacing,
            order: connectorOrder
        )
        
        var newTypes = currentLayout.types
        newTypes.append(.horizontal(horizontalConnector))
        
        self.currentLayout = AutoLayout(
            insets: currentLayout.insets,
            size: currentLayout.size,
            types: newTypes
        )
        
        return self
    }
    
    func build() -> [(UIView, AutoLayout)] {
        if let currentView = currentView, let currentLayout = currentLayout {
            constraints.append((currentView, currentLayout))
        }
        
        return constraints
    }
    
    @MainActor func apply(to superview: UIView) {
        let constraints = build()
        constraints.forEach { view, layout in
            superview.setupConstraints(of: view, layout: layout)
        }
    }
}


fileprivate extension Array {
    static func getAdjacentElements<E>(array: [E], at index: Int) -> (previous: E?, next: E?) {
        guard array.indices.contains(index) else {
            return (nil, nil)
        }
        var index = index
        let previous = array[index]
        index += 1
        
        let next = index < array.count ? array[index] : nil
        
        return (previous, next)
    }
}

// MARK: - Convenience Methods for Common Patterns
extension AutoLayoutBuilder {
    
    func startStack() -> Self {
        linkedTags = []
        return self
    }
    
    func linkV(from firstView: UIView? = nil, to secondView: UIView? = nil, _ spacing: CGFloat = 0) -> Self {
        guard let currentView = firstView ?? currentView,
              let previousView = secondView ?? constraints.last?.view else {
            return self
        }
        
        return vertical(spacing: spacing,
                        order: .bottomTop(currentView, .top, previousView, .bottom))
    }
    
    @MainActor func stackV(_ spacing: CGFloat = 0) -> Self {
        defer {
            constraints.removeLast()
        }
        
        appendCurrentItem()
        
        let taggedConstraints = constraints.filter { [weak self] in
            guard let self, let linkedTags else { return false }
            return linkedTags.contains($0.view.tag)
        }
        
        taggedConstraints.enumerated().forEach { [weak self] index, constraint in
            guard let self else { return }
            let adjacentConstraints = Array<Any>.getAdjacentElements(array: taggedConstraints, at: index)
            guard let previous = adjacentConstraints.previous?.view,
                  let next = adjacentConstraints.next?.view else { return }
            vertical(spacing: spacing,
                     order: .bottomTop(next, .top, previous, .bottom))
        }
        
        linkedTags = nil
        
        return self
    }
    
    func linkH(from firstView: UIView? = nil, to secondView: UIView? = nil, _ spacing: CGFloat = 0) -> Self {
        guard let currentView = firstView ?? currentView,
              let previousView = secondView ?? constraints.last?.view else {
            return self
        }
        
        return horizontal(spacing: spacing,
                          order: .trailingLeading(currentView, .leading, previousView, .trailing))
    }
    
    @MainActor func stackH(_ spacing: CGFloat = 0) -> Self {
        defer {
            constraints.removeLast()
        }
        
        appendCurrentItem()
        
        let taggedConstraints = constraints.filter { [weak self] in
            guard let self, let linkedTags else { return false }
            return linkedTags.contains($0.view.tag)
        }
        
        taggedConstraints.enumerated().forEach { [weak self] index, constraint in
            guard let self else { return }
            let adjacentConstraints = Array<Any>.getAdjacentElements(array: taggedConstraints, at: index)
            guard let previous = adjacentConstraints.previous?.view,
                  let next = adjacentConstraints.next?.view else { return }
            horizontal(spacing: spacing,
                       order: .trailingLeading(next, .leading, previous, .trailing))
        }
        
        linkedTags = nil
        
        return self
    }
}

extension UIView {
    
    var layoutBuilder: AutoLayoutBuilder {
        return AutoLayoutBuilder()
    }
    
    @discardableResult func layout(_ subviews: UIView...) -> AutoLayoutBuilder {
        for subview in subviews {
            addSubview(subview)
        }
        return layoutBuilder
    }
}
