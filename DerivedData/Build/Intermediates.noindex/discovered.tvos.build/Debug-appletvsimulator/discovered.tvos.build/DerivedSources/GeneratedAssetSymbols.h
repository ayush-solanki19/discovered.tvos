#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "Container" asset catalog image resource.
static NSString * const ACImageNameContainer AC_SWIFT_PRIVATE = @"Container";

/// The "Profile Avatar" asset catalog image resource.
static NSString * const ACImageNameProfileAvatar AC_SWIFT_PRIVATE = @"Profile Avatar";

/// The "hero_back" asset catalog image resource.
static NSString * const ACImageNameHeroBack AC_SWIFT_PRIVATE = @"hero_back";

#undef AC_SWIFT_PRIVATE
