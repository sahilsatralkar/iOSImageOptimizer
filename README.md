# iOS Image Optimizer

A comprehensive command-line tool that analyzes your iOS projects for image optimization opportunities following **Apple's official Human Interface Guidelines**. Identify unused images, validate Apple compliance, and get actionable recommendations to improve your app's performance and App Store approval chances.

## 🎯 What It Does

This tool provides **comprehensive image analysis** for iOS projects:

### ✅ Core Features
- **Unused Image Detection** - Find images that exist but are never referenced in code
- **Apple Compliance Validation** - Validate images against Apple's official guidelines
- **PNG Interlacing Analysis** - Detect performance-impacting interlaced PNGs
- **Color Profile Validation** - Ensure consistent colors across devices
- **Asset Catalog Organization** - Validate proper scale variants (@1x, @2x, @3x)
- **Design Quality Assessment** - Check touch targets and memory optimization
- **Compliance Scoring** - Get a 0-100 Apple compliance score
- **Prioritized Recommendations** - Actionable items ranked by importance

### 📊 Sample Output

```
🔍 Analyzing iOS project at: /Users/yourname/Documents/MyApp

📊 Analysis Complete
==================================================

🎯 Apple Compliance Score: 73/100

📈 Summary:
  Total images: 45
  Total image size: 2.3 MB
  Unused images: 8
  Potential savings: 890 KB

🍎 Apple Guidelines Compliance:
  PNG interlacing issues: 2
  Color profile issues: 5
  Asset catalog issues: 12
  Design quality issues: 3

💡 Prioritized Action Items:
  1. Remove 8 unused images to save 890 KB
  2. Fix 2 critical PNG interlacing issues
  3. Add color profiles to 5 images
  4. Add missing scale variants for 7 images
  5. Address 2 design quality issues
```

## 🍎 Apple Guidelines Reference

This tool implements validation based on **Apple's official Human Interface Guidelines**:

