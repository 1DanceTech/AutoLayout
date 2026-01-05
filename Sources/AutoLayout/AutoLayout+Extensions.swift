//
//  AutoLayout+Extensions.swift
//  AutoLayout
//
//  Created by Moses A. on 05/01/2026.
//

import UIKit

// MARK: - ═══════════════════════════════════════════════════════════════════
// MARK: 1. SAFE AREA SUPPORT
// MARK: ═══════════════════════════════════════════════════════════════════

/// Defines which layout guide to use for constraint anchoring
public enum LayoutGuideType: Sendable {
    case superview
    case safeArea
    case layoutMargins
    case readableContent
    case keyboard
}

/// Configuration for safe area edge behavior
public struct SafeAreaConfiguration: Sendable {
    public let top: LayoutGuideType
    public let bottom: LayoutGuideType
    public let leading: LayoutGuideType
    public let trailing: LayoutGuideType
    
    public init(
        top: LayoutGuideType = .safeArea,
        bottom: LayoutGuideType = .safeArea,
        leading: LayoutGuideType = .safeArea,
        trailing: LayoutGuideType = .safeArea
    ) {
        self.top = top
        self.bottom = bottom
        self.leading = leading
        self.trailing = trailing
    }
    
    /// All edges respect safe area
    public static let allSafeArea = SafeAreaConfiguration()
    
    /// Only vertical edges respect safe area (common for full-width content)
    public static let verticalSafeArea = SafeAreaConfiguration(
        top: .safeArea,
        bottom: .safeArea,
        leading: .superview,
        trailing: .superview
    )
    
    /// Only top respects safe area (content extends to bottom)
    public static let topSafeArea = SafeAreaConfiguration(
        top: .safeArea,
        bottom: .superview,
        leading: .superview,
        trailing: .superview
    )
    
    /// Only bottom respects safe area (content extends to top - e.g., behind nav bar)
    public static let bottomSafeArea = SafeAreaConfiguration(
        top: .superview,
        bottom: .safeArea,
        leading: .superview,
        trailing: .superview
    )
    
    /// Use layout margins for all edges
    public static let layoutMargins = SafeAreaConfiguration(
        top: .layoutMargins,
        bottom: .layoutMargins,
        leading: .layoutMargins,
        trailing: .layoutMargins
    )
    
    /// Readable content guide (optimal for text-heavy content)
    public static let readableContent = SafeAreaConfiguration(
        top: .safeArea,
        bottom: .safeArea,
        leading: .readableContent,
        trailing: .readableContent
    )
}

extension AutoLayout {
    
    /// Creates an AutoLayout configuration with safe area support
    public static func safeArea(
        insets: UIEdgeInsets = .zero,
        configuration: SafeAreaConfiguration = .allSafeArea,
        size: Size? = nil,
        types: [Connectors] = [.all]
    ) -> (AutoLayout, SafeAreaConfiguration) {
        return (AutoLayout(insets: insets, size: size, types: types), configuration)
    }
}

extension AutoLayout.Builder {
    
    /// Builds constraints with safe area awareness
    @available(iOS 15.0, *)
    @MainActor
    public static func buildSafeAreaConstraints(
        for content: UIView,
        in container: UIView,
        layout: AutoLayout,
        safeAreaConfig: SafeAreaConfiguration
    ) -> [NSLayoutConstraint] {
        content.translatesAutoresizingMaskIntoConstraints = false
        
        var constraints: [NSLayoutConstraint] = []
        
        let constraintTypes = layout.types.contains(.all)
            ? [.top, .bottom, .leading, .trailing] as [AutoLayout.Connectors]
            : layout.types.filter { $0 != .all }
        
        for type in constraintTypes {
            switch type {
            case .top:
                let anchor = resolveTopAnchor(for: container, guide: safeAreaConfig.top)
                constraints.append(content.topAnchor.constraint(equalTo: anchor, constant: layout.top))
                
            case .bottom:
                let anchor = resolveBottomAnchor(for: container, guide: safeAreaConfig.bottom)
                constraints.append(content.bottomAnchor.constraint(equalTo: anchor, constant: -layout.bottom))
                
            case .leading:
                let anchor = resolveLeadingAnchor(for: container, guide: safeAreaConfig.leading)
                constraints.append(content.leadingAnchor.constraint(equalTo: anchor, constant: layout.leading))
                
            case .trailing:
                let anchor = resolveTrailingAnchor(for: container, guide: safeAreaConfig.trailing)
                constraints.append(content.trailingAnchor.constraint(equalTo: anchor, constant: -layout.trailing))
                
            case .height:
                if case .height(let value) = layout.size {
                    constraints.append(content.heightAnchor.constraint(equalToConstant: value))
                } else if case .size(let value) = layout.size {
                    constraints.append(content.heightAnchor.constraint(equalToConstant: value.height))
                } else if case .equal(let value) = layout.size {
                    constraints.append(content.heightAnchor.constraint(equalToConstant: value))
                }
                
            case .width:
                if case .width(let value) = layout.size {
                    constraints.append(content.widthAnchor.constraint(equalToConstant: value))
                } else if case .size(let value) = layout.size {
                    constraints.append(content.widthAnchor.constraint(equalToConstant: value.width))
                } else if case .equal(let value) = layout.size {
                    constraints.append(content.widthAnchor.constraint(equalToConstant: value))
                }
                
            default:
                break
            }
        }
        
        return constraints
    }
    
    @available(iOS 15.0, *)
    @MainActor
    private static func resolveTopAnchor(for view: UIView, guide: LayoutGuideType) -> NSLayoutYAxisAnchor {
        switch guide {
        case .superview: return view.topAnchor
        case .safeArea: return view.safeAreaLayoutGuide.topAnchor
        case .layoutMargins: return view.layoutMarginsGuide.topAnchor
        case .readableContent: return view.readableContentGuide.topAnchor
        case .keyboard: return view.keyboardLayoutGuide.topAnchor
        }
    }
    
