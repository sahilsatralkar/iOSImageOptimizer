# iOS Image Optimizer

A command-line tool to find unused and oversized images in your iOS projects. Helps you identify images that are taking up unnecessary space in your app bundle.

## 🎯 What It Does

This tool scans your iOS project and tells you:

- **Which images are unused** - Images that exist in your project but are never referenced in code
- **Which images are too large** - Images that exceed recommended size limits
- **How much space you could save** - Potential reduction in app bundle size

## 🚀 Complete Setup Guide (For Beginners)

### Step 1: Check Your System Requirements

First, let's make sure you have everything needed. Open **Terminal** (press `Cmd + Space`, type "Terminal", press Enter) and run:

```bash
swift --version
```

You should see something like:
```
Apple Swift version 6.1.2 (or 5.9+)
```

If you don't have Swift or it's too old:
1. Update Xcode from the Mac App Store
2. Or install Xcode command line tools: `xcode-select --install`

### Step 2: Download and Build the Tool

**Copy and paste these commands one by one into Terminal:**

```bash
# 1. Navigate to your Documents folder
cd ~/Documents

# 2. Download the tool
git clone https://github.com/sahilsatralkar/iOSImageOptimizer.git

# 3. Go into the tool directory
cd iOSImageOptimizer/iOSImageOptimizer

# 4. Build the tool (this takes 2-5 minutes first time)
swift build
```

Wait for the build to complete. You should see something like:
```
Building for debugging...
Build complete!
```

### Step 3: Run the Tool on Your iOS Project

**Replace `/path/to/your/ios/project` with your actual project path:**

```bash
swift run iOSImageOptimizer /path/to/your/ios/project
```

**Real example:**
```bash
swift run iOSImageOptimizer /Users/yourname/Documents/MyiOSApp
```

**For detailed output, add `--verbose`:**
```bash
swift run iOSImageOptimizer /path/to/your/ios/project --verbose
```

## 📋 Sample Output

When you run the tool, you'll see something like this:

```
🔍 Analyzing iOS project at: /Users/yourname/Documents/MyApp

📊 Analysis Complete
==================================================

📈 Summary:
  Total images: 25
  Unused images: 3
  Oversized images: 2
  Total image size: 2.1 MB
  Potential savings: 890 KB

🗑️  Unused Images:
  ❌ old_logo (45 KB)
     Path: /Users/yourname/Documents/MyApp/Assets.xcassets/old_logo.imageset/old_logo.png
  ❌ test_image (123 KB)
     Path: /Users/yourname/Documents/MyApp/Images/test_image@2x.png

⚠️  Oversized Images:
  ⚡ splash_screen
     Image exceeds 3x size limit (1.2 MB > 400 KB)
     Potential saving: 800 KB
```

## 🛠️ What to Do With the Results

### For Unused Images:
1. **Review each unused image** - Some might be loaded dynamically
2. **Check if they're really unused** - Search your code for the image name
3. **Delete confirmed unused images** - You can manually delete them to save space

### For Oversized Images:
1. **Optimize large images** - Use image compression tools
2. **Consider using smaller versions** - Especially for @3x images
3. **Use appropriate formats** - PNG for simple graphics, JPEG for photos

## 🔧 Common Issues and Solutions

### "Command not found" Error
**Problem:** Terminal says `swift: command not found`
**Solution:** 
```bash
xcode-select --install
```
Then restart Terminal and try again.

### "No such file or directory" Error
**Problem:** Can't find your iOS project
**Solution:** 
1. Find your project in Finder
2. Right-click the folder → "Copy Pathname"
3. Paste that path in the command

### Build Takes Forever
**Problem:** `swift build` runs for more than 10 minutes
**Solution:**
1. Press `Ctrl + C` to cancel
2. Run: `swift package clean`
3. Try: `swift build` again

### Permission Denied
**Problem:** Can't access certain folders
**Solution:** Make sure you're pointing to your project folder, not system folders.

## 🎓 Understanding the Results

### Size Limits Used:
- **1x images**: Should be under 100 KB
- **2x images**: Should be under 200 KB  
- **3x images**: Should be under 400 KB

### What Gets Scanned:
- **Image files**: `.png`, `.jpg`, `.jpeg`, `.pdf`, `.svg`
- **Asset catalogs**: Images in `.xcassets` folders
- **Code files**: `.swift`, `.m`, `.mm` files for image references
- **Interface files**: `.storyboard`, `.xib` files

### What It Looks For:
- `UIImage(named: "image_name")`
- `Image("image_name")` (SwiftUI)
- `image="image_name"` (Storyboards)
- And many other patterns

## 💡 Pro Tips

1. **Run regularly** - Check for unused images before each release
2. **Review before deleting** - Some images might be used dynamically
3. **Optimize don't just delete** - Large images can often be compressed
4. **Use appropriate scales** - You might not need @3x for all images

## 🚨 Important Notes

- **This tool only analyzes** - It doesn't automatically delete anything
- **Review all results** - Some "unused" images might be loaded dynamically
- **Backup first** - Always backup your project before making changes
- **Test after changes** - Make sure your app still works after removing images

## 🆘 Getting Help

If you run into problems:

1. **Check the error message** - Often tells you exactly what's wrong
2. **Try the troubleshooting section above**
3. **Make sure you're in the right directory** - Run `pwd` to see where you are
4. **Verify your project path** - Use `ls /path/to/your/project` to check it exists

## 📁 Example File Structure

Your iOS project should look something like this:
```
MyiOSApp/
├── MyiOSApp.xcodeproj
├── MyiOSApp/
│   ├── ViewController.swift
│   ├── Assets.xcassets/
│   │   └── AppIcon.appiconset/
│   └── Images/
│       ├── logo.png
│       └── background@2x.png
└── README.md
```

Point the tool to the root folder (`MyiOSApp/`), not the `.xcodeproj` file.

---

**That's it!** You now have a powerful tool to optimize your iOS app's image usage. Happy optimizing! 🚀