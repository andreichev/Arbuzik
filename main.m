//
//  main.m
//  VulkanTest
//
//  Created by Andreichev Mikhail on 09.04.2025.
//

#import "AppDelegate.h"
#import "VulkanHelper.h"

#import <MetalKit/MetalKit.h>
#import <Cocoa/Cocoa.h>

bool isRunning = YES;

@interface CocoaWindowDelegate : NSObject<NSWindowDelegate>

@end

@implementation CocoaWindowDelegate

- (BOOL)windowShouldClose:(NSWindow *)sender {
    isRunning = NO;
    return YES;
}

@end

#pragma mark -
#pragma mark DemoView

/** The Metal-compatibile view for the demo Storyboard. */
@interface DemoView : NSView
@end

@implementation DemoView

/** Indicates that the view wants to draw using the backing layer instead of using drawRect:.  */
-(BOOL) wantsUpdateLayer { return YES; }

/** Returns a Metal-compatible layer. */
+(Class) layerClass { return [CAMetalLayer class]; }

/** If the wantsLayer property is set to YES, this method will be invoked to return a layer instance. */
-(CALayer*) makeBackingLayer {
    CALayer* layer = [self.class.layerClass layer];
    CGSize viewScale = [self convertSizeToBacking: CGSizeMake(1.0, 1.0)];
    layer.contentsScale = MIN(viewScale.width, viewScale.height);
    return layer;
}

/**
 * If this view moves to a screen that has a different resolution scale (eg. Standard <=> Retina),
 * update the contentsScale of the layer, which will trigger a Vulkan VK_SUBOPTIMAL_KHR result, which
 * causes this demo to replace the swapchain, in order to optimize rendering for the new resolution.
 */
-(BOOL) layer: (CALayer *)layer shouldInheritContentsScale: (CGFloat)newScale fromWindow: (NSWindow *)window {
    if (newScale == layer.contentsScale) { return NO; }

    layer.contentsScale = newScale;
    return YES;
}

@end

void pollEvents(void) {
    NSApplication* application = [NSApplication sharedApplication];
    while (true) {
        NSEvent *event = [application nextEventMatchingMask:NSEventMaskAny
                                                  untilDate:[NSDate distantPast]
                                                     inMode:NSDefaultRunLoopMode
                                                    dequeue:YES];
        if (!event) { break; }
        [application sendEvent:event];
        [application updateWindows];
    }
}

int main(int argc, const char * argv[]) {

    // -----------------------------------
    //         INIT APP AND MENU
    // -----------------------------------

    NSApplication* application = [NSApplication sharedApplication];
    AppDelegate* delegate = [[AppDelegate alloc] init];
    [application setDelegate:delegate];
    [application setActivationPolicy:NSApplicationActivationPolicyRegular];
    [application finishLaunching];
    id quitMenuItem = [NSMenuItem new];
    [quitMenuItem initWithTitle:@"Quit"
                         action:@selector(terminate:)
                  keyEquivalent:@"q"];
    id appMenu = [NSMenu new];
    [appMenu addItem:quitMenuItem];
    id appMenuItem = [NSMenuItem new];
    [appMenuItem setSubmenu:appMenu];
    id menubar = [NSMenu new];
    [menubar addItem:appMenuItem];
    [application setMainMenu:menubar];
    [application run];

    // -----------------------------------
    //     INIT WINDOW, VIEW AND LAYER
    // -----------------------------------

    NSRect frame = NSMakeRect(0, 0, 800, 600);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                     styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO];
    [window setTitle:@"Vulkan macOS Surface"];
    [window setDelegate: [[CocoaWindowDelegate alloc] init]];
    [window makeKeyAndOrderFront:nil];
    [window center];
    [window setRestorable:NO];

    DemoView *view = [[DemoView alloc] init];
    [window setContentView: view];
    [window makeFirstResponder:view];
    [window setAcceptsMouseMovedEvents: YES];
    [window makeKeyAndOrderFront:nil];

    pollEvents();

    // -----------------------------------
    //            INIT VULKAN
    // -----------------------------------

    uint32_t version;
    vkEnumerateInstanceVersion(&version);
    NSLog(
          @"System can support Vulkan version: %d.%d.%d.%d",
          VK_API_VERSION_VARIANT(version),
          VK_API_VERSION_MAJOR(version),
          VK_API_VERSION_MINOR(version),
          VK_API_VERSION_PATCH(version)
          );
    // patch = 0
    // version &= ~(0xFFFU);

    // APP INFO
    VkApplicationInfo appInfo;
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName = "Panda";
    appInfo.pEngineName = "Panda";
    appInfo.applicationVersion = version;
    appInfo.apiVersion = version;
    appInfo.pNext = nil;

    // EXTENSIONS
    uint32_t extensionCount = 0;
    vkEnumerateInstanceExtensionProperties(nil, &extensionCount, nil);
    VkExtensionProperties extensions[extensionCount];
    vkEnumerateInstanceExtensionProperties(nil, &extensionCount, extensions);
    const char* extensionNames[extensionCount];
    NSLog(@"Aavailable extensions:");
    for (int i = 0; i < extensionCount; i++) {
        NSLog(@"%d) %s", i + 1, extensions[i].extensionName);
        extensionNames[i] = extensions[i].extensionName;
    }

    // CREATE INSTANCE
    VkInstance instance;
    VkInstanceCreateInfo instanceCreateInfo;
    instanceCreateInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    instanceCreateInfo.enabledExtensionCount = extensionCount;
    instanceCreateInfo.ppEnabledExtensionNames = extensionNames;
    instanceCreateInfo.enabledLayerCount = 0;
    instanceCreateInfo.flags = VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR;
    instanceCreateInfo.pApplicationInfo = &appInfo;
    instanceCreateInfo.pNext = nil;

    VkResult result;
    result = vkCreateInstance(&instanceCreateInfo, NULL, &instance);
    if (result != VK_SUCCESS) {
        NSLog(@"Failed to create Vulkan instance: %s", getResultToString(result));
        return -1;
    }

    // CREATE SURFACE
    VkMetalSurfaceCreateInfoEXT surfaceCreateInfo;
    surfaceCreateInfo.sType = VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT;
    surfaceCreateInfo.pLayer = (CAMetalLayer*) view.layer;

    VkSurfaceKHR surface;
    result = vkCreateMetalSurfaceEXT(instance, &surfaceCreateInfo, NULL, &surface);
    if (result != VK_SUCCESS) {
        NSLog(@"Failed to create Vulkan surface: %s", getResultToString(result));
        vkDestroyInstance(instance, NULL);
        return -1;
    }

    // -----------------------------------
    //              RUN LOOP
    // -----------------------------------

    while (isRunning) {
        pollEvents();
    }

    // -----------------------------------
    //              END
    // -----------------------------------

    [application terminate:nil];
    return 0;
}