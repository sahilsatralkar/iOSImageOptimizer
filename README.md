# iOS Image Optimizer

A powerful command-line tool to analyze and optimize images in iOS projects. Find unused images, detect oversized assets, and reclaim valuable app bundle space.

## 🎯 What It Does

iOS Image Optimizer helps you:

- **Find unused images** - Identifies images that are never referenced in your code
- **Detect oversized images** - Finds images that exceed recommended size limits for their scale
- **Analyze asset catalogs** - Scans both standalone images and `.xcassets` bundles  
- **Generate detailed reports** - Provides actionable insights with potential space savings
- **Export data** - Output results as JSON for further processing

## 🚀 Quick Start

### Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- Xcode command line tools

### Installation

#### Option 1: Build from Source
```bash
git clone https://github.com/sahilsatralkar/iOSImageOptimizer.git
cd iOSImageOptimizer/iOSImageOptimizer
swift build -c release
```

#### Option 2: Direct Usage
```bash
# Navigate to your iOS project directory
cd /path/to/your/ios/project

# Run the analyzer
/path/to/iOSImageOptimizer/.build/release/ios-image-optimizer .
```

### Basic Usage

```bash
# Analyze current directory
ios-image-optimizer .

# Analyze specific project
ios-image-optimizer /path/to/your/ios/project

# Verbose output with detailed scanning info
ios-image-optimizer /path/to/your/ios/project --verbose

# Export results as JSON
ios-image-optimizer /path/to/your/ios/project --json > report.json
```

## 📊 Sample Output

```
🔍 Analyzing iOS project at: /Users/developer/MyApp

📊 Analysis Complete
==================================================

📈 Summary:
  Total images: 342
  Unused images: 47
  Oversized images: 23
  Total image size: 45.3 MB
  Potential savings: 12.8 MB

🗑️  Unused Images:
  ❌ old_logo (234 KB)
  ❌ test_background (1.2 MB)
  ❌ unused_icon (45 KB)
  ... and 44 more

⚠️  Oversized Images:
  ⚡ splash_screen
     Image exceeds 3x size limit (2.1 MB > 400 KB)
     Potential saving: 1.7 MB
  ⚡ hero_background
     Image exceeds 2x size limit (890 KB > 200 KB)
     Potential saving: 690 KB
  ... and 21 more

✨ Recommendations:
  → Run 'ios-image-optimizer clean' to remove unused images
  → Run 'ios-image-optimizer optimize' to resize oversized images
```

## 🔍 What Gets Analyzed

### Image Detection
- **Standalone images**: `.png`, `.jpg`, `.jpeg`, `.pdf`, `.svg` files
- **Asset catalogs**: Images within `.xcassets` bundles
- **Scale variants**: Automatic detection of `@2x`, `@3x` suffixes

### Usage Detection
The tool scans for image references in:

- **Swift files** (`.swift`)
  - `UIImage(named: "image_name")`
  - `Image("image_name")` (SwiftUI)
  - `UIImage(systemName: "sf_symbol")`
  - `#imageLiteral(resourceName: "image_name")`

- **Objective-C files** (`.m`, `.mm`)
  - `[UIImage imageNamed:@"image_name"]`
  - `imageWithContentsOfFile:@"image_name"`

- **Interface Builder files** (`.storyboard`, `.xib`)
  - `image="image_name"`
  - `imageName="image_name"`
  - `<image name="image_name">`

### Size Thresholds

The tool uses these recommended size limits:

- **1x images**: 100 KB
- **2x images**: 200 KB  
- **3x images**: 400 KB
- **General limit**: 500 KB

## 📱 Integrating into Your iOS Development Workflow

### 1. Pre-commit Hook

Add image optimization checks to your git pre-commit hook:

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "🔍 Checking for image optimization opportunities..."
ios-image-optimizer . --json > /tmp/image-report.json

# Parse results and fail if too much waste detected
WASTED_SIZE=$(cat /tmp/image-report.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('wastedSize', 0))
")

if [ "$WASTED_SIZE" -gt 5242880 ]; then  # 5MB threshold
    echo "❌ Too much wasted space in images: $(( WASTED_SIZE / 1024 / 1024 ))MB"
    echo "Please run 'ios-image-optimizer .' to see optimization opportunities"
    exit 1
fi

echo "✅ Image optimization check passed"
```

### 2. CI/CD Integration

Add to your GitHub Actions workflow:

```yaml
name: iOS Image Optimization Check

on: [push, pull_request]

