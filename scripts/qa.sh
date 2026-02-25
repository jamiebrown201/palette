#!/bin/bash
# Unified QA tool - seed data, navigate to any screen, take screenshot.
#
# Usage:
#   ./scripts/qa.sh <screen>              Navigate + screenshot
#   ./scripts/qa.sh <screen> --full       Full-page scrolling screenshot
#   ./scripts/qa.sh <screen> --seed       Seed DB, restart app, navigate + screenshot
#   ./scripts/qa.sh --seed-only           Just seed the DB and restart the app
#   ./scripts/qa.sh --list                Show available screens
#
# Examples:
#   ./scripts/qa.sh red-thread
#   ./scripts/qa.sh room-detail --full
#   ./scripts/qa.sh room-detail --seed --full
#   ./scripts/qa.sh home

set -e

DEVICE="${QA_DEVICE:-emulator-5554}"
ADB="adb -s $DEVICE"
PKG="com.paletteapp.palette"
DB="app_flutter/palette.sqlite"
SCREENSHOT_DIR="screenshots"
WAIT_SECS=3
NOW=$(date +%s)
SCREEN_HEIGHT=2400
SCROLL_AMOUNT=1600  # Swipe distance in px
OVERLAP=600         # Overlap to crop from subsequent frames
MAX_SCROLLS=10

# --- Route mapping ---
get_route() {
  case "$1" in
    home)           echo "/home" ;;
    rooms)          echo "/rooms" ;;
    room-detail)    echo "/rooms/qa-room-living" ;;
    explore)        echo "/explore" ;;
    wheel)          echo "/explore/wheel" ;;
    white-finder)   echo "/explore/white-finder" ;;
    paint-library)  echo "/explore/paint-library" ;;
    profile)        echo "/profile" ;;
    palette)        echo "/palette" ;;
    red-thread)     echo "/red-thread" ;;
    paywall)        echo "/paywall" ;;
    capture)        echo "/capture" ;;
    onboarding)     echo "/onboarding" ;;
    dev)            echo "/dev" ;;
    *)              echo "" ;;
  esac
}

# --- Seed DB via sqlite3 ---
seed_db() {
  echo "Seeding demo data..."
  $ADB shell "run-as $PKG sqlite3 $DB \"
    INSERT OR REPLACE INTO user_profiles VALUES('default', 1, 'plus', 0, 'qa-demo-dna-001', $NOW, $NOW);

    INSERT OR IGNORE INTO colour_dna_results VALUES(
      'qa-demo-dna-001', 'warmNeutrals', 'earthTones',
      '[\"#C4A882\",\"#8B7355\",\"#D4C5A9\",\"#A0522D\",\"#DEB887\",\"#F5DEB3\",\"#BC8F8F\",\"#CD853F\",\"#D2B48C\",\"#4A6741\"]',
      'terraced', 'victorian', 'planning', 'owner', $NOW, 1);

    INSERT OR IGNORE INTO rooms VALUES('qa-room-living', 'Living Room', 'south', 'evening', '[\"cocooning\",\"elegant\"]', 'midRange', '#C4A882', '#8B7355', '#4A6741', 0, 0, NULL, $NOW, $NOW);
    INSERT OR IGNORE INTO rooms VALUES('qa-room-bedroom', 'Bedroom', 'east', 'morning', '[\"calm\"]', 'affordable', '#D4C5A9', '#BC8F8F', '#DEB887', 0, 1, NULL, $NOW, $NOW);
    INSERT OR IGNORE INTO rooms VALUES('qa-room-kitchen', 'Kitchen', 'north', 'allDay', '[\"fresh\",\"energising\"]', 'investment', '#F5DEB3', '#CD853F', '#A0522D', 0, 2, NULL, $NOW, $NOW);
  \""
  echo "Done."
}

restart_app() {
  echo "Restarting app..."
  $ADB shell am force-stop $PKG
  sleep 2
  $ADB shell am start -n $PKG/.MainActivity > /dev/null 2>&1
  sleep 8
  echo "App ready."
}

navigate() {
  local route="$1"
  $ADB shell am start -a android.intent.action.VIEW \
    -d "palette://$route" $PKG > /dev/null 2>&1
}

take_screenshot() {
  local name="$1"
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local filename="${name}_${timestamp}.png"
  mkdir -p "$SCREENSHOT_DIR"
  $ADB shell screencap -p /sdcard/qa_screenshot.png
  $ADB pull /sdcard/qa_screenshot.png "$SCREENSHOT_DIR/$filename" > /dev/null 2>&1
  $ADB shell rm /sdcard/qa_screenshot.png
  echo "$SCREENSHOT_DIR/$filename"
}

