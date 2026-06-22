# BuildTrack App - Run Script
# Increases Dart VM heap size to prevent OOM crashes on large widget files

Write-Host "Starting BuildTrack App with increased Dart VM heap..." -ForegroundColor Cyan

# REQUIRED: Increase heap for the Flutter TOOLCHAIN process itself.
# Without this, every flutter command crashes at startup with:
#   allocation.cc:22: error: Out of memory
# DART_VM_OPTIONS only covers the running app — FLUTTER_TOOL_ARGS covers the CLI.
$env:FLUTTER_TOOL_ARGS = '--old-gen-heap-size=4096'
$env:DART_VM_OPTIONS   = '--old-gen-heap-size=4096'

# Run flutter
flutter run $args
