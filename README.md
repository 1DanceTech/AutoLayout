# AutoLayout

A production-grade, type-safe Auto Layout framework for iOS that dramatically reduces constraint boilerplate while providing powerful features like safe area management, constraint animations, aspect ratios, and visual debugging.

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2013+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

UIKit's Auto Layout is powerful but verbose. A simple card layout can balloon to 50+ lines of constraint code. AutoLayout solves this with a compositional, type-safe API that turns seven lines into one:

```swift
// Before: Standard UIKit
contentView.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
    contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
    contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
    contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
])

// After: AutoLayout Framework
containerView.setupConstraints(of: contentView, layout: .init(insets: .all(16)))
```

## Installation

### Swift Package Manager

Add AutoLayout to your project via SPM:

```swift
dependencies: [
    .package(url: "https://github.com/1DanceTech/AutoLayout.git", from: "main")
]
```

Or in Xcode: **File → Add Package Dependencies** and enter the repository URL.

## Features

- **Declarative API** — Express layout intent clearly and concisely
- **Type-Safe Constraints** — Catch errors at compile time, not runtime
- **Safe Area Management** — Unified handling of safe area, layout margins, and keyboard
- **Priority System** — Semantic constraint priorities with fluent API
- **Aspect Ratios** — Built-in support for common ratios and dynamic calculations
- **Animations** — First-class constraint animation with spring physics
- **Debug Visualization** — Visual overlays and conflict detection
- **Builder Pattern** — Fluent interface for complex layouts

## Quick Start

### Basic Constraints

```swift
// Pin to all edges with insets
containerView.setupConstraints(
    of: contentView,
    layout: .init(insets: .all(16))
)

// Selective edges
containerView.setupConstraints(
    of: headerView,
    layout: AutoLayout(
        insets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20),
        types: [.top, .leading, .trailing]
    )
)

// Fixed size
containerView.setupConstraints(
    of: avatarView,
    layout: AutoLayout(
        size: .equal(64),  // 64×64 square
        types: [.width, .height]
    )
)
```

### Builder Pattern

For complex layouts, use the fluent builder:

```swift
view.layout(headerView, contentScrollView, footerView)
    .with(headerView, 
          insets: .options(top: 0, left: 0, right: 0),
          size: .height(88),
          constraints: [.top, .leading, .trailing, .height])
    .with(contentScrollView,
          insets: .options(left: 0, right: 0),
          constraints: [.leading, .trailing])
    .linkV(from: contentScrollView, to: headerView, 0)
    .with(footerView,
          insets: .options(left: 0, bottom: 0, right: 0),
          size: .height(49),
          constraints: [.leading, .trailing, .bottom, .height])
    .linkV(from: footerView, to: contentScrollView, 0)
    .apply(to: view)
```

### Vertical Stacks

```swift
view.layout(titleLabel, subtitleLabel, descriptionLabel, actionButton)
    .startStack()
    .with(titleLabel, constraints: [.top, .leading, .trailing])
    .with(subtitleLabel, constraints: [.leading, .trailing])
    .with(descriptionLabel, constraints: [.leading, .trailing])
    .with(actionButton, 
          size: .height(44),
          constraints: [.leading, .trailing, .bottom, .height])
    .stackV(12)  // 12pt spacing between all elements
    .apply(to: view)
```

## Safe Area Management

Configure each edge to respect different layout guides:

```swift
let config = SafeAreaConfiguration(
    top: .safeArea,
    bottom: .keyboard,      // Adjusts for keyboard automatically
    leading: .layoutMargins,
    trailing: .layoutMargins
)

view.setupSafeAreaConstraints(
    of: inputContainerView,
    safeAreaConfig: config
)
```

**Built-in Presets:**

| Preset | Description |
|--------|-------------|
| `.allSafeArea` | All edges respect safe area (default) |
| `.verticalSafeArea` | Full-width content with vertical safe area |
| `.readableContent` | Optimal width for text-heavy interfaces |
| `.layoutMargins` | Uses system layout margins |

## Constraint Priorities

Semantic priority definitions for cleaner code:

```swift
public struct ConstraintPriority {
    static let required = ConstraintPriority(1000)
    static let almostRequired = ConstraintPriority(999)
    static let defaultHigh = ConstraintPriority(750)
    static let medium = ConstraintPriority(500)
    static let defaultLow = ConstraintPriority(250)
    static let veryLow = ConstraintPriority(100)
}

// Usage
let heightConstraint = contentView.heightAnchor
    .constraint(equalToConstant: 200)
    .withPriority(.defaultHigh)

// Batch application
view.constraints(for: cardView, layout: .init(insets: .all(16)))
    .activate(priority: .defaultHigh)
```

