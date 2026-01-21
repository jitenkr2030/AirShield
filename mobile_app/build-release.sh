#!/bin/bash

# AIRSHIELD Release Build Script
# Automates the build process for Android and iOS platforms

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
PROJECT_ROOT="/workspace/airshield/mobile_app"
APP_NAME="AIRSHIELD"
BUILD_DATE=$(date +"%Y%m%d_%H%M%S")
BUILD_TYPE="${1:-release}"
PLATFORM="${2:-android}"

# Default to release build if not specified
if [ -z "$1" ]; then
    BUILD_TYPE="release"
fi

# Print banner
echo -e "${BLUE}"
echo "=========================================="
echo "  AIRSHIELD Release Build Script"
echo "=========================================="
echo -e "${NC}"

print_status "Build Type: $BUILD_TYPE"
print_status "Platform: $PLATFORM"
print_status "Build Date: $BUILD_DATE"
print_status "Project Root: $PROJECT_ROOT"

# Change to project directory
cd "$PROJECT_ROOT"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check Flutter version
flutter --version

# Function to clean previous builds
clean_build() {
    print_status "Cleaning previous builds..."
    flutter clean
    flutter pub get
    print_success "Clean completed"
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check if required files exist
    if [ "$PLATFORM" = "android" ]; then
        if [ ! -f "android/key.properties" ]; then
            print_warning "Android keystore file (android/key.properties) not found!"
            print_warning "Please set up your release keystore first."
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
        
        if [ ! -f "android/app/google-services.json" ]; then
            print_warning "Firebase configuration (android/app/google-services.json) not found!"
            print_warning "Please set up Firebase first."
        fi
    elif [ "$PLATFORM" = "ios" ]; then
        if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
            print_warning "Firebase configuration (ios/Runner/GoogleService-Info.plist) not found!"
            print_warning "Please set up Firebase first."
        fi
        
        # Check if iOS platform exists
        if [ ! -d "ios" ]; then
            print_error "iOS platform not found. Run 'flutter create --platforms ios' first."
            exit 1
        fi
    fi
    
    print_success "Dependency check completed"
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    
    # Run Flutter tests
    flutter test
    
    # Run integration tests if available
    if [ -d "integration_test" ]; then
        print_status "Running integration tests..."
        flutter drive --target=test_driver/app.dart --release
    fi
    
    print_success "Tests completed"
}

# Function to analyze code
analyze_code() {
    print_status "Analyzing code..."
    
    # Run Flutter analyze
    flutter analyze
    
    # Check for security issues
    if command -v flutter_secure &> /dev/null; then
        flutter_secure check
    fi
    
    print_success "Code analysis completed"
}

