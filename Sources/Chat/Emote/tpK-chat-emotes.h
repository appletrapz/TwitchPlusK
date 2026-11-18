#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

FOUNDATION_EXPORT id TPKChatEmotesReceive(id socket, id message);
FOUNDATION_EXPORT NSURLSessionWebSocketMessage *TPKChatEmotesReceiveLegacy(NSURLSessionWebSocketTask *task, NSURLSessionWebSocketMessage *message);
FOUNDATION_EXPORT NSURLRequest *TPKChatEmotesImageRequest(NSURLRequest *request);
FOUNDATION_EXPORT void TPKChatEmoteAnimationSetup(void);
FOUNDATION_EXPORT void TPKChatUIKitEmoteSizeSetup(void);
FOUNDATION_EXPORT NSString *TPKChatEmoteIdentifier(NSURL *url, CGSize size);
// Same identifier, and remembers the emote's name for the chat emote card.
FOUNDATION_EXPORT NSString *TPKChatEmoteIdentifierNamed(NSURL *url, CGSize size, NSString *name);
// For a gql.twitch.tv EmoteCard request about tpK emotes, returns a data: URL
// request carrying a complete local answer. Returns nil for anything else.
FOUNDATION_EXPORT NSURLRequest *TPKChatEmoteCardRequest(NSURLRequest *request);

#ifdef __cplusplus
namespace facebook { namespace jsi { class Runtime; } }
bool TPKChatEmoteSizeInstall(facebook::jsi::Runtime &runtime);
#endif
