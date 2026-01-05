//
//  AutoLayout+Connector.swift
//  AutoLayout
//
//  Created by Moses A. on 29/10/2025.
//

import UIKit

extension AutoLayout {
    public struct Connector: Hashable, Sendable {
        public let type: Connectors
        public let content: UIView
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(content)
        }
    }
    
    public struct HorizontalConnector: Hashable, Sendable {
        let leading: Connector
        let trailing: Connector
        let spacing: CGFloat
        let order: ConnectorOrders
    }
    
    public struct VerticalConnector: Hashable, Sendable {
        let top: Connector
        let bottom: Connector
        let spacing: CGFloat
        let order: ConnectorOrders
    }
    
    enum ConnectorOrders {
        case leadingTrailing
        case trailingLeading
        case topBottom
        case bottomTop
    }
    
    public indirect enum Connectors: Equatable, Sendable {
        case top
        case bottom
        case leading
        case trailing
        case all
        case horizontal(HorizontalConnector)
        case vertical(VerticalConnector)
        case height
        case width
        case center
        
        public static func == (lhs: Connectors, rhs: Connectors) -> Bool {
            switch (lhs, rhs) {
            case let (.horizontal(a), .horizontal(b)):
                return a.hashValue == b.hashValue
            case let (.vertical(a), .vertical(b)):
                return a.hashValue == b.hashValue
            case (.top, .top), (.bottom, .bottom), (.leading, .leading),
                (.trailing, .trailing), (.all, .all), (.height, .height), (.width, .width):
                return true
            case (.center, .center):
                return true
            default:
                return false
            }
        }
    }
    
    public enum Size: Equatable, Sendable {
        case height(CGFloat)
        case width(CGFloat)
        case size(CGSize)
        case equal(CGFloat)
        
        func extendConstraints(_ constraints: [AutoLayout.Connectors]) -> [AutoLayout.Connectors] {
            
            let hasHeight = constraints.contains(.height)
            let hasWidth = constraints.contains(.width)
            
            switch self {
            case .height:
                guard !hasHeight else { return constraints }
                return constraints + [.height]
                
            case .width:
                guard !hasWidth else { return constraints }
                return constraints + [.width]
                
            case .size, .equal:
                var result = constraints
                if !hasHeight { result.append(.height) }
                if !hasWidth { result.append(.width) }
                return result
            }
        }
    }
    
    public enum Center: Equatable, Sendable {
        case x(CGFloat)
        case y(CGFloat)
        case xEqual(NSLayoutXAxisAnchor)
        case yEqual(NSLayoutYAxisAnchor)
    }
}