# Function to optimize TensorFlow Lite models
optimize_models() {
    print_status "Checking TensorFlow Lite model sizes..."
    
    MODEL_DIR="assets/ml_models"
    if [ -d "$MODEL_DIR" ]; then
        for model in "$MODEL_DIR"/*.tflite; do
            if [ -f "$model" ]; then
                size=$(du -h "$model" | cut -f1)
                print_status "$(basename "$model"): $size"
                
                # Check if model is too large (>50MB)
                size_bytes=$(stat -c%s "$model" 2>/dev/null || stat -f%z "$model" 2>/dev/null)
                if [ "$size_bytes" -gt 52428800 ]; then
                    print_warning "$(basename "$model") is larger than 50MB, consider optimization"
                fi
            fi
        done
    else
        print_warning "ML models directory not found"
    fi
    
    print_success "Model optimization check completed"
}

# Function to build Android
build_android() {
    print_status "Building Android $BUILD_TYPE version..."
    
    # Clean build
    if [ "$BUILD_TYPE" = "release" ]; then
        flutter clean
        flutter pub get
    fi
    
    # Build APK
    print_status "Building APK..."
    flutter build apk --$BUILD_TYPE --target lib/main.dart
    
    # Build App Bundle (recommended for Play Store)
    print_status "Building Android App Bundle..."
    flutter build appbundle --$BUILD_TYPE --target lib/main.dart
    
    # Copy builds to output directory
    OUTPUT_DIR="$PROJECT_ROOT/builds/android"
    mkdir -p "$OUTPUT_DIR"
    
    APK_FILE="build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"
    BUNDLE_FILE="build/app/outputs/bundle/release/app-release.aab"
    
    if [ -f "$APK_FILE" ]; then
        cp "$APK_FILE" "$OUTPUT_DIR/airshield-$BUILD_TYPE-$BUILD_DATE.apk"
        print_success "APK created: $OUTPUT_DIR/airshield-$BUILD_TYPE-$BUILD_DATE.apk"
    fi
    
    if [ -f "$BUNDLE_FILE" ]; then
        cp "$BUNDLE_FILE" "$OUTPUT_DIR/airshield-$BUILD_TYPE-$BUILD_DATE.aab"
        print_success "App Bundle created: $OUTPUT_DIR/airshield-$BUILD_TYPE-$BUILD_DATE.aab"
    fi
    
    # Print build information
    print_status "Build Information:"
    echo "  - APK Size: $(du -h "$OUTPUT_DIR/airshield-$BUILD_TYPE-$BUILD_DATE.apk" 2>/dev/null | cut -f1 || echo "N/A")"
    echo "  - Bundle Size: $(du -h "$OUTPUT_DIR/airshield-$BUILD_TYPE-$BUILD_DATE.aab" 2>/dev/null | cut -f1 || echo "N/A")"
    
    print_success "Android build completed"
}

# Function to build iOS
build_ios() {
    print_status "Building iOS $BUILD_TYPE version..."
    
    # Check if iOS platform is available
    if [ ! -d "ios" ]; then
        print_error "iOS platform not found. Run 'flutter create --platforms ios' first."
        exit 1
    fi
    
    # Clean build
    if [ "$BUILD_TYPE" = "release" ]; then
        flutter clean
        flutter pub get
        cd ios
        pod install
        cd ..
    fi
    
    # Build iOS
    print_status "Building iOS archive..."
    flutter build ios --$BUILD_TYPE --target lib/main.dart
    
    # Build for distribution
    print_status "Building for App Store distribution..."
    cd ios
    xcodebuild -workspace Runner.xcworkspace \
               -scheme Runner \
               -configuration Release \
               -destination generic/platform=iOS \
               -archivePath "build/airshield-$BUILD_TYPE-$BUILD_DATE.xcarchive" \
               archive
    
    cd ..
    
    # Export IPA for TestFlight or Ad Hoc distribution
    print_status "Exporting IPA..."
    cd ios
    xcodebuild -exportArchive \
               -archivePath "build/airshield-$BUILD_TYPE-$BUILD_DATE.xcarchive" \
               -exportPath "../builds/ios" \
               -exportOptionsPlist ExportOptions.plist
    
    cd ..
    
    # Copy builds to output directory
    OUTPUT_DIR="$PROJECT_ROOT/builds/ios"
    mkdir -p "$OUTPUT_DIR"
    
    IPA_FILE="$OUTPUT_DIR/airshield-$BUILD_TYPE-$BUILD_DATE.ipa"
    XCARCHIVE_FILE="$PROJECT_ROOT/ios/build/airshield-$BUILD_TYPE-$BUILD_DATE.xcarchive"
    
    if [ -f "$IPA_FILE" ]; then
        print_success "IPA created: $IPA_FILE"
    fi
    
    if [ -d "$XCARCHIVE_FILE" ]; then
        print_success "Archive created: $XCARCHIVE_FILE"
    fi
    
    # Print build information
    print_status "Build Information:"
    echo "  - IPA Size: $(du -h "$IPA_FILE" 2>/dev/null | cut -f1 || echo "N/A")"
    
    print_success "iOS build completed"
}

# Function to run security scan
security_scan() {
    print_status "Running security scan..."
    
    # Check for hardcoded secrets
    if command -v git &> /dev/null; then
        print_status "Checking for hardcoded secrets..."
        # This would require additional tools like truffleHog or git-secrets
        print_status "Consider running git-secrets or similar tools for security scanning"
    fi
    
    # Check app permissions
    if [ "$PLATFORM" = "android" ]; then
        print_status "Android permissions analysis..."
        if command -v aapt &> /dev/null; then
            aapt dump permissions build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk
        else
            print_warning "aapt not found, skipping permission analysis"
        fi
    fi
    
    print_success "Security scan completed"
}

# Function to generate build report
generate_report() {
    print_status "Generating build report..."
    
    REPORT_FILE="$PROJECT_ROOT/builds/build-report-$BUILD_TYPE-$BUILD_DATE.md"
    mkdir -p "$(dirname "$REPORT_FILE")"
    
    cat > "$REPORT_FILE" << EOF
# AIRSHIELD Build Report

**Build Date:** $(date)
**Build Type:** $BUILD_TYPE
**Platform:** $PLATFORM
**Flutter Version:** $(flutter --version)

## Build Information
- **Build Date:** $BUILD_DATE
- **Project:** $APP_NAME
- **Platform:** $PLATFORM
- **Configuration:** $BUILD_TYPE

## Generated Files
EOF

    if [ "$PLATFORM" = "android" ]; then
        echo "- APK: build/android/airshield-$BUILD_TYPE-$BUILD_DATE.apk" >> "$REPORT_FILE"
        echo "- App Bundle: build/android/airshield-$BUILD_TYPE-$BUILD_DATE.aab" >> "$REPORT_FILE"
    elif [ "$PLATFORM" = "ios" ]; then
        echo "- IPA: build/ios/airshield-$BUILD_TYPE-$BUILD_DATE.ipa" >> "$REPORT_FILE"
        echo "- Archive: ios/build/airshield-$BUILD_TYPE-$BUILD_DATE.xcarchive" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

## Testing Status
- [ ] Unit Tests
- [ ] Integration Tests  
- [ ] Manual Testing

## Code Analysis
- [ ] Flutter Analyze Passed
- [ ] Security Scan Completed
- [ ] Performance Analysis

## Checklist
- [ ] Build artifacts generated successfully
- [ ] Firebase configuration verified
- [ ] App signing configured (release builds)
- [ ] Dependencies verified
- [ ] Permissions reviewed
- [ ] Ready for store submission

## Next Steps
1. Test build on device/simulator
2. Upload to respective app store
3. Monitor crash reports and analytics
4. Prepare for release

---
*Generated by AIRSHIELD Build Script*
EOF

    print_success "Build report generated: $REPORT_FILE"
}

# Main execution
main() {
    print_status "Starting build process..."
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --test)
                RUN_TESTS=true
                shift
                ;;
            --analyze)
                RUN_ANALYZE=true
                shift
                ;;
            --security)
                RUN_SECURITY=true
                shift
                ;;
            --report)
                GENERATE_REPORT=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [BUILD_TYPE] [PLATFORM] [OPTIONS]"
                echo "  BUILD_TYPE: debug|release (default: release)"
                echo "  PLATFORM: android|ios|both (default: android)"
                echo "  OPTIONS:"
                echo "    --clean: Clean build before building"
                echo "    --test: Run tests"
                echo "    --analyze: Run code analysis"
                echo "    --security: Run security scan"
                echo "    --report: Generate build report"
                echo "    -h|--help: Show this help"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Initialize flags
    CLEAN_BUILD=${CLEAN_BUILD:-false}
    RUN_TESTS=${RUN_TESTS:-false}
    RUN_ANALYZE=${RUN_ANALYZE:-false}
    RUN_SECURITY=${RUN_SECURITY:-false}
    GENERATE_REPORT=${GENERATE_REPORT:-false}
    
    # Run build process
    clean_build
    check_dependencies
    
    if [ "$RUN_TESTS" = true ]; then
        run_tests
    fi
    
    if [ "$RUN_ANALYZE" = true ]; then
        analyze_code
    fi
    
    optimize_models
    
    if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "both" ]; then
        build_android
    fi
    
    if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "both" ]; then
        build_ios
    fi
    
    if [ "$RUN_SECURITY" = true ]; then
        security_scan
    fi
    
    if [ "$GENERATE_REPORT" = true ]; then
        generate_report
    fi
    
    print_success "Build process completed successfully!"
    print_status "Check the 'builds' directory for generated artifacts"
}

# Error handling
trap 'print_error "Build failed at line $LINENO"' ERR

# Run main function
main "$@"