//
//  Attribute.swift
//  AutoLayout
//
//  Created by Moses A. on 29/10/2025.
//

import UIKit

enum VerticalAttribute {
    case top
    case bottom
    
    var connectorType: AutoLayout.Connectors {
        switch self {
        case .top: return .top
        case .bottom: return .bottom
        }
    }
}

enum HorizontalAttribute {
    case leading
    case trailing
    
    var connectorType: AutoLayout.Connectors {
        switch self {
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
}
