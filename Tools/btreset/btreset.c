// btreset: put an Intel Bluetooth module back into its bootloader (HCI 0xFC01 "Intel Reset").
//
// Why: the CNVi BT module keeps whatever firmware ran last (Linux, Windows, an older macOS session)
// across restarts and even shutdowns on AC. IntelBTUnified then sees "(already running)", skips its own
// upload, and macOS's bluetoothd fails ("Transport layer initialization failed", Address: NULL).
// After this reset the module re-enumerates in bootloader mode and IntelBTUnified uploads its firmware.
//
// Same command Linux uses in btintel_reset_to_bootloader():
//   opcode 0xFC01, params: reset_type=1, patch_enable=1, ddc_reload=1, boot_option=0, boot_param=0
// sent as an HCI command over USB (class request, bRequest 0, on the default control pipe).
//
// Build: clang -O2 -Wall -framework IOKit -framework CoreFoundation btreset.c -o btreset
// Usage: sudo ./btreset [-n]      (-n: only list the device, do not reset)
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>

static const uint16_t kIntelVendor = 0x8087;
static const uint16_t kProducts[] = { 0x0025, 0x0026, 0x0029, 0x0032, 0x0033, 0x0035, 0x0036, 0x0038, 0x0a2b, 0x0aaa };

static int intProp(io_service_t s, CFStringRef key) {
    int v = -1;
    CFTypeRef r = IORegistryEntryCreateCFProperty(s, key, kCFAllocatorDefault, 0);
    if (r && CFGetTypeID(r) == CFNumberGetTypeID()) CFNumberGetValue((CFNumberRef)r, kCFNumberIntType, &v);
    if (r) CFRelease(r);
    return v;
}

static int isIntelBT(io_service_t s) {
    if (intProp(s, CFSTR("idVendor")) != kIntelVendor) return 0;
    int pid = intProp(s, CFSTR("idProduct"));
    for (size_t i = 0; i < sizeof kProducts / sizeof kProducts[0]; i++) if (pid == kProducts[i]) return pid;
    return 0;
}

static IOReturn sendReset(io_service_t s) {
    IOCFPlugInInterface **plug = NULL;
    SInt32 score = 0;
    IOReturn kr = IOCreatePlugInInterfaceForService(s, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plug, &score);
    if (kr != kIOReturnSuccess || !plug) { fprintf(stderr, "btreset: no USB user client (0x%08x)\n", kr); return kr; }
    IOUSBDeviceInterface **dev = NULL;
    (*plug)->QueryInterface(plug, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID *)&dev);
    (*plug)->Release(plug);
    if (!dev) { fprintf(stderr, "btreset: no device interface\n"); return kIOReturnError; }

    // Open if we can; a control request on the default pipe also works while a kext owns the device
    // on most systems, so carry on if opening fails.
    IOReturn op = (*dev)->USBDeviceOpen(dev);
    if (op != kIOReturnSuccess) op = (*dev)->USBDeviceOpenSeize(dev);
    if (op != kIOReturnSuccess) fprintf(stderr, "btreset: device not opened (0x%08x), trying anyway\n", op);

    uint8_t cmd[] = { 0x01, 0xFC, 0x08,            // opcode 0xFC01 (LE), parameter length 8
                      0x01, 0x01, 0x01, 0x00,      // reset_type, patch_enable, ddc_reload, boot_option
                      0x00, 0x00, 0x00, 0x00 };    // boot_param
    IOUSBDevRequest req;
    memset(&req, 0, sizeof req);
    req.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBDevice);   // 0x20: HCI command
    req.bRequest = 0;
    req.wValue = 0;
    req.wIndex = 0;
    req.wLength = sizeof cmd;
    req.pData = cmd;
    kr = (*dev)->DeviceRequest(dev, &req);
    // The module resets right away and drops off the bus, so an error here can still mean success.
    printf("btreset: Intel Reset sent (result 0x%08x); the module should re-enumerate in bootloader mode\n", kr);

    if (op == kIOReturnSuccess) (*dev)->USBDeviceClose(dev);
    (*dev)->Release(dev);
    return kr;
}

int main(int argc, char **argv) {
    int listOnly = (argc > 1 && strcmp(argv[1], "-n") == 0);
    io_iterator_t it = 0;
    CFMutableDictionaryRef match = IOServiceMatching("IOUSBHostDevice");
    if (IOServiceGetMatchingServices(MACH_PORT_NULL /* default main port */, match, &it) != kIOReturnSuccess) return 2;
    int found = 0;
    io_service_t s;
    while ((s = IOIteratorNext(it))) {
        int pid = isIntelBT(s);
        if (pid) {
            found++;
            printf("btreset: Intel Bluetooth %04x:%04x, locationID 0x%08x\n", kIntelVendor, pid,
                   (unsigned)intProp(s, CFSTR("locationID")));
            if (!listOnly) sendReset(s);
        }
        IOObjectRelease(s);
    }
    IOObjectRelease(it);
    if (!found) { fprintf(stderr, "btreset: no Intel Bluetooth USB device found\n"); return 1; }
    return 0;
}
