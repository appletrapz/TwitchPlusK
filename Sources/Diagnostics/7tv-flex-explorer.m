/*
 * 7tv-flex-explorer.m
 * See header for context. Uses NSClassFromString + objc_msgSend (looked up
 * dynamically via NSSelectorFromString) so the tweak compiles and runs fine
 * whether or not FLEX is embedded — there is no hard link to libFLEX.dylib
 * anywhere in this project or its Makefile.
 */

#import "7tv-flex-explorer.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>

static BOOL s7tv_tryLoadEmbeddedFlex(void) {
    // Common drop-in locations for a manually embedded libFLEX.dylib in a
    // sideloaded IPA. All lookups are scoped to the app's own bundle, never
    // to arbitrary filesystem paths.
    NSArray<NSString *> *candidates = @[
        [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Frameworks/libFLEX.dylib"],
        [[NSBundle mainBundle].privateFrameworksPath ?: @"" stringByAppendingPathComponent:@"libFLEX.dylib"],
    ];
    for (NSString *path in candidates) {
        if (path.length == 0) continue;
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) continue;
        if (dlopen(path.fileSystemRepresentation, RTLD_NOW | RTLD_LOCAL) != NULL) {
            return YES;
        }
    }
    return NO;
}

BOOL S7TVFlexExplorerAvailable(void) {
    if (NSClassFromString(@"FLEXManager") != nil) return YES;
    if (s7tv_tryLoadEmbeddedFlex()) return NSClassFromString(@"FLEXManager") != nil;
    return NO;
}

void S7TVSetFlexExplorerVisible(BOOL visible) {
    Class flexManagerClass = NSClassFromString(@"FLEXManager");
    if (!flexManagerClass && s7tv_tryLoadEmbeddedFlex()) {
        flexManagerClass = NSClassFromString(@"FLEXManager");
    }
    if (!flexManagerClass) {
        NSLog(@"[TwitchPlusK] FLEX Explorer requested but FLEXManager isn't "
              @"available. Make sure libFLEX.dylib is embedded in the IPA's "
              @"Frameworks/ folder.");
        return;
    }

    SEL sharedManagerSEL = NSSelectorFromString(@"sharedManager");
    if (![flexManagerClass respondsToSelector:sharedManagerSEL]) return;

    // dispatch_async: keep this off whatever thread toggled the switch,
    // consistent with the rest of the manager's UI-affecting setters.
    dispatch_async(dispatch_get_main_queue(), ^{
        id manager = ((id (*)(id, SEL))objc_msgSend)(flexManagerClass, sharedManagerSEL);
        if (!manager) return;

        SEL actionSEL = visible ? NSSelectorFromString(@"showExplorer")
                                 : NSSelectorFromString(@"hideExplorer");
        if ([manager respondsToSelector:actionSEL]) {
            ((void (*)(id, SEL))objc_msgSend)(manager, actionSEL);
        }
    });
}
