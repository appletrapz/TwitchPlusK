/*
 * 7tv-chat-top-banner.h
 *
 * Optional toggle to hide Twitch.ChatTopBannerCarouselView (the banner
 * carousel Twitch shows above the chat transcript — e.g. channel
 * announcements/promos). Same "hide native UI element" pattern as
 * s7tv_hideTwitchStoriesEnabled in 7tv-system-home-features, just scoped to
 * a UIView.didMoveToWindow hook instead of a view controller lifecycle hook.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

BOOL s7tv_hideChatTopBannerEnabled(void);
void s7tv_setHideChatTopBannerEnabled(BOOL enabled);

// Called from the UIView.didMoveToWindow router in 7tv-core-runtime-hooks.m.
// Only acts on Twitch.ChatTopBannerCarouselView; no-op otherwise.
void s7tv_handleChatTopBannerCarouselViewLifecycle(UIView *view);

NS_ASSUME_NONNULL_END
