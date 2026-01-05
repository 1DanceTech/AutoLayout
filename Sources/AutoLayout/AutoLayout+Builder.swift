//
//  AutoLayout+Builder.swift
//  AutoLayout
//
//  Created by Moses A. on 29/10/2025.
//

import UIKit

extension AutoLayout {
    struct Builder {
        
        @MainActor static func buildConstraints(for content: UIView,
                                     in container: UIView,
                                     layout: AutoLayout) -> [NSLayoutConstraint] {
            content.translatesAutoresizingMaskIntoConstraints = false
            
            let constraintTypes = layout.types.contains(.all)
            ? [.all]
            : layout.types.filter { $0 != .all }
            
            return constraintTypes.flatMap { type in
                createConstraints(for: content, in: container, layout: layout, type: type)
            }
        }
        
        @MainActor private static func createConstraints(for content: UIView,
                                              in container: UIView,
                                              layout: AutoLayout,
                                              type: AutoLayout.Connectors) -> [NSLayoutConstraint] {
            switch type {
            case .top:
                return [content.topAnchor.constraint(equalTo: container.topAnchor, constant: layout.top)]
                
            case .bottom:
                return [content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -layout.bottom)]
                
            case .leading:
                return [content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: layout.leading)]
                
            case .trailing:
                return [content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -layout.trailing)]
                
            case .all:
                return [
                    content.topAnchor.constraint(equalTo: container.topAnchor, constant: layout.top),
                    content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -layout.bottom),
                    content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: layout.leading),
                    content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -layout.trailing)
                ]
                
            case .horizontal(let connector):
                return createHorizontalConstraint(connector)
                
            case .vertical(let connector):
                return createVerticalConstraint(connector)
                
            case .height:
                
                if case .height(let value) = layout.size {
                    return [content.heightAnchor.constraint(equalToConstant: value)]
                } else if case .size(let value) = layout.size {
                    return [content.heightAnchor.constraint(equalToConstant: value.height)]
                } else if case .equal(let value) = layout.size {
                    return [content.heightAnchor.constraint(equalToConstant: value)]
                }
                
                return []
            case .width:
                if case .width(let value) = layout.size {
                    return [content.widthAnchor.constraint(equalToConstant: value)]
                } else if case .size(let value) = layout.size {
                    return [content.widthAnchor.constraint(equalToConstant: value.width)]
                } else if case .equal(let value) = layout.size {
                    return [content.widthAnchor.constraint(equalToConstant: value)]
                }
                
                return []
            case .center:
                return layout.center?
                    .map { item in
                        switch item {
                        case .x(let value):
                            return content.centerXAnchor.constraint(equalTo: container.centerXAnchor, constant: value)
                        case .y(let value):
                            return content.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: value)
                        case .xEqual(let value):
                            return content.centerXAnchor.constraint(equalTo: value, constant: 0)
                        case .yEqual(let value):
                            return content.centerYAnchor.constraint(equalTo: value, constant: 0)
                        }
                    } ?? []
            }
        }
        
        @MainActor private static func createHorizontalConstraint(_ connector: AutoLayout.HorizontalConnector) -> [NSLayoutConstraint] {
            [connector.leading.content, connector.trailing.content]
                .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
            
            let constraint: NSLayoutConstraint? = switch connector.order {
            case .trailingLeading:
                connector.trailing.content.trailingAnchor.constraint(
                    equalTo: connector.leading.content.leadingAnchor,
                    constant: -connector.spacing
                )
            case .leadingTrailing:
                connector.leading.content.leadingAnchor.constraint(
                    equalTo: connector.trailing.content.trailingAnchor,
                    constant: connector.spacing
                )
            default : nil
            }
            
            return constraint.map { [$0] } ?? []
        }
        
        @MainActor private static func createVerticalConstraint(_ connector: AutoLayout.VerticalConnector) -> [NSLayoutConstraint] {
            [connector.top.content, connector.bottom.content]
                .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
            
            let constraint: NSLayoutConstraint? = switch connector.order {
            case .topBottom:
                connector.top.content.topAnchor.constraint(
                    equalTo: connector.bottom.content.bottomAnchor,
                    constant: connector.spacing
                )
            case .bottomTop:
                connector.bottom.content.bottomAnchor.constraint(
                    equalTo: connector.top.content.topAnchor,
                    constant: -connector.spacing
                )
                
            default : nil
            }
            
            return constraint.map { [$0] } ?? []
        }
    }
}
