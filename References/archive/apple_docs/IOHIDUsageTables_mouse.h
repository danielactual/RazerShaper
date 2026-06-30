/* IOHIDUsageTables_mouse.h - Relevant subset of HID Usage Tables for mouse/pointer
 * Source: USB-IF HID Usage Tables 1.5 (archived locally as PDF)
 *         Apple IOKit IOHIDUsageTables.h
 *
 * Usage Page: Generic Desktop (0x01)
 */

/* Usage Page 0x01 - Generic Desktop */
#define kHIDPage_GenericDesktop         0x01
#define kHIDUsage_GD_Pointer            0x01  /* Physical Collection */
#define kHIDUsage_GD_Mouse              0x02  /* Application Collection */
#define kHIDUsage_GD_Keyboard           0x06  /* Application Collection */
#define kHIDUsage_GD_X                  0x30  /* Dynamic Value */
#define kHIDUsage_GD_Y                  0x31  /* Dynamic Value */
#define kHIDUsage_GD_Wheel              0x38  /* Dynamic Value */

/* Usage Page 0x09 - Button */
#define kHIDPage_Button                 0x09
/* Button usages are 1-indexed: kHIDUsage_Button_1 = 0x01 (left), 2 = right, 3 = middle, 4+ = extra */
#define kHIDUsage_Button_1              0x01
#define kHIDUsage_Button_2              0x02
#define kHIDUsage_Button_3              0x03
#define kHIDUsage_Button_4              0x04  /* Typically "Back" */
#define kHIDUsage_Button_5              0x05  /* Typically "Forward" */

/* Usage Page 0x0C - Consumer */
#define kHIDPage_Consumer               0x0C
#define kHIDUsage_Csmr_ACBack           0x0224
#define kHIDUsage_Csmr_ACForward        0x0225

/* kIOHIDOptionsTypeNone - used when opening HID devices */
#define kIOHIDOptionsTypeNone           0x00

/* kIOHIDReportTypeFeature - used with IOHIDDeviceSetReport/GetReport */
/* kIOHIDReportTypeInput   - for reading input reports */
/* kIOHIDReportTypeOutput  - for writing output reports */
