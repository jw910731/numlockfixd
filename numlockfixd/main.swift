//
//  main.swift
//  numlockfixd
//
//  Created by 吳文元 on 2025/6/14.
//

import Foundation

import IOKit
import IOKit.hid
import Darwin.Mach.mach_error

func stringifyIOReturn(_ val: IOReturn) -> String {
    guard let unsafeStr = mach_error_string(val) else { return "" }
    return String(cString:unsafeStr)
}

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)); }
let matchingDict = [
    kIOHIDVendorIDKey: 0xc45,
    kIOHIDProductIDKey: 0x7811,
    kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
    kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard,
] as CFDictionary
IOHIDManagerSetDeviceMatching(manager, matchingDict)
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
IOHIDManagerRegisterDeviceMatchingCallback(manager, {_, _, _, device in
    print(device)
    guard let elements = IOHIDDeviceCopyMatchingElements(device, nil, IOOptionBits(kIOHIDOptionsTypeNone)) as? [AnyObject] as? [IOHIDElement?] else { exit(EXIT_FAILURE) }
    elements
        .filter{ $0 != nil }
        .map { $0! }
        .filter { IOHIDElementGetUsagePage($0) == kHIDPage_LEDs}
        .filter { IOHIDElementGetUsage($0) ==  kHIDUsage_LED_NumLock }
        .forEach { element in
            var unmanagedState = Unmanaged.passUnretained(IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault, element, 0, 7122));
            if (withUnsafeMutablePointer(to: &unmanagedState) {
                IOHIDDeviceGetValue(device, element, $0)
            }) != kIOReturnSuccess {
                print("Op failed")
                return;
            }
            let state = unmanagedState.takeUnretainedValue()
            let current = IOHIDValueGetIntegerValue(state)
            print("State: \(current)")
            let newState = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault, element, 0, 1)
            IOHIDDeviceSetValue(device, element, newState)
        }
}, nil);

let ret = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
if ret != kIOReturnSuccess {
    print("Failed to open manager")
    print(stringifyIOReturn(ret))
    exit(EXIT_FAILURE)
}

CFRunLoopRun()
