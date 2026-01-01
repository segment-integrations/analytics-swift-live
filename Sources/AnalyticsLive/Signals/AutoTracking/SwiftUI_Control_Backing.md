# SwiftUI Control Backing Analysis

**Date:** December 30, 2025  
**iOS Version Tested:** iOS 26
**Method:** Runtime view hierarchy inspection via UIKit traversal

## Summary

Most SwiftUI controls are backed by UIKit views, meaning we can use swizzling for interaction capture. Only a few controls are pure SwiftUI and require wrapper types.

## UIKit-Backed Controls (Swizzlable)

| SwiftUI Control | UIKit Backing View | Adaptor Class |
|-----------------|-------------------|---------------|
| `TextField` | `UITextField` | `PlatformTextFieldAdaptor` |
| `SecureField` | `UITextField` | `PlatformTextFieldAdaptor` |
| `TextEditor` | `TextEditorTextView` | `UIKitTextViewAdaptor` |
| `Toggle` | `UISwitch` | `Switch` |
| `Slider` | `UISlider` | `SystemSlider` |
| `Stepper` | `UIStepper` | `UIKitStepper` |
| `Picker` (segmented style) | `UISegmentedControl` | `SystemSegmentedControl` |
| `Picker` (menu style) | `UIKitIconPreferringButton` | `UIKitButtonAdaptor` |
| `DatePicker` | `UIDatePicker` | `UIKitDatePickerRepresentable` |
| `ColorPicker` | `UIColorWell` | `BridgedColorPicker` |

## Pure SwiftUI Controls (Need Wrappers)

| SwiftUI Control | Notes |
|-----------------|-------|
| `Button` | No UIKit backing - just `CellHostingView` |
| `Link` | No UIKit backing - just `CellHostingView` |
| `Menu` | Uses `HostingUIButton` - hybrid, needs investigation |

## Signal Source Detection

SwiftUI-wrapped UIKit controls can be distinguished from pure UIKit by checking for hosting view ancestors:

- `UIKitPlatformViewHost`
- `PlatformViewRepresentableAdaptor`  
- `HostingView` / `CellHostingView`

If any of these exist in the view's ancestor chain → `.autoSwiftUI`  
If none exist → `.autoUIKit`

```swift
func detectSignalSource(for view: UIView) -> SignalSource {
    var current: UIView? = view
    while let v = current {
        let typeName = String(describing: type(of: v))
        if typeName.contains("UIKitPlatformViewHost") || 
           typeName.contains("PlatformViewRepresentableAdaptor") ||
           typeName.contains("HostingView") {
            return .autoSwiftUI
        }
        current = v.superview
    }
    return .autoUIKit
}
```

## Implications

1. **Swizzling is the primary approach** - Most controls can be captured via UIKit swizzling
2. **Wrappers only needed for Button/Link** - Drastically reduces wrapper maintenance burden
3. **Universal swizzlers** - Same swizzler code works for both UIKit and SwiftUI apps
4. **Automatic source detection** - No need for separate code paths per framework

## Caveats

- This analysis was performed on iOS 18; Apple may change backing implementations in future versions
- Some controls may have different backing depending on style (e.g., Picker menu vs segmented)
- Private API class names (`_UIKitPlatformViewHost`, etc.) may change between iOS versions
