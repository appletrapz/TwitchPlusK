/*
 * 7tv-flex-explorer.h
 * Optional bridge to FLEX (https://github.com/FLEXTool/FLEX, MIT), Facebook's
 * in-app debugging tool. TwitchPlusK does NOT link or embed FLEX itself —
 * this file only talks to it *if* the user has separately embedded
 * libFLEX.dylib in the sideloaded IPA (Frameworks/libFLEX.dylib). If it
 * isn't present, every function here is a safe no-op.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// YES if the FLEXManager class can be resolved at runtime (already loaded,
// or found via a best-effort dlopen of the app's embedded Frameworks dir).
BOOL S7TVFlexExplorerAvailable(void);

// Shows or hides the FLEX explorer toolbar/window. No-op (and logs once)
// if FLEX isn't available.
void S7TVSetFlexExplorerVisible(BOOL visible);

NS_ASSUME_NONNULL_END