## Aspect Ratios

Built-in support for common aspect ratios:

```swift
// Standard ratios
imageView.constrainAspectRatio(.widescreen)  // 16:9
imageView.constrainAspectRatio(.square)       // 1:1
imageView.constrainAspectRatio(.photo)        // 3:2
imageView.constrainAspectRatio(.portrait)     // 9:16
imageView.constrainAspectRatio(.golden)       // 1.618:1

// With fixed dimension
thumbnailView.constrainAspectRatio(
    .photo,
    fixedDimension: .width,
    value: 120  // 120pt wide → 80pt tall
)

// From image
if let heroImage = UIImage(named: "hero_banner") {
    heroImageView.constrainAspectRatio(.from(heroImage))
}

// Aspect fit/fill
videoPlayer.constrainAspectFit(ratio: .widescreen, within: CGSize(width: 320, height: 320))
backgroundImage.constrainAspectFill(ratio: .photo, filling: CGSize(width: 320, height: 320))
```

## Animations

First-class animation support with spring physics:

```swift
let animator = panelView.constraintAnimator
animator.store(heightConstraint, key: "panelHeight")

// Animate with spring physics
animator.animateConstant(forKey: "panelHeight", to: 400, config: .spring)

// Multiple constraints
animator.animateConstraints(
    changes: ["panelHeight": 500, "panelBottom": -100],
    config: .bounce
) { finished in
    print("Animation completed")
}
```

**Animation Presets:**

| Preset | Duration | Description |
|--------|----------|-------------|
| `.default` | 0.3s | Standard animation |
| `.quick` | 0.15s | Micro-interactions |
| `.spring` | 0.5s | Bouncy reveals |
| `.bounce` | 0.6s | Playful animations |
| `.smooth` | 0.4s | Elegant transitions |

### State Transitions

```swift
let transition = drawer.createTransition(
    from: collapsedConstraints,
    to: expandedConstraints
)

transition.perform(config: .spring)   // Expand
transition.reverse(config: .smooth)   // Collapse
```

### Async/Await Support

```swift
func expandPanel() async {
    let finished = await panelView.animateConstraintsAsync(config: .spring) {
        self.panelHeightConstraint.constant = 500
    }
    
    if finished {
        await panelView.animateConstraintsAsync(config: .quick) {
            self.panelAlphaConstraint.constant = 1.0
        }
    }
}
```

## Debug Visualization

Visual debugging tools for constraint issues:

```swift
// Toggle debug overlay
containerView.toggleDebugVisualization()

// With configuration
let config = DebugVisualizationConfig(
    showViewBorders: true,
    showConstraintLines: true,
    showAnchorPoints: true,
    showLabels: true,
    colorScheme: .highContrast
)
containerView.toggleDebugVisualization(config: config)

// Conflict detection
let conflicts = AutoLayoutDebugManager.shared.analyzeConstraints(for: containerView)
for conflict in conflicts {
    print("⚠️ \(conflict.description)")
    if let fix = conflict.suggestedFix {
        print("   Suggested: \(fix)")
    }
}

// Console output
containerView.debugPrintConstraints()
```

## Quick Reference

### Common Patterns

| Pattern | Code |
|---------|------|
| Pin to all edges | `.init(insets: .all(16))` |
| Pin to safe area | `setupSafeAreaConstraints(safeAreaConfig: .allSafeArea)` |
| Fixed size | `.init(size: .equal(44), types: [.width, .height])` |
| Centered | `.init(center: [.x(0), .y(0)], types: [.center])` |
| Aspect ratio | `view.constrainAspectRatio(.widescreen)` |
| Vertical stack | `.stackV(12)` |
| Horizontal chain | `.linkH(spacing: 8)` |

### Priority Guide

| Priority | Value | Use Case |
|----------|-------|----------|
| `.required` | 1000 | Must-satisfy constraints |
| `.almostRequired` | 999 | Breakable only in extreme cases |
| `.defaultHigh` | 750 | Content hugging/compression |
| `.medium` | 500 | Preferred but flexible |
| `.defaultLow` | 250 | Easily breakable |

## Requirements

- iOS 13.0+
- Swift 5.5+
- Xcode 13.0+

## License

AutoLayout is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Resources

- [Complete Guide](https://1dance.substack.com/p/a-complete-guide-to-ios-autolayout) — In-depth tutorial and architecture overview
- [API Documentation](https://github.com/1DanceTech/AutoLayout) — Full API reference

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
