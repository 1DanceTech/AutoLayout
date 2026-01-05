//
//  HorizontalOrder.swift
//  AutoLayout
//
//  Created by Moses A. on 29/10/2025.
//

import UIKit

enum HorizontalOrder {
    case leadingTrailing(UIView, HorizontalAttribute, UIView, HorizontalAttribute)
    case trailingLeading(UIView, HorizontalAttribute, UIView, HorizontalAttribute)
    
    var components: (UIView, HorizontalAttribute, UIView, HorizontalAttribute) {
        switch self {
        case let .leadingTrailing(fromView, fromAttr, toView, toAttr):
            return (fromView, fromAttr, toView, toAttr)
        case let .trailingLeading(fromView, fromAttr, toView, toAttr):
            return (fromView, fromAttr, toView, toAttr)
        }
    }
    
    var connectorOrder: AutoLayout.ConnectorOrders {
        switch self {
        case .leadingTrailing:
            return .leadingTrailing
        case .trailingLeading:
            return .trailingLeading
        }
    }
}

enum VerticalOrder {
    case topBottom(UIView, VerticalAttribute, UIView, VerticalAttribute)
    case bottomTop(UIView, VerticalAttribute, UIView, VerticalAttribute)
    
    var components: (UIView, VerticalAttribute, UIView, VerticalAttribute) {
        switch self {
        case let .topBottom(fromView, fromAttr, toView, toAttr):
            return (fromView, fromAttr, toView, toAttr)
        case let .bottomTop(fromView, fromAttr, toView, toAttr):
            return (fromView, fromAttr, toView, toAttr)
        }
    }
    
    var connectorOrder: AutoLayout.ConnectorOrders {
        switch self {
        case .topBottom:
            return .topBottom
        case .bottomTop:
            return .bottomTop
        }
    }
}
