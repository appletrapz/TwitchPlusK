#import "Chat/Emote/tpK-chat-emotes.h"
#import "Emote/tpK-emote-image-transport.h"
#include <math.h>

NSString *TPKChatEmoteIdentifier(NSURL *url, CGSize size) {
    NSString *encoded = [[url.absoluteString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    encoded = [[encoded stringByReplacingOccurrencesOfString:@"+" withString:@"-"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    CGFloat ratio = size.height > 0 ? size.width / size.height : 1;
    if (!isfinite(ratio) || ratio <= 0) ratio = 1;
    return [NSString stringWithFormat:@"tpk_r%ld_%@", (long)lround(MIN(5, MAX(.125, ratio)) * 1000),
        [encoded stringByReplacingOccurrencesOfString:@"=" withString:@""]];
}

// Decodes the provider image URL carried by a tpk_ emote identifier, or nil.
static NSURL *TPKChatEmoteImageURL(NSString *identifier) {
    if (![identifier hasPrefix:@"tpk_"] || identifier.length > 1400) return nil;
    NSString *payload = [identifier substringFromIndex:4];
    if ([payload hasPrefix:@"r"]) {
        NSRange separator = [payload rangeOfString:@"_"];
        if (separator.location == NSNotFound) return nil;
        NSString *digits = [payload substringWithRange:NSMakeRange(1, separator.location - 1)];
        if (!digits.length || digits.length > 4 ||
            [digits rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location != NSNotFound ||
            digits.integerValue < 125 || digits.integerValue > 5000) return nil;
        payload = [payload substringFromIndex:separator.location + 1];
    }
    NSString *encoded = [payload stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    encoded = [encoded stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    while (encoded.length % 4) encoded = [encoded stringByAppendingString:@"="];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:encoded options:0];
    NSString *text = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
    NSURL *image = text ? [NSURL URLWithString:text] : nil;
    return TPKEmoteImageProviderURL(image) ? image : nil;
}

// identifier -> emote name, filled when emotes are injected into chat.
static NSCache<NSString *, NSString *> *TPKChatEmoteNames(void) {
    static NSCache *names;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        names = [NSCache new];
        names.countLimit = 8192;
    });
    return names;
}

NSString *TPKChatEmoteIdentifierNamed(NSURL *url, CGSize size, NSString *name) {
    NSString *identifier = TPKChatEmoteIdentifier(url, size);
    if (identifier.length && name.length && name.length <= 100)
        [TPKChatEmoteNames() setObject:name forKey:identifier];
    return identifier;
}

static NSString *TPKChatEmoteFallbackName(NSURL *image) {
    NSString *host = image.host.lowercaseString ?: @"";
    if ([host containsString:@"7tv"]) return @"7TV emote";
    if ([host containsString:@"betterttv"]) return @"BTTV emote";
    if ([host containsString:@"frankerfacez"]) return @"FFZ emote";
    return @"Emote";
}

// One complete EmoteCard result. Apollo's cache drops results that miss any
// requested field, so every field of the query is present: the tpK emote is
// presented as a GLOBALS emote with no owner, which the card shows with just
// its image and name instead of "Error loading emote data".
static NSDictionary *TPKChatEmoteCardResult(NSString *identifier) {
    NSURL *image = TPKChatEmoteImageURL(identifier);
    if (!image) return nil;
    NSString *name = [TPKChatEmoteNames() objectForKey:identifier] ?: TPKChatEmoteFallbackName(image);
    return @{@"data": @{@"emote": @{
        @"__typename": @"Emote",
        @"id": identifier,
        @"token": name,
        @"type": @"GLOBALS",
        @"subscriptionTier": NSNull.null,
        @"setID": NSNull.null,
        @"owner": NSNull.null,
        @"subscriptionProduct": NSNull.null,
        @"subscriptionSummaries": @[],
        @"bitsBadgeTierSummary": NSNull.null,
    }}};
}

static NSString *TPKChatEmoteCardIdentifier(id operation) {
    if (![operation isKindOfClass:NSDictionary.class] ||
        ![operation[@"operationName"] isEqual:@"EmoteCard"]) return nil;
    NSDictionary *variables = operation[@"variables"];
    if (![variables isKindOfClass:NSDictionary.class]) return nil;
    NSString *identifier = variables[@"emoteID"];
    return [identifier isKindOfClass:NSString.class] && [identifier hasPrefix:@"tpk_"] ? identifier : nil;
}

NSURLRequest *TPKChatEmoteCardRequest(NSURLRequest *request) {
    if (![request.URL.host.lowercaseString isEqualToString:@"gql.twitch.tv"] ||
        ![request.HTTPMethod isEqualToString:@"POST"]) return nil;
    NSData *body = request.HTTPBody;
    // Cheap test before parsing every GraphQL request body.
    if (body.length < 20 || body.length > 65536 ||
        [body rangeOfData:[@"EmoteCard" dataUsingEncoding:NSUTF8StringEncoding]
                  options:0 range:NSMakeRange(0, body.length)].location == NSNotFound) return nil;
    id payload = [NSJSONSerialization JSONObjectWithData:body options:0 error:nil];
    id answer = nil;
    if ([payload isKindOfClass:NSDictionary.class]) {
        NSString *identifier = TPKChatEmoteCardIdentifier(payload);
        answer = identifier ? TPKChatEmoteCardResult(identifier) : nil;
    } else if ([payload isKindOfClass:NSArray.class] && [payload count] && [payload count] <= 32) {
        // A batch is answered locally only if every operation in it is ours.
        NSMutableArray *results = [NSMutableArray array];
        for (id operation in payload) {
            NSString *identifier = TPKChatEmoteCardIdentifier(operation);
            NSDictionary *result = identifier ? TPKChatEmoteCardResult(identifier) : nil;
            if (!result) return nil;
            [results addObject:result];
        }
        answer = results;
    }
    if (!answer) return nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:answer options:0 error:nil];
    if (!json) return nil;
    NSString *url = [@"data:application/json;base64," stringByAppendingString:[json base64EncodedStringWithOptions:0]];
    NSMutableURLRequest *local = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                     timeoutInterval:15];
    local.HTTPMethod = @"GET";
    return local;
}

NSURLRequest *TPKChatEmotesImageRequest(NSURLRequest *request) {
    NSURL *url = request.URL;
    if (![url.host.lowercaseString isEqualToString:@"static-cdn.jtvnw.net"] ||
        ![request.HTTPMethod isEqualToString:@"GET"]) return request;
    NSArray<NSString *> *parts = url.pathComponents;
    BOOL nativeRoute = (parts.count == 7 && [parts[2] isEqualToString:@"v2"]) ||
        (parts.count == 5 && [parts[2] isEqualToString:@"v1"]);
    if (!nativeRoute || ![parts[1] isEqualToString:@"emoticons"]) return request;
    NSURL *image = TPKChatEmoteImageURL(parts[3]);
    if (!image) return request;
    // Do not forward Twitch cookies or authorization headers to provider CDNs.
    return [NSURLRequest requestWithURL:image cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
}
