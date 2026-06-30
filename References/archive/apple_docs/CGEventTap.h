/* CGEventTap.h - CoreGraphics event tap API
 * Source: Apple Open Source / CoreGraphics framework
 * This header defines CGEventTapCreate and related APIs for intercepting
 * system-wide HID events on macOS.
 *
 * Key constants for button interception:
 */
#ifndef __CGEVENTTAP__
#define __CGEVENTTAP__

#include <CoreGraphics/CGEvent.h>
#include <CoreGraphics/CGEventTypes.h>

/* Tap locations */
typedef CF_ENUM(uint32_t, CGEventTapLocation) {
    kCGHIDEventTap = 0,          /* Inserted before HID system processes event */
    kCGSessionEventTap,          /* Inserted before session event filter */
    kCGAnnotatedSessionEventTap  /* Inserted after session event filter */
};

/* Tap placement */
typedef CF_ENUM(uint32_t, CGEventTapPlacement) {
    kCGHeadInsertEventTap = 0,   /* Inserted before any existing taps */
    kCGTailAppendEventTap        /* Appended after any existing taps */
};

/* Tap options */
typedef CF_ENUM(uint32_t, CGEventTapOptions) {
    kCGEventTapOptionDefault     = 0x00000000, /* Can modify/filter events */
    kCGEventTapOptionListenOnly  = 0x00000001  /* Passive - cannot modify events */
};

/* Callback type */
typedef CGEventRef (*CGEventTapCallBack)(
    CGEventTapProxy proxy,
    CGEventType type,
    CGEventRef event,
    void *userInfo
);

/* Create an event tap */
CG_EXTERN CFMachPortRef CGEventTapCreate(
    CGEventTapLocation tap,
    CGEventTapPlacement place,
    CGEventTapOptions options,
    CGEventMask eventsOfInterest,
    CGEventTapCallBack callback,
    void *userInfo
);

/* Enable or disable an event tap */
CG_EXTERN void CGEventTapEnable(CFMachPortRef tap, bool enable);

/* Check if an event tap is enabled */
CG_EXTERN bool CGEventTapIsEnabled(CFMachPortRef tap);

/* Get the sending IOHIDDevice from a CGEvent (reverse-engineered, works on 10.13+) */
/* Usage: IOHIDDeviceRef device = CGEventGetSendingDevice(event); */
/* Note: This is a private/undocumented API used by Mac Mouse Fix */

#endif /* __CGEVENTTAP__ */
