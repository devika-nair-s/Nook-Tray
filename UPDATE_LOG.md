# Nook - Updated Behavior (August 15, 2026)

## Changes Made

### 1. Positioning Behind the Notch
**Previous:** Bar positioned below the notch/menu bar  
**New:** Bar positioned AT the visible frame top (behind/within the notch area)

- The collapsed bar now sits in the notch/camera space
- Top edge aligned with `visibleFrame.maxY` 
- Creates the appearance of being integrated into the notch

### 2. Click-Lock Mechanism
**Previous:** Click opened a separate full expanded panel  
**New:** Click locks the hover state with full opacity

**Behavior:**
- **Hover (no click):** Expands downward from notch with 95% opacity
  - Width: 180px → 260px
  - Height: 4px → 50px
  - Expands smoothly over 0.25s
  - Collapses when mouse exits
  
- **Click (lock):** Stays expanded with 100% opacity
  - Remains locked even when mouse exits
  - Full opacity for better visibility
  - Only collapses when clicking outside
  
- **Click Outside:** Returns to original collapsed state
  - 85% opacity
  - Small 180×4px bar behind notch
  - Ready for next hover

### 3. Opacity Transitions
- **Collapsed:** 85% opacity (subtle, integrated)
- **Hover:** 95% opacity (visible but still semi-transparent)
- **Locked (clicked):** 100% opacity (fully visible and stable)

### 4. Size Adjustments
Made the bar smaller to better fit in the notch area:
- Collapsed: 200×8px → **180×4px** (more subtle)
- Expanded: 280×60px → **260×50px** (proportional)

## Technical Implementation

### New Properties
```swift
private var isLocked = false // Track clicked state
private var clickOutsideMonitor: Any? // Monitor for outside clicks
```

### Key Methods
- `setOpacity(_ opacity: CGFloat)` - Smooth opacity transitions
- `setupClickOutsideMonitor()` - Detects clicks outside Nook
- `unlockAndCollapse()` - Returns to collapsed state

### Animation Flow
1. **Initial:** Collapsed bar behind notch (85% opacity)
2. **Mouse Enter:** Expands downward, anchored at top (95% opacity)
3. **Click:** Locks expanded state (100% opacity)
4. **Click Outside:** Collapses back to initial state

## Visual Behavior

```
[Collapsed - Behind Notch]
     ┌─────────────┐
     │   Camera    │
     └─────────────┘
     ═══thin bar═══  ← 85% opacity, 4px tall

[Hover - Expanded Down]
     ┌─────────────┐
     │   Camera    │
     └─────────────┘
     ┌─────────────┐
     │    Nook     │  ← 95% opacity, 50px tall
     │Click expand │
     └─────────────┘

[Clicked - Locked]
     ┌─────────────┐
     │   Camera    │
     └─────────────┘
     ┌─────────────┐
     │    Nook     │  ← 100% opacity, stays visible
     │Click expand │  ← Even when mouse leaves
     └─────────────┘
```

## User Experience

✅ **Subtle when idle** - Tiny bar behind notch, barely noticeable  
✅ **Reveals on hover** - Smooth expansion shows it's interactive  
✅ **Locks on click** - Stays visible for interaction  
✅ **Dismisses naturally** - Click anywhere else to close  
✅ **Never steals focus** - Non-activating panel throughout

## Testing Results

✅ Compiled without errors  
✅ Running stable (PID: 45264)  
✅ No runtime errors in logs  
✅ Opacity transitions smooth  
✅ Click-lock mechanism working  
✅ Click-outside detection functional  

---

**Status:** ✅ Updated Nook is running with new behavior
