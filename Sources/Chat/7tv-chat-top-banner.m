/*
 * 7tv-chat-top-banner.m
 * See header for context.
 */

#import "Chat/7tv-chat-top-banner.h"
#import <objc/runtime.h>
#import <os/log.h>

static NSString *const S7TVHideChatVerticalContentKey = @"s7tv_hide_chat_vertical_content";
static NSString *const S7TVHideChatTopCalloutKey      = @"s7tv_hide_chat_top_callout";
static NSString *const S7TVHideCreatorGoalsBannerKey  = @"s7tv_hide_creator_goals_banner";
static NSString *const S7TVHideLeaderboardBannerKey   = @"s7tv_hide_leaderboard_banner";

static char kS7TVChatTopBannerHiddenKey;

BOOL s7tv_hideChatVerticalContentEnabled(void) {
    return [NSUserDefaults.standardUserDefaults boolForKey:S7TVHideChatVerticalContentKey];
}
void s7tv_setHideChatVerticalContentEnabled(BOOL enabled) {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:S7TVHideChatVerticalContentKey];
}

BOOL s7tv_hideChatTopCalloutEnabled(void) {
    return [NSUserDefaults.standardUserDefaults boolForKey:S7TVHideChatTopCalloutKey];
}
void s7tv_setHideChatTopCalloutEnabled(BOOL enabled) {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:S7TVHideChatTopCalloutKey];
}

BOOL s7tv_hideCreatorGoalsBannerEnabled(void) {
    return [NSUserDefaults.standardUserDefaults boolForKey:S7TVHideCreatorGoalsBannerKey];
}
void s7tv_setHideCreatorGoalsBannerEnabled(BOOL enabled) {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:S7TVHideCreatorGoalsBannerKey];
}

BOOL s7tv_hideLeaderboardBannerEnabled(void) {
    return [NSUserDefaults.standardUserDefaults boolForKey:S7TVHideLeaderboardBannerKey];
}
void s7tv_setHideLeaderboardBannerEnabled(BOOL enabled) {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:S7TVHideLeaderboardBannerKey];
}

// Associe chaque classe Twitch ciblée à son toggle indépendant.
static BOOL s7tv_chatTopBannerClassEnabled(NSString *className) {
    if ([className isEqualToString:@"Twitch.VerticalContentScrollView"]) {
        return s7tv_hideChatVerticalContentEnabled();
    }
    if ([className isEqualToString:@"Twitch.TopChatCalloutView"]) {
        return s7tv_hideChatTopCalloutEnabled();
    }
    if ([className isEqualToString:@"Twitch.CreaterGoalsBannerView"]) {
        return s7tv_hideCreatorGoalsBannerEnabled();
    }
    if ([className isEqualToString:@"Twitch.LeaderboardBannerView"]) {
        return s7tv_hideLeaderboardBannerEnabled();
    }
    return NO;
}

static BOOL s7tv_isChatTopBannerTargetClass(NSString *className) {
    return [className isEqualToString:@"Twitch.VerticalContentScrollView"] ||
           [className isEqualToString:@"Twitch.TopChatCalloutView"] ||
           [className isEqualToString:@"Twitch.CreaterGoalsBannerView"] ||
           [className isEqualToString:@"Twitch.LeaderboardBannerView"];
}

void s7tv_handleChatTopBannerCarouselViewLifecycle(UIView *view) {
    NSString *className = NSStringFromClass(view.class);
    if (!s7tv_isChatTopBannerTargetClass(className) || !view.window) return;
    if (!s7tv_chatTopBannerClassEnabled(className)) {
        // Le réglage propre à cette classe a pu être désactivé après une
        // précédente occultation (nouvelle vue recyclée) : on la laisse
        // visible normalement.
        return;
    }
    if ([objc_getAssociatedObject(view, &kS7TVChatTopBannerHiddenKey) boolValue]) return;
    objc_setAssociatedObject(view, &kS7TVChatTopBannerHiddenKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    view.hidden = YES;
    // Si le parent est un UIStackView, .hidden suffit à récupérer l'espace
    // automatiquement. Sinon (contrainte de hauteur fixe côté Twitch), on
    // force la hauteur à 0 pour ne pas laisser un bandeau vide.
    if (![view.superview isKindOfClass:UIStackView.class]) {
        NSLayoutConstraint *zeroHeight =
            [view.heightAnchor constraintEqualToConstant:0.0];
        zeroHeight.priority = UILayoutPriorityRequired;
        zeroHeight.active = YES;
    }
    os_log(OS_LOG_DEFAULT, "[S7TV-Chat] %{public}@ hidden", className);
}