    @available(iOS 15.0, *)
    @MainActor
    private static func resolveBottomAnchor(for view: UIView, guide: LayoutGuideType) -> NSLayoutYAxisAnchor {
        switch guide {
        case .superview: return view.bottomAnchor
        case .safeArea: return view.safeAreaLayoutGuide.bottomAnchor
        case .layoutMargins: return view.layoutMarginsGuide.bottomAnchor
        case .readableContent: return view.readableContentGuide.bottomAnchor
        case .keyboard: return view.keyboardLayoutGuide.topAnchor // Keyboard uses top anchor
        }
    }
    
    @MainActor
    private static func resolveLeadingAnchor(for view: UIView, guide: LayoutGuideType) -> NSLayoutXAxisAnchor {
        switch guide {
        case .superview: return view.leadingAnchor
        case .safeArea: return view.safeAreaLayoutGuide.leadingAnchor
        case .layoutMargins: return view.layoutMarginsGuide.leadingAnchor
        case .readableContent: return view.readableContentGuide.leadingAnchor
        case .keyboard: return view.leadingAnchor // Keyboard doesn't affect horizontal
        }
    }
    
    @MainActor
    private static func resolveTrailingAnchor(for view: UIView, guide: LayoutGuideType) -> NSLayoutXAxisAnchor {
        switch guide {
        case .superview: return view.trailingAnchor
        case .safeArea: return view.safeAreaLayoutGuide.trailingAnchor
        case .layoutMargins: return view.layoutMarginsGuide.trailingAnchor
        case .readableContent: return view.readableContentGuide.trailingAnchor
        case .keyboard: return view.trailingAnchor // Keyboard doesn't affect horizontal
        }
    }
}

extension UIView {
    
