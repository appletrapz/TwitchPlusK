/*
 * 7tv-chat-top-banner.h
 *
 * Four independent toggles to hide native banner content Twitch shows above
 * the chat transcript:
 *   - Twitch.VerticalContentScrollView  (the container hosting the whole
 *                                         carousel — hiding it hides all
 *                                         of the below at once)
 *   - Twitch.TopChatCalloutView         (Drops / Hype Train / Prediction / Polls)
 *   - Twitch.CreatorGoalsBannerView     (Sub/Follower goals banner)
 *   - Twitch.LeaderboardBannerView      (Leaderboard banner)
 * Same "hide native UI element" pattern as s7tv_hideTwitchStoriesEnabled in
 * 7tv-system-home-features, just scoped to a UIView.didMoveToWindow hook
 * instead of a view controller lifecycle hook.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

BOOL s7tv_hideChatVerticalContentEnabled(void);
void s7tv_setHideChatVerticalContentEnabled(BOOL enabled);

BOOL s7tv_hideChatTopCalloutEnabled(void);
void s7tv_setHideChatTopCalloutEnabled(BOOL enabled);

BOOL s7tv_hideCreatorGoalsBannerEnabled(void);
void s7tv_setHideCreatorGoalsBannerEnabled(BOOL enabled);

BOOL s7tv_hideLeaderboardBannerEnabled(void);
void s7tv_setHideLeaderboardBannerEnabled(BOOL enabled);

// Called from the UIView.didMoveToWindow router in 7tv-core-runtime-hooks.m.
// Only acts on the banner-related classes described above, gated
// individually by their respective toggle; no-op otherwise.
void s7tv_handleChatTopBannerCarouselViewLifecycle(UIView *view);

NS_ASSUME_NONNULL_END