take_full_screenshot() {
  local name="$1"
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local tmpdir=$(mktemp -d)
  local frame=0
  local prev_md5=""

  mkdir -p "$SCREENSHOT_DIR"

  # Scroll to top first (3 fast upward swipes)
  for i in 1 2 3; do
    $ADB shell input swipe 540 300 540 2000 200
  done
  sleep 1

  # Capture first frame
  $ADB shell screencap -p /sdcard/qa_frame.png
  $ADB pull /sdcard/qa_frame.png "$tmpdir/frame_${frame}.png" > /dev/null 2>&1
  prev_md5=$(md5 -q "$tmpdir/frame_${frame}.png")
  frame=$((frame + 1))

  # Scroll and capture until content stops changing
  while [ $frame -lt $MAX_SCROLLS ]; do
    $ADB shell input swipe 540 1900 540 $((1900 - SCROLL_AMOUNT)) 800
    sleep 1

    $ADB shell screencap -p /sdcard/qa_frame.png
    $ADB pull /sdcard/qa_frame.png "$tmpdir/frame_${frame}.png" > /dev/null 2>&1

    curr_md5=$(md5 -q "$tmpdir/frame_${frame}.png")
    if [ "$curr_md5" = "$prev_md5" ]; then
      rm "$tmpdir/frame_${frame}.png"
      break
    fi

    prev_md5="$curr_md5"
    frame=$((frame + 1))
  done

  $ADB shell rm -f /sdcard/qa_frame.png

  local total_frames=$frame
  local filename="${name}_full_${timestamp}.png"

  if [ $total_frames -eq 1 ]; then
    mv "$tmpdir/frame_0.png" "$SCREENSHOT_DIR/$filename"
  else
    # Crop top portion (overlap) from frames 1+ and stitch with ffmpeg
    local crop_top=1200  # Crop overlap from subsequent frames
    local keep_height=$((SCREEN_HEIGHT - crop_top))

    for i in $(seq 1 $((total_frames - 1))); do
      ffmpeg -i "$tmpdir/frame_${i}.png" \
        -vf "crop=1080:${keep_height}:0:${crop_top}" \
        -y "$tmpdir/cropped_${i}.png" 2>/dev/null
    done

    # Create a separator bar labelled "--- SCROLL ---"
    ffmpeg -f lavfi -i "color=c=0x666666:s=1080x60:d=1" \
      -vf "drawtext=text='--- SCROLL ---':fontsize=28:fontcolor=white:x=(w-tw)/2:y=(h-th)/2" \
      -frames:v 1 -y "$tmpdir/separator.png" 2>/dev/null

    # Build vstack: frame0 + [separator + cropped_N] for each subsequent frame
    local inputs="-i $tmpdir/frame_0.png -i $tmpdir/separator.png"
    local filter_labels="[0:v]"
    local input_idx=2
    local stack_count=1
    for i in $(seq 1 $((total_frames - 1))); do
      inputs="$inputs -i $tmpdir/cropped_${i}.png"
      filter_labels="${filter_labels}[1:v][$input_idx:v]"
      input_idx=$((input_idx + 1))
      stack_count=$((stack_count + 2))
    done

    ffmpeg $inputs \
      -filter_complex "${filter_labels}vstack=inputs=${stack_count}" \
      -y "$SCREENSHOT_DIR/$filename" 2>/dev/null
  fi

  rm -rf "$tmpdir"
  echo "$SCREENSHOT_DIR/$filename ($total_frames frames)"
}

show_list() {
  echo "Available screens:"
  echo "  home          Home dashboard"
  echo "  rooms         Room list"
  echo "  room-detail   Room detail (Living Room)"
  echo "  explore       Explore menu"
  echo "  wheel         Colour wheel"
  echo "  white-finder  White finder"
  echo "  paint-library Paint library"
  echo "  profile       Profile/settings"
  echo "  palette       Colour DNA palette"
  echo "  red-thread    Red thread planner"
  echo "  paywall       Subscription paywall"
  echo "  capture       Capture (coming soon)"
  echo "  onboarding    Onboarding quiz"
  echo "  dev           QA Mode screen"
}

# --- Main ---
SCREEN=""
SEED=false
FULL=false

for arg in "$@"; do
  case "$arg" in
    --seed)      SEED=true ;;
    --full)      FULL=true ;;
    --seed-only) seed_db; restart_app; exit 0 ;;
    --list)      show_list; exit 0 ;;
    *)           SCREEN="$arg" ;;
  esac
done

if [ -z "$SCREEN" ]; then
  echo "Usage: ./scripts/qa.sh <screen> [--seed] [--full]"
  echo "       ./scripts/qa.sh --list"
  exit 1
fi

ROUTE=$(get_route "$SCREEN")
if [ -z "$ROUTE" ]; then
  echo "Unknown screen: $SCREEN"
  show_list
  exit 1
fi

if [ "$SEED" = true ]; then
  seed_db
  restart_app
fi

echo "Navigating to $SCREEN ($ROUTE)..."
navigate "$ROUTE"
sleep $WAIT_SECS

if [ "$FULL" = true ]; then
  echo "Capturing full page..."
  SCREENSHOT=$(take_full_screenshot "review_$SCREEN")
  echo "Screenshot: $SCREENSHOT"
else
  SCREENSHOT=$(take_screenshot "review_$SCREEN")
  echo "Screenshot: $SCREENSHOT"
fi
