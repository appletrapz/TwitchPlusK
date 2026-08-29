/*
 * 7tv-chat-top-banner.m
 * See header for context.
 */

#import "Chat/7tv-chat-top-banner.h"
#import <objc/runtime.h>
#import <os/log.h>

static NSString *const S7TVHideChatTopBannerKey = @"s7tv_hide_chat_top_banner";
static char kS7TVChatTopBannerHiddenKey;

BOOL s7tv_hideChatTopBannerEnabled(void) {
    return [NSUserDefaults.standardUserDefaults boolForKey:S7TVHideChatTopBannerKey];
}

void s7tv_setHideChatTopBannerEnabled(BOOL enabled) {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:S7TVHideChatTopBannerKey];
}

void s7tv_handleChatTopBannerCarouselViewLifecycle(UIView *view) {
    if (![NSStringFromClass(view.class) isEqualToString:@"Twitch.ChatTopBannerCarouselView"] ||
        !view.window) return;
    if (!s7tv_hideChatTopBannerEnabled()) {
        // Le réglage a pu être désactivé après une précédente occultation
        // (nouvelle vue recyclée) : on la laisse visible normalement.
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
    os_log(OS_LOG_DEFAULT, "[S7TV-Chat] ChatTopBannerCarouselView hidden");
}