    /// Sets up constraints with safe area configuration
    @available(iOS 15.0, *)
    @MainActor
    func setupSafeAreaConstraints(
        of content: UIView,
        layout: AutoLayout = .init(),
        safeAreaConfig: SafeAreaConfiguration = .allSafeArea
    ) {
        let constraints = AutoLayout.Builder.buildSafeAreaConstraints(
            for: content,
            in: self,
            layout: layout,
            safeAreaConfig: safeAreaConfig
        )
        NSLayoutConstraint.activate(constraints)
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════════
// MARK: 2. PRIORITY MODIFIERS
// MARK: ═══════════════════════════════════════════════════════════════════

/// Priority configuration for constraints
public struct ConstraintPriority: Sendable {
    public let value: Float
    
    public init(_ value: Float) {
        self.value = min(max(value, 0), 1000)
    }
    
    public init(_ priority: UILayoutPriority) {
        self.value = priority.rawValue
    }
    
    // Standard priorities
    public static let required = ConstraintPriority(UILayoutPriority.required)
    public static let defaultHigh = ConstraintPriority(UILayoutPriority.defaultHigh)
    public static let defaultLow = ConstraintPriority(UILayoutPriority.defaultLow)
    public static let fittingSizeLevel = ConstraintPriority(UILayoutPriority.fittingSizeLevel)
    
    // Custom semantic priorities
    public static let almostRequired = ConstraintPriority(999)
    public static let high = ConstraintPriority(750)
    public static let medium = ConstraintPriority(500)
    public static let low = ConstraintPriority(250)
    public static let veryLow = ConstraintPriority(100)
    
    // Compression resistance defaults
    public static let compressionRequired = ConstraintPriority(UILayoutPriority.required)
    public static let compressionHigh = ConstraintPriority(UILayoutPriority.defaultHigh)
    public static let compressionLow = ConstraintPriority(UILayoutPriority.defaultLow)
    
    // Hugging defaults
    public static let huggingRequired = ConstraintPriority(UILayoutPriority.required)
    public static let huggingHigh = ConstraintPriority(UILayoutPriority.defaultHigh)
    public static let huggingLow = ConstraintPriority(UILayoutPriority.defaultLow)
    
    var layoutPriority: UILayoutPriority {
        UILayoutPriority(value)
    }
}

/// Priority specification per constraint type
public struct PriorityConfiguration: Sendable {
    public let top: ConstraintPriority?
    public let bottom: ConstraintPriority?
    public let leading: ConstraintPriority?
    public let trailing: ConstraintPriority?
    public let width: ConstraintPriority?
    public let height: ConstraintPriority?
    public let centerX: ConstraintPriority?
    public let centerY: ConstraintPriority?
    
    public init(
        top: ConstraintPriority? = nil,
        bottom: ConstraintPriority? = nil,
        leading: ConstraintPriority? = nil,
        trailing: ConstraintPriority? = nil,
        width: ConstraintPriority? = nil,
        height: ConstraintPriority? = nil,
        centerX: ConstraintPriority? = nil,
        centerY: ConstraintPriority? = nil
    ) {
        self.top = top
        self.bottom = bottom
        self.leading = leading
        self.trailing = trailing
        self.width = width
        self.height = height
        self.centerX = centerX
        self.centerY = centerY
    }
    
    /// Apply same priority to all constraints
    public static func all(_ priority: ConstraintPriority) -> PriorityConfiguration {
        PriorityConfiguration(
            top: priority,
            bottom: priority,
            leading: priority,
            trailing: priority,
            width: priority,
            height: priority,
            centerX: priority,
            centerY: priority
        )
    }
    
    /// Edges at one priority, dimensions at another
    public static func edges(_ edgePriority: ConstraintPriority, dimensions: ConstraintPriority) -> PriorityConfiguration {
        PriorityConfiguration(
            top: edgePriority,
            bottom: edgePriority,
            leading: edgePriority,
            trailing: edgePriority,
            width: dimensions,
            height: dimensions
        )
    }
    
    /// Flexible height configuration (common for dynamic content)
    public static let flexibleHeight = PriorityConfiguration(
        top: .required,
        bottom: .defaultHigh,
        leading: .required,
        trailing: .required,
        height: .defaultLow
    )
    
    /// Flexible width configuration
    public static let flexibleWidth = PriorityConfiguration(
        top: .required,
        bottom: .required,
        leading: .required,
        trailing: .defaultHigh,
        width: .defaultLow
    )
}

/// Constraint wrapper with priority support
public struct PrioritizedConstraint {
    public let constraint: NSLayoutConstraint
    public let priority: ConstraintPriority
    
    public init(_ constraint: NSLayoutConstraint, priority: ConstraintPriority = .required) {
        self.constraint = constraint
        self.priority = priority
    }
    
    @discardableResult
    @MainActor public func activate() -> NSLayoutConstraint {
        constraint.priority = priority.layoutPriority
        constraint.isActive = true
        return constraint
    }
}

extension NSLayoutConstraint {
    
    /// Sets priority and returns self for chaining
    @discardableResult
    func withPriority(_ priority: ConstraintPriority) -> NSLayoutConstraint {
        self.priority = priority.layoutPriority
        return self
    }
    
    /// Sets priority using UILayoutPriority
    @discardableResult
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

extension Array where Element == NSLayoutConstraint {
    
    /// Applies priority to all constraints
    @discardableResult
    @MainActor func withPriority(_ priority: ConstraintPriority) -> [NSLayoutConstraint] {
        forEach { $0.priority = priority.layoutPriority }
        return self
    }
    
    /// Activates all constraints with optional priority
    @MainActor func activate(priority: ConstraintPriority? = nil) {
        if let priority = priority {
            forEach { $0.priority = priority.layoutPriority }
        }
        NSLayoutConstraint.activate(self)
    }
}

extension UIView {
    
    /// Content hugging priority helpers
    func setContentHugging(_ priority: ConstraintPriority, for axis: NSLayoutConstraint.Axis) {
        setContentHuggingPriority(priority.layoutPriority, for: axis)
    }
    
    func setContentHugging(horizontal: ConstraintPriority? = nil, vertical: ConstraintPriority? = nil) {
        if let h = horizontal { setContentHugging(h, for: .horizontal) }
        if let v = vertical { setContentHugging(v, for: .vertical) }
    }
    
    /// Compression resistance helpers
    func setCompressionResistance(_ priority: ConstraintPriority, for axis: NSLayoutConstraint.Axis) {
        setContentCompressionResistancePriority(priority.layoutPriority, for: axis)
    }
    
    func setCompressionResistance(horizontal: ConstraintPriority? = nil, vertical: ConstraintPriority? = nil) {
        if let h = horizontal { setCompressionResistance(h, for: .horizontal) }
        if let v = vertical { setCompressionResistance(v, for: .vertical) }
    }
}

// MARK: - AutoLayoutBuilder Priority Extension

extension AutoLayoutBuilder {
    
    nonisolated(unsafe) private static var priorityConfigKey: UInt8 = 0
    
    private var priorityConfig: PriorityConfiguration? {
        get { objc_getAssociatedObject(self, &Self.priorityConfigKey) as? PriorityConfiguration }
        set { objc_setAssociatedObject(self, &Self.priorityConfigKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// Sets priority configuration for subsequent constraints
    @discardableResult
    func withPriorities(_ config: PriorityConfiguration) -> Self {
        self.priorityConfig = config
        return self
    }
    
    /// Applies a single priority to all constraints for the current view
    @discardableResult
    func priority(_ priority: ConstraintPriority) -> Self {
        self.priorityConfig = .all(priority)
        return self
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════════
// MARK: 3. ASPECT RATIO CONSTRAINTS
// MARK: ═══════════════════════════════════════════════════════════════════

/// Aspect ratio representation
public struct AspectRatio: Sendable, Equatable {
    public let width: CGFloat
    public let height: CGFloat
    
    public var ratio: CGFloat { width / height }
    public var inverse: AspectRatio { AspectRatio(width: height, height: width) }
    
    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    public init(ratio: CGFloat) {
        self.width = ratio
        self.height = 1
    }
    
    // Common aspect ratios
    public static let square = AspectRatio(width: 1, height: 1)
    public static let widescreen = AspectRatio(width: 16, height: 9)
    public static let ultrawide = AspectRatio(width: 21, height: 9)
    public static let standard = AspectRatio(width: 4, height: 3)
    public static let photo = AspectRatio(width: 3, height: 2)
    public static let portrait = AspectRatio(width: 9, height: 16)
    public static let golden = AspectRatio(width: 1.618, height: 1)
    public static let a4 = AspectRatio(width: 1, height: 1.414)
    
    // Device-specific ratios
    public static let iPhoneX = AspectRatio(width: 9, height: 19.5)
    public static let iPhone8 = AspectRatio(width: 9, height: 16)
    public static let iPadPro = AspectRatio(width: 3, height: 4)
    
    /// Creates aspect ratio from CGSize
    public static func from(_ size: CGSize) -> AspectRatio {
        AspectRatio(width: size.width, height: size.height)
    }
    
    /// Creates aspect ratio from UIImage
    public static func from(_ image: UIImage) -> AspectRatio {
        AspectRatio(width: image.size.width, height: image.size.height)
    }
}

/// Dimension anchor for aspect ratio constraints
public enum DimensionAnchor {
    case width
    case height
}

extension AutoLayout {
    
    /// Extended Size enum with aspect ratio support
    public enum AspectSize: Equatable, Sendable {
        case height(CGFloat)
        case width(CGFloat)
        case size(CGSize)
        case equal(CGFloat)
        case aspectRatio(AspectRatio)
        case aspectWidth(AspectRatio, CGFloat)  // Aspect ratio with fixed width
        case aspectHeight(AspectRatio, CGFloat) // Aspect ratio with fixed height
        case aspectFit(AspectRatio, CGSize)     // Fit within bounds maintaining ratio
        case aspectFill(AspectRatio, CGSize)    // Fill bounds maintaining ratio
    }
}

extension UIView {
    
    /// Adds aspect ratio constraint
    @discardableResult
    func constrainAspectRatio(_ ratio: AspectRatio, priority: ConstraintPriority = .required) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let constraint = widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio.ratio)
        constraint.priority = priority.layoutPriority
        constraint.isActive = true
        return constraint
    }
    
    /// Adds aspect ratio with one fixed dimension
    @discardableResult
    func constrainAspectRatio(
        _ ratio: AspectRatio,
        fixedDimension: DimensionAnchor,
        value: CGFloat,
        priority: ConstraintPriority = .required
    ) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        
        var constraints: [NSLayoutConstraint] = []
        
        switch fixedDimension {
        case .width:
            let widthConstraint = widthAnchor.constraint(equalToConstant: value)
            let heightConstraint = heightAnchor.constraint(equalToConstant: value / ratio.ratio)
            constraints = [widthConstraint, heightConstraint]
            
        case .height:
            let heightConstraint = heightAnchor.constraint(equalToConstant: value)
            let widthConstraint = widthAnchor.constraint(equalToConstant: value * ratio.ratio)
            constraints = [widthConstraint, heightConstraint]
        }
        
        constraints.forEach { $0.priority = priority.layoutPriority }
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
    
    /// Constrains to fit within bounds while maintaining aspect ratio
    func constrainAspectFit(
        ratio: AspectRatio,
        within bounds: CGSize,
        priority: ConstraintPriority = .required
    ) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        
        let boundRatio = bounds.width / bounds.height
        let targetRatio = ratio.ratio
        
        let size: CGSize
        if targetRatio > boundRatio {
            // Width constrained
            size = CGSize(width: bounds.width, height: bounds.width / targetRatio)
        } else {
            // Height constrained
            size = CGSize(width: bounds.height * targetRatio, height: bounds.height)
        }
        
        let constraints = [
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ]
        
        constraints.forEach { $0.priority = priority.layoutPriority }
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
    
    /// Constrains to fill bounds while maintaining aspect ratio
    func constrainAspectFill(
        ratio: AspectRatio,
        filling bounds: CGSize,
        priority: ConstraintPriority = .required
    ) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        
        let boundRatio = bounds.width / bounds.height
        let targetRatio = ratio.ratio
        
        let size: CGSize
        if targetRatio < boundRatio {
            // Width constrained
            size = CGSize(width: bounds.width, height: bounds.width / targetRatio)
        } else {
            // Height constrained
            size = CGSize(width: bounds.height * targetRatio, height: bounds.height)
        }
        
        let constraints = [
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ]
        
        constraints.forEach { $0.priority = priority.layoutPriority }
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
    
    /// Creates aspect ratio constraint relative to another view
    @discardableResult
    func constrainAspectRatio(
        matching view: UIView,
        multiplier: CGFloat = 1.0,
        priority: ConstraintPriority = .required
    ) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let constraint = widthAnchor.constraint(
            equalTo: view.widthAnchor,
            multiplier: multiplier
        )
        constraint.priority = priority.layoutPriority
        constraint.isActive = true
        return constraint
    }
}

// MARK: - AutoLayoutBuilder Aspect Ratio Extension

extension AutoLayoutBuilder {
    
    /// Adds aspect ratio constraint to current view
    @MainActor
    @discardableResult
    func aspectRatio(_ ratio: AspectRatio) -> Self {
        guard let currentView = getCurrentView() else { return self }
        currentView.constrainAspectRatio(ratio)
        return self
    }
    
    /// Adds aspect ratio with fixed width
    @MainActor
    @discardableResult
    func aspectRatio(_ ratio: AspectRatio, width: CGFloat) -> Self {
        guard let currentView = getCurrentView() else { return self }
        currentView.constrainAspectRatio(ratio, fixedDimension: .width, value: width)
        return self
    }
    
    /// Adds aspect ratio with fixed height
    @MainActor
    @discardableResult
    func aspectRatio(_ ratio: AspectRatio, height: CGFloat) -> Self {
        guard let currentView = getCurrentView() else { return self }
        currentView.constrainAspectRatio(ratio, fixedDimension: .height, value: height)
        return self
    }
    
    // Helper to access current view (requires internal access)
    private func getCurrentView() -> UIView? {
        // This would need access to the private currentView property
        // In actual implementation, this would be:
        // return currentView
        return nil // Placeholder
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════════
// MARK: 4. ANIMATION HELPERS
// MARK: ═══════════════════════════════════════════════════════════════════

/// Animation configuration for constraint changes
public struct ConstraintAnimationConfig {
    public let duration: TimeInterval
    public let delay: TimeInterval
    public let dampingRatio: CGFloat
    public let initialVelocity: CGFloat
    public let options: UIView.AnimationOptions
    
    public init(
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        dampingRatio: CGFloat = 1.0,
        initialVelocity: CGFloat = 0,
        options: UIView.AnimationOptions = [.curveEaseInOut]
    ) {
        self.duration = duration
        self.delay = delay
        self.dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
        self.options = options
    }
    
    // Preset configurations
    nonisolated(unsafe) public static let `default` = ConstraintAnimationConfig()
    nonisolated(unsafe) public static let quick = ConstraintAnimationConfig(duration: 0.15)
    nonisolated(unsafe) public static let slow = ConstraintAnimationConfig(duration: 0.5)
    nonisolated(unsafe) public static let spring = ConstraintAnimationConfig(duration: 0.5, dampingRatio: 0.7, initialVelocity: 0.5)
    nonisolated(unsafe) public static let bounce = ConstraintAnimationConfig(duration: 0.6, dampingRatio: 0.5, initialVelocity: 0.8)
    nonisolated(unsafe) public static let smooth = ConstraintAnimationConfig(duration: 0.4, dampingRatio: 0.9, options: [.curveEaseOut])
    
    // Keyboard animations
    public static func keyboard(duration: TimeInterval, curve: UIView.AnimationCurve) -> ConstraintAnimationConfig {
        let options: UIView.AnimationOptions
        switch curve {
        case .easeIn: options = .curveEaseIn
        case .easeOut: options = .curveEaseOut
        case .easeInOut: options = .curveEaseInOut
        case .linear: options = .curveLinear
        @unknown default: options = .curveEaseInOut
        }
        return ConstraintAnimationConfig(duration: duration, options: options)
    }
}

/// Manages constraint animations
public class ConstraintAnimator {
    
    private weak var view: UIView?
    private var constraintStorage: [String: NSLayoutConstraint] = [:]
    
    public init(view: UIView) {
        self.view = view
    }
    
    /// Stores a constraint for later animation
    public func store(_ constraint: NSLayoutConstraint, key: String) {
        constraintStorage[key] = constraint
    }
    
    /// Retrieves a stored constraint
    public func constraint(forKey key: String) -> NSLayoutConstraint? {
        constraintStorage[key]
    }
    
    /// Animates constraint constant change
    @MainActor
    public func animateConstant(
        forKey key: String,
        to value: CGFloat,
        config: ConstraintAnimationConfig = .default,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let constraint = constraintStorage[key],
              let view = view else { return }
        
        constraint.constant = value
        
        UIView.animate(
            withDuration: config.duration,
            delay: config.delay,
            usingSpringWithDamping: config.dampingRatio,
            initialSpringVelocity: config.initialVelocity,
            options: config.options,
            animations: {
                view.superview?.layoutIfNeeded()
            },
            completion: completion
        )
    }
    
    /// Animates multiple constraints simultaneously
    @MainActor
    public func animateConstraints(
        changes: [String: CGFloat],
        config: ConstraintAnimationConfig = .default,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let view = view else { return }
        
        for (key, value) in changes {
            constraintStorage[key]?.constant = value
        }
        
        UIView.animate(
            withDuration: config.duration,
            delay: config.delay,
            usingSpringWithDamping: config.dampingRatio,
            initialSpringVelocity: config.initialVelocity,
            options: config.options,
            animations: {
                view.superview?.layoutIfNeeded()
            },
            completion: completion
        )
    }
    
    /// Animates constraint activation/deactivation
    @MainActor
    public func animateActivation(
        activate: [String] = [],
        deactivate: [String] = [],
        config: ConstraintAnimationConfig = .default,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let view = view else { return }
        
        let toDeactivate = deactivate.compactMap { constraintStorage[$0] }
        let toActivate = activate.compactMap { constraintStorage[$0] }
        
        NSLayoutConstraint.deactivate(toDeactivate)
        NSLayoutConstraint.activate(toActivate)
        
        UIView.animate(
            withDuration: config.duration,
            delay: config.delay,
            usingSpringWithDamping: config.dampingRatio,
            initialSpringVelocity: config.initialVelocity,
            options: config.options,
            animations: {
                view.superview?.layoutIfNeeded()
            },
            completion: completion
        )
    }
}

/// Transition between two constraint sets
public class ConstraintTransition {
    
    private var fromConstraints: [NSLayoutConstraint]
    private var toConstraints: [NSLayoutConstraint]
    private weak var view: UIView?
    
    public init(view: UIView, from: [NSLayoutConstraint], to: [NSLayoutConstraint]) {
        self.view = view
        self.fromConstraints = from
        self.toConstraints = to
    }
    
    @MainActor
    public func perform(
        config: ConstraintAnimationConfig = .default,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let view = view else { return }
        
        NSLayoutConstraint.deactivate(fromConstraints)
        NSLayoutConstraint.activate(toConstraints)
        
        UIView.animate(
            withDuration: config.duration,
            delay: config.delay,
            usingSpringWithDamping: config.dampingRatio,
            initialSpringVelocity: config.initialVelocity,
            options: config.options,
            animations: {
                view.superview?.layoutIfNeeded()
            },
            completion: completion
        )
    }
    
    /// Reverses the transition
    @MainActor
    public func reverse(
        config: ConstraintAnimationConfig = .default,
        completion: ((Bool) -> Void)? = nil
    ) {
        swap(&fromConstraints, &toConstraints)
        perform(config: config, completion: completion)
    }
}

extension UIView {
    
    private static var animatorKey: UInt8 = 0
    
    /// Gets or creates a constraint animator for this view
    var constraintAnimator: ConstraintAnimator {
        if let animator = objc_getAssociatedObject(self, &Self.animatorKey) as? ConstraintAnimator {
            return animator
        }
        let animator = ConstraintAnimator(view: self)
        objc_setAssociatedObject(self, &Self.animatorKey, animator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return animator
    }
    
    /// Animates layout changes
    @MainActor
    func animateLayout(
        config: ConstraintAnimationConfig = .default,
        changes: () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        changes()
        
        UIView.animate(
            withDuration: config.duration,
            delay: config.delay,
            usingSpringWithDamping: config.dampingRatio,
            initialSpringVelocity: config.initialVelocity,
            options: config.options,
            animations: { [weak self] in
                self?.superview?.layoutIfNeeded()
            },
            completion: completion
        )
    }
    
    /// Creates a transition between constraint states
    func createTransition(
        from: [NSLayoutConstraint],
        to: [NSLayoutConstraint]
    ) -> ConstraintTransition {
        ConstraintTransition(view: self, from: from, to: to)
    }
}

// MARK: - Async Animation Support

@available(iOS 13.0, *)
extension UIView {
    
    /// Async/await wrapper for constraint animations
    @MainActor
    func animateConstraintsAsync(
        config: ConstraintAnimationConfig = .default,
        changes: () -> Void
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            changes()
            
            UIView.animate(
                withDuration: config.duration,
                delay: config.delay,
                usingSpringWithDamping: config.dampingRatio,
                initialSpringVelocity: config.initialVelocity,
                options: config.options,
                animations: { [weak self] in
                    self?.superview?.layoutIfNeeded()
                },
                completion: { finished in
                    continuation.resume(returning: finished)
                }
            )
        }
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════════
// MARK: 5. DEBUG VISUALIZATION
// MARK: ═══════════════════════════════════════════════════════════════════

/// Debug visualization configuration
public struct DebugVisualizationConfig {
    public var showViewBorders: Bool
    public var showConstraintLines: Bool
    public var showAnchorPoints: Bool
    public var showLabels: Bool
    public var borderWidth: CGFloat
    public var anchorPointSize: CGFloat
    public var labelFontSize: CGFloat
    public var colorScheme: DebugColorScheme
    
    public init(
        showViewBorders: Bool = true,
        showConstraintLines: Bool = true,
        showAnchorPoints: Bool = true,
        showLabels: Bool = true,
        borderWidth: CGFloat = 1.0,
        anchorPointSize: CGFloat = 6.0,
        labelFontSize: CGFloat = 10.0,
        colorScheme: DebugColorScheme = .default
    ) {
        self.showViewBorders = showViewBorders
        self.showConstraintLines = showConstraintLines
        self.showAnchorPoints = showAnchorPoints
        self.showLabels = showLabels
        self.borderWidth = borderWidth
        self.anchorPointSize = anchorPointSize
        self.labelFontSize = labelFontSize
        self.colorScheme = colorScheme
    }
    
    nonisolated(unsafe) public static let minimal = DebugVisualizationConfig(
        showConstraintLines: false,
        showAnchorPoints: false,
        showLabels: false
    )
    
    nonisolated(unsafe) public static let detailed = DebugVisualizationConfig()
    
    nonisolated(unsafe) public static let constraintsOnly = DebugVisualizationConfig(
        showViewBorders: false,
        showAnchorPoints: false
    )
}

/// Color scheme for debug visualization
public struct DebugColorScheme {
    public var viewBorderColor: UIColor
    public var constraintLineColor: UIColor
    public var anchorPointColor: UIColor
    public var labelBackgroundColor: UIColor
    public var labelTextColor: UIColor
    public var conflictColor: UIColor
    public var ambiguousColor: UIColor
    
    public init(
        viewBorderColor: UIColor = .systemBlue,
        constraintLineColor: UIColor = .systemGreen,
        anchorPointColor: UIColor = .systemRed,
        labelBackgroundColor: UIColor = .systemYellow.withAlphaComponent(0.8),
        labelTextColor: UIColor = .black,
        conflictColor: UIColor = .systemRed,
        ambiguousColor: UIColor = .systemOrange
    ) {
        self.viewBorderColor = viewBorderColor
        self.constraintLineColor = constraintLineColor
        self.anchorPointColor = anchorPointColor
        self.labelBackgroundColor = labelBackgroundColor
        self.labelTextColor = labelTextColor
        self.conflictColor = conflictColor
        self.ambiguousColor = ambiguousColor
    }
    
    nonisolated(unsafe) public static let `default` = DebugColorScheme()
    
    nonisolated(unsafe) public static let highContrast = DebugColorScheme(
        viewBorderColor: .magenta,
        constraintLineColor: .cyan,
        anchorPointColor: .yellow,
        labelBackgroundColor: .black.withAlphaComponent(0.8),
        labelTextColor: .white
    )
    
    nonisolated(unsafe) public static let subtle = DebugColorScheme(
        viewBorderColor: .gray.withAlphaComponent(0.5),
        constraintLineColor: .gray.withAlphaComponent(0.3),
        anchorPointColor: .gray.withAlphaComponent(0.5),
        labelBackgroundColor: .white.withAlphaComponent(0.7),
        labelTextColor: .darkGray
    )
}

/// Constraint conflict information
public struct ConstraintConflict {
    public let constraints: [NSLayoutConstraint]
    public let description: String
    public let suggestedFix: String?
}

/// Debug overlay view for constraint visualization
public class ConstraintDebugOverlay: UIView {
    
    private weak var targetView: UIView?
    private var config: DebugVisualizationConfig
    private var constraintLayers: [CAShapeLayer] = []
    private var anchorLayers: [CAShapeLayer] = []
    private var labelViews: [UILabel] = []
    
    public init(targetView: UIView, config: DebugVisualizationConfig = .detailed) {
        self.targetView = targetView
        self.config = config
        super.init(frame: targetView.bounds)
        
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func refresh() {
        clearVisualization()
        guard let targetView = targetView else { return }
        
        if config.showViewBorders {
            drawViewBorders(for: targetView)
        }
        
        if config.showConstraintLines {
            drawConstraintLines(for: targetView)
        }
        
        if config.showAnchorPoints {
            drawAnchorPoints(for: targetView)
        }
        
        if config.showLabels {
            addLabels(for: targetView)
        }
    }
    
    private func clearVisualization() {
        constraintLayers.forEach { $0.removeFromSuperlayer() }
        anchorLayers.forEach { $0.removeFromSuperlayer() }
        labelViews.forEach { $0.removeFromSuperview() }
        
        constraintLayers.removeAll()
        anchorLayers.removeAll()
        labelViews.removeAll()
    }
    
    private func drawViewBorders(for view: UIView) {
        addBorder(to: view, color: config.colorScheme.viewBorderColor)
        
        for subview in view.subviews {
            drawViewBorders(for: subview)
        }
    }
    
    private func addBorder(to view: UIView, color: UIColor) {
        guard let targetView = targetView else { return }
        
        let frameInOverlay = view.convert(view.bounds, to: targetView)
        
        let borderLayer = CAShapeLayer()
        borderLayer.path = UIBezierPath(rect: frameInOverlay).cgPath
        borderLayer.strokeColor = color.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = config.borderWidth
        borderLayer.lineDashPattern = [4, 2]
        
        layer.addSublayer(borderLayer)
        constraintLayers.append(borderLayer)
    }
    
    private func drawConstraintLines(for view: UIView) {
        guard let targetView = targetView else { return }
        
        for constraint in view.constraints {
            guard let firstItem = constraint.firstItem as? UIView else { continue }
            
            let firstFrame = firstItem.convert(firstItem.bounds, to: targetView)
            var lineStart = CGPoint.zero
            var lineEnd = CGPoint.zero
            
            switch constraint.firstAttribute {
            case .top:
                lineStart = CGPoint(x: firstFrame.midX, y: firstFrame.minY)
                lineEnd = CGPoint(x: firstFrame.midX, y: firstFrame.minY - 20)
            case .bottom:
                lineStart = CGPoint(x: firstFrame.midX, y: firstFrame.maxY)
                lineEnd = CGPoint(x: firstFrame.midX, y: firstFrame.maxY + 20)
            case .leading, .left:
                lineStart = CGPoint(x: firstFrame.minX, y: firstFrame.midY)
                lineEnd = CGPoint(x: firstFrame.minX - 20, y: firstFrame.midY)
            case .trailing, .right:
                lineStart = CGPoint(x: firstFrame.maxX, y: firstFrame.midY)
                lineEnd = CGPoint(x: firstFrame.maxX + 20, y: firstFrame.midY)
            case .centerX:
                lineStart = CGPoint(x: firstFrame.midX, y: firstFrame.midY - 10)
                lineEnd = CGPoint(x: firstFrame.midX, y: firstFrame.midY + 10)
            case .centerY:
                lineStart = CGPoint(x: firstFrame.midX - 10, y: firstFrame.midY)
                lineEnd = CGPoint(x: firstFrame.midX + 10, y: firstFrame.midY)
            default:
                continue
            }
            
            let path = UIBezierPath()
            path.move(to: lineStart)
            path.addLine(to: lineEnd)
            
            let lineLayer = CAShapeLayer()
            lineLayer.path = path.cgPath
            lineLayer.strokeColor = config.colorScheme.constraintLineColor.cgColor
            lineLayer.lineWidth = 1.0
            
            layer.addSublayer(lineLayer)
            constraintLayers.append(lineLayer)
        }
        
        for subview in view.subviews {
            drawConstraintLines(for: subview)
        }
    }
    
    private func drawAnchorPoints(for view: UIView) {
        guard let targetView = targetView else { return }
        
        let frameInOverlay = view.convert(view.bounds, to: targetView)
        
        let anchorPoints = [
            CGPoint(x: frameInOverlay.minX, y: frameInOverlay.minY),     // Top-Left
            CGPoint(x: frameInOverlay.maxX, y: frameInOverlay.minY),     // Top-Right
            CGPoint(x: frameInOverlay.minX, y: frameInOverlay.maxY),     // Bottom-Left
            CGPoint(x: frameInOverlay.maxX, y: frameInOverlay.maxY),     // Bottom-Right
            CGPoint(x: frameInOverlay.midX, y: frameInOverlay.minY),     // Top-Center
            CGPoint(x: frameInOverlay.midX, y: frameInOverlay.maxY),     // Bottom-Center
            CGPoint(x: frameInOverlay.minX, y: frameInOverlay.midY),     // Left-Center
            CGPoint(x: frameInOverlay.maxX, y: frameInOverlay.midY),     // Right-Center
            CGPoint(x: frameInOverlay.midX, y: frameInOverlay.midY)      // Center
        ]
        
        for point in anchorPoints {
            let anchorLayer = CAShapeLayer()
            let rect = CGRect(
                x: point.x - config.anchorPointSize / 2,
                y: point.y - config.anchorPointSize / 2,
                width: config.anchorPointSize,
                height: config.anchorPointSize
            )
            anchorLayer.path = UIBezierPath(ovalIn: rect).cgPath
            anchorLayer.fillColor = config.colorScheme.anchorPointColor.cgColor
            
            layer.addSublayer(anchorLayer)
            anchorLayers.append(anchorLayer)
        }
        
        for subview in view.subviews {
            drawAnchorPoints(for: subview)
        }
    }
    
    private func addLabels(for view: UIView) {
        guard let targetView = targetView else { return }
        
        let frameInOverlay = view.convert(view.bounds, to: targetView)
        
        let label = UILabel()
        label.font = .systemFont(ofSize: config.labelFontSize, weight: .medium)
        label.textColor = config.colorScheme.labelTextColor
        label.backgroundColor = config.colorScheme.labelBackgroundColor
        label.textAlignment = .center
        label.layer.cornerRadius = 2
        label.clipsToBounds = true
        
        let viewName = String(describing: type(of: view))
        let sizeText = String(format: "%.0fx%.0f", frameInOverlay.width, frameInOverlay.height)
        label.text = " \(viewName) (\(sizeText)) "
        label.sizeToFit()
        
        label.frame.origin = CGPoint(
            x: frameInOverlay.minX + 2,
            y: frameInOverlay.minY + 2
        )
        
        addSubview(label)
        labelViews.append(label)
        
        for subview in view.subviews {
            addLabels(for: subview)
        }
    }
}

/// Debug manager for constraint visualization
public class AutoLayoutDebugManager {
    
    nonisolated(unsafe) public static let shared = AutoLayoutDebugManager()
    
    private var overlays: [UIView: ConstraintDebugOverlay] = [:]
    private var isEnabled: Bool = false
    private var config: DebugVisualizationConfig = .detailed
    
    private init() {}
    
    /// Enables debug visualization globally
    public func enable(config: DebugVisualizationConfig = .detailed) {
        #if DEBUG
        self.config = config
        self.isEnabled = true
        #endif
    }
    
    /// Disables debug visualization globally
    @MainActor public func disable() {
        isEnabled = false
        overlays.values.forEach { $0.removeFromSuperview() }
        overlays.removeAll()
    }
    
    /// Adds debug overlay to a specific view
    @MainActor
    public func addOverlay(to view: UIView) {
        guard isEnabled else { return }
        
        let overlay = ConstraintDebugOverlay(targetView: view, config: config)
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
        
        overlays[view] = overlay
        overlay.refresh()
    }
    
    /// Removes debug overlay from a specific view
    @MainActor public func removeOverlay(from view: UIView) {
        overlays[view]?.removeFromSuperview()
        overlays[view] = nil
    }
    
    /// Refreshes all overlays
    @MainActor public func refreshAll() {
        overlays.values.forEach { $0.refresh() }
    }
    
    /// Analyzes constraints for potential issues
    @MainActor
    public func analyzeConstraints(for view: UIView) -> [ConstraintConflict] {
        var conflicts: [ConstraintConflict] = []
        
        // Check for ambiguous layout
        if view.hasAmbiguousLayout {
            conflicts.append(ConstraintConflict(
                constraints: view.constraints,
                description: "View has ambiguous layout",
                suggestedFix: "Add missing constraints or adjust priorities"
            ))
        }
        
        // Check for conflicting constraints
        let allConstraints = gatherAllConstraints(from: view)
        let groupedConstraints = Dictionary(grouping: allConstraints) { constraint -> String in
            guard let firstItem = constraint.firstItem as? UIView else { return "unknown" }
            return "\(ObjectIdentifier(firstItem))-\(constraint.firstAttribute.rawValue)"
        }
        
        for (_, constraints) in groupedConstraints {
            let requiredConstraints = constraints.filter { $0.priority == .required }
            if requiredConstraints.count > 1 {
                let hasConflict = requiredConstraints.contains { c1 in
                    requiredConstraints.contains { c2 in
                        c1 !== c2 && c1.constant != c2.constant
                    }
                }
                
                if hasConflict {
                    conflicts.append(ConstraintConflict(
                        constraints: requiredConstraints,
                        description: "Multiple required constraints on same attribute",
                        suggestedFix: "Lower priority of one constraint or remove duplicate"
                    ))
                }
            }
        }
        
        return conflicts
    }
    
    @MainActor private func gatherAllConstraints(from view: UIView) -> [NSLayoutConstraint] {
        var constraints = view.constraints
        for subview in view.subviews {
            constraints.append(contentsOf: gatherAllConstraints(from: subview))
        }
        return constraints
    }
    
    /// Prints constraint hierarchy to console
    @MainActor
    public func printConstraintHierarchy(for view: UIView, indent: Int = 0) {
        let indentString = String(repeating: "  ", count: indent)
        let viewName = String(describing: type(of: view))
        let frame = view.frame
        
        print("\(indentString)[\(viewName)] frame: \(frame)")
        
        for constraint in view.constraints {
            let priority = constraint.priority.rawValue
            let constant = constraint.constant
            let firstAttr = constraint.firstAttribute
            print("\(indentString)  ├─ \(firstAttr) = \(constant) @ priority \(priority)")
        }
        
        for subview in view.subviews {
            printConstraintHierarchy(for: subview, indent: indent + 1)
        }
    }
}

// MARK: - UIView Debug Extensions

extension UIView {
    
    /// Toggles debug visualization for this view hierarchy
    @MainActor
    func toggleDebugVisualization(config: DebugVisualizationConfig = .detailed) {
        #if DEBUG
        if let existingOverlay = subviews.first(where: { $0 is ConstraintDebugOverlay }) {
            existingOverlay.removeFromSuperview()
        } else {
            let overlay = ConstraintDebugOverlay(targetView: self, config: config)
            overlay.frame = bounds
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(overlay)
            overlay.refresh()
        }
        #endif
    }
    
    /// Highlights constraint conflicts
    @MainActor
    func highlightConstraintConflicts() {
        #if DEBUG
        if hasAmbiguousLayout {
            layer.borderColor = UIColor.systemOrange.cgColor
            layer.borderWidth = 2
        }
        
        // Check for unsatisfiable constraints
        let conflicts = AutoLayoutDebugManager.shared.analyzeConstraints(for: self)
        if !conflicts.isEmpty {
            layer.borderColor = UIColor.systemRed.cgColor
            layer.borderWidth = 3
        }
        
        for subview in subviews {
            subview.highlightConstraintConflicts()
        }
        #endif
    }
    
    /// Prints constraint information to console
    @MainActor
    func debugPrintConstraints() {
        #if DEBUG
        AutoLayoutDebugManager.shared.printConstraintHierarchy(for: self)
        #endif
    }
    
    /// Returns a description of all constraints affecting this view
    func constraintDescription() -> String {
        var description = "Constraints for \(type(of: self)):\n"
        
        for (index, constraint) in constraints.enumerated() {
            description += "  \(index + 1). \(constraint)\n"
        }
        
        if let superview = superview {
            let superviewConstraints = superview.constraints.filter { constraint in
                (constraint.firstItem as? UIView) == self || (constraint.secondItem as? UIView) == self
            }
            
            if !superviewConstraints.isEmpty {
                description += "Superview constraints:\n"
                for (index, constraint) in superviewConstraints.enumerated() {
                    description += "  \(index + 1). \(constraint)\n"
                }
            }
        }
        
        return description
    }
}