jobs:
  image-optimization:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Swift
      uses: swift-actions/setup-swift@v1
      
    - name: Build iOS Image Optimizer
      run: |
        git clone https://github.com/sahilsatralkar/iOSImageOptimizer.git
        cd iOSImageOptimizer/iOSImageOptimizer
        swift build -c release
        
    - name: Analyze Images
      run: |
        ./iOSImageOptimizer/iOSImageOptimizer/.build/release/ios-image-optimizer . --json > image-report.json
        
    - name: Check Results
      run: |
        python3 -c "
        import json
        with open('image-report.json') as f:
            data = json.load(f)
        wasted_mb = data['wastedSize'] / 1024 / 1024
        print(f'Potential savings: {wasted_mb:.1f}MB')
        if wasted_mb > 5:
            exit(1)
        "
```

### 3. Xcode Build Phase

Add a "Run Script" build phase in Xcode:

```bash
# Build Phase: Image Optimization Check
if command -v ios-image-optimizer &> /dev/null; then
    echo "🔍 Running image optimization analysis..."
    ios-image-optimizer "${SRCROOT}" --verbose
else
    echo "⚠️ ios-image-optimizer not found. Install from: https://github.com/sahilsatralkar/iOSImageOptimizer"
fi
```

### 4. Development Scripts

Create a script for regular optimization checks:

```bash
#!/bin/bash
# scripts/check-images.sh

echo "🔍 iOS Image Optimization Report"
echo "================================"

# Run analysis
ios-image-optimizer . --json > /tmp/ios-image-report.json

# Extract key metrics
TOTAL_IMAGES=$(cat /tmp/ios-image-report.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('totalImages', 0))
")

UNUSED_COUNT=$(cat /tmp/ios-image-report.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(len(data.get('unusedImages', [])))
")

OVERSIZED_COUNT=$(cat /tmp/ios-image-report.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(len(data.get('oversizedImages', [])))
")

WASTED_MB=$(cat /tmp/ios-image-report.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(round(data.get('wastedSize', 0) / 1024 / 1024, 1))
")

echo "📊 Summary:"
echo "  Total images: $TOTAL_IMAGES"
echo "  Unused images: $UNUSED_COUNT"
echo "  Oversized images: $OVERSIZED_COUNT"
echo "  Potential savings: ${WASTED_MB}MB"

if [ "$WASTED_MB" != "0.0" ]; then
    echo ""
    echo "💡 Run 'ios-image-optimizer .' for detailed analysis"
fi
```

## 🛠 Advanced Usage

### Command Line Options

```bash
ios-image-optimizer [OPTIONS] <PROJECT_PATH>

ARGUMENTS:
  <PROJECT_PATH>    Path to iOS project directory

OPTIONS:
  -v, --verbose     Show detailed output during scanning
  -j, --json        Export findings to JSON format
  -h, --help        Show help information
```

### JSON Output Format

```json
{
  "totalImages": 342,
  "unusedImages": [
    {
      "name": "old_logo",
      "path": "/path/to/old_logo.png",
      "size": 239616,
      "type": "png",
      "scale": 1
    }
  ],
  "oversizedImages": [
    {
      "asset": {
        "name": "splash_screen",
        "path": "/path/to/splash_screen@3x.png",
        "size": 2097152,
        "type": "assetCatalog-3x",
        "scale": 3
      },
      "reason": "Image exceeds 3x size limit (2.0 MB > 400 KB)",
      "potentialSaving": 1697152
    }
  ],
  "totalSize": 47513600,
  "wastedSize": 13421772
}
```

## 🔧 Troubleshooting

### Common Issues

**Build fails with dependency errors:**
```bash
# Clean and rebuild
swift package clean
swift build
```

**Tool doesn't find images in asset catalogs:**
- Ensure your `.xcassets` folders are properly structured
- Check that imagesets contain `Contents.json` files

**False positives for unused images:**
- Some images might be loaded dynamically via string interpolation
- Images used in other bundles or frameworks might not be detected
- Consider manual review of flagged images

### Performance Tips

- Use `--verbose` flag to see scanning progress on large projects
- The tool processes files recursively - scanning large projects may take time
- Consider running on specific subdirectories for faster analysis

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Swift Argument Parser](https://github.com/apple/swift-argument-parser)
- File operations powered by [Files](https://github.com/JohnSundell/Files)
- Colored output using [Rainbow](https://github.com/onevcat/Rainbow)

---

**Happy optimizing! 🚀**

*Reclaim your app bundle space and improve user download experience.*