- **Primary Reference**: [Apple Human Interface Guidelines - Images](https://developer.apple.com/design/human-interface-guidelines/images)
- **Key Requirements**: 
  - De-interlaced PNG files for better performance
  - Color profiles for consistent appearance across devices
  - Proper scale factors (@1x, @2x, @3x) for different device densities
  - Appropriate formats (PNG for UI, JPEG for photos, PDF/SVG for icons)
  - Design at lowest resolution and scale up for clean alignment

## 🚀 Complete Setup Guide

### Step 1: System Requirements

Open **Terminal** and verify Swift is installed:

```bash
swift --version
```

You need Swift 5.9+ or Xcode 14+. If not installed:
```bash
xcode-select --install
```

### Step 2: Download and Build

```bash
# Navigate to your Documents folder
cd ~/Documents

# Download the tool
git clone https://github.com/sahilsatralkar/iOSImageOptimizerTool.git

# Go into the tool directory
cd iOSImageOptimizerTool/iOSImageOptimizer

# Build the tool (takes 2-5 minutes first time)
swift build
```

### Step 3: Analyze Your iOS Project

```bash
# Basic analysis
swift run iOSImageOptimizer /path/to/your/ios/project

# Detailed analysis with verbose output
swift run iOSImageOptimizer /path/to/your/ios/project --verbose

# JSON output for integration
swift run iOSImageOptimizer /path/to/your/ios/project --json
```

**Real example:**
```bash
swift run iOSImageOptimizer /Users/yourname/Documents/MyiOSApp
```

## 📋 Understanding the Analysis

### 🎯 Apple Compliance Score (0-100)
- **80-100**: Excellent compliance, ready for App Store
- **60-79**: Good, minor issues to address
- **40-59**: Fair, several compliance issues
- **0-39**: Poor, significant issues requiring attention

### 🔍 Validation Categories

#### **PNG Interlacing Issues**
- **What**: Detects interlaced PNGs that impact performance
- **Why**: Apple recommends de-interlaced PNGs for better iOS performance
- **Action**: Convert to de-interlaced format using image editing tools

#### **Color Profile Issues**
- **What**: Images missing or with incompatible color profiles
- **Why**: Ensures consistent colors across different iOS devices
- **Action**: Add sRGB color profile (recommended for most iOS images)

#### **Asset Catalog Issues**
- **What**: Missing scale variants, orphaned scales, organization problems
- **Why**: iOS requires proper @1x, @2x, @3x variants for optimal display
- **Action**: Add missing scale variants or organize in Asset Catalogs

#### **Design Quality Issues**
- **What**: Images too small for touch targets or memory-intensive
- **Why**: Affects usability and performance on iOS devices
- **Action**: Resize touch targets to 44×44pt minimum, optimize large images

#### **Unused Images**
- **What**: Images present in project but never referenced in code
- **Why**: Reduces app bundle size and improves download/install times
- **Action**: Review and remove confirmed unused images

## 🛠️ Acting on Recommendations

### Priority 1: Remove Unused Images
```bash
# Before deleting, verify the image is truly unused
grep -r "image_name" /path/to/your/project
# If no results, safe to delete
```

### Priority 2: Fix PNG Interlacing
- Use tools like ImageOptim, Photoshop, or online converters
- Ensure "interlaced" option is disabled when saving PNGs

### Priority 3: Add Color Profiles
- In Photoshop: Edit → Convert to Profile → sRGB
- In Preview: Tools → Assign Profile → sRGB IEC61966-2.1

### Priority 4: Fix Asset Catalog Organization
- Create missing @1x, @2x, @3x variants
- Move standalone images to Asset Catalogs
- Ensure proper naming conventions

### Priority 5: Address Design Quality
- Resize touch targets to minimum 44×44 points
- Optimize large images or implement progressive loading
- Use appropriate formats for content type

## 🔧 Troubleshooting

### Build Issues
```bash
# Clean and rebuild
swift package clean
swift build

# Update dependencies
swift package update
```

### Path Issues
```bash
# Find your project path
open /path/to/your/project  # Should open in Finder
pwd  # Shows current directory
```

### Permission Issues
- Ensure you have read access to the project directory
- Don't point to system directories

## 💡 Best Practices

### Regular Analysis
- Run before each App Store submission
- Include in CI/CD pipeline for continuous monitoring
- Check after adding new images or design updates

### Image Optimization Workflow
1. **Design** images at @1x resolution with whole-number dimensions
2. **Scale up** to create @2x and @3x variants
3. **Optimize** file sizes without losing quality
4. **Validate** with this tool before submission
5. **Test** on actual devices to verify appearance

### Apple Compliance Tips
- Use PNG for UI elements and icons
- Use JPEG for photographs
- Use PDF/SVG for scalable icons
- Always include color profiles
- Organize images in Asset Catalogs
- Follow Apple's dimension guidelines

## 📱 iOS Image Requirements

### Scale Factors by Platform
- **iOS**: @2x and @3x required
- **iPadOS**: @2x required
- **macOS**: @1x and @2x required
- **watchOS**: @2x required

### Recommended Formats
- **UI Elements**: De-interlaced PNG with sRGB color profile
- **Photographs**: JPEG with embedded color profile
- **Icons**: PDF or SVG for scalability
- **Low-color graphics**: 8-bit PNG palette

## 🆘 Getting Help

### Common Error Solutions

**"No images found"**
- Verify project path is correct
- Ensure project contains .png, .jpg, .pdf, or .svg files

**"Low compliance score"**
- Review each category in the detailed output
- Focus on Priority 1 and 2 items first
- Use Apple's official guidelines as reference

**"Build failed"**
- Update Xcode and command line tools
- Check Swift version compatibility
- Clean and rebuild the project

### Additional Resources
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [iOS App Development Best Practices](https://developer.apple.com/documentation/xcode)
- [Image Optimization Tools](https://imageoptim.com/mac)

## 🚨 Important Notes

- **Analysis Only**: This tool only analyzes - it never automatically modifies your project
- **Backup First**: Always backup your project before making changes
- **Review Results**: Some "unused" images might be loaded dynamically in code
- **Test Thoroughly**: Verify your app works correctly after making changes
- **Apple Guidelines**: This tool follows Apple's official recommendations, not arbitrary limits

## 📁 Supported Project Structure

The tool works with standard iOS project structures:

```
MyiOSApp/
├── MyiOSApp.xcodeproj
├── MyiOSApp/
│   ├── ViewController.swift
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   └── LaunchImage.imageset/
│   ├── Images/
│   │   ├── logo.png
│   │   ├── logo@2x.png
│   │   └── logo@3x.png
│   └── Storyboards/
│       └── Main.storyboard
├── Pods/ (if using CocoaPods)
└── README.md
```

Point the tool to the root project folder containing the `.xcodeproj` file.

---

**Transform your iOS app's image optimization with Apple-compliant analysis!** 🚀📱

*Following Apple's Human Interface Guidelines ensures better performance, smaller bundle sizes, and improved App Store approval chances.*