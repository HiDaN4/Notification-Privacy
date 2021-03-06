#import "Headers/Headers.h"
#import "Headers/NPSettings.h"
#import <CoreFoundation/CoreFoundation.h>

#define FILEPATH @"/var/mobile/Library/Preferences/com.dpkgdan.notificationprivacy.plist"
#define DEFAULT_TEXT @"New Notification"

@implementation NPSettings

static NPSettings *_sharedInstance;

-(void)loadSettings
{
	_preferenceFile = [[NSMutableDictionary alloc] initWithContentsOfFile: FILEPATH];

	if (_preferenceFile) {
		id object = [_preferenceFile objectForKey: @"NotificationText"];
		_notificationText = (object ? object : DEFAULT_TEXT);

		object = [_preferenceFile objectForKey: @"isEnabled"];
		_isEnabled = (object ? [object boolValue] : YES);

		object = [_preferenceFile objectForKey: @"hiddenOnLockscreen"];
		_hiddenOnLockscreen = (object ? [object boolValue] : YES);

		object = [_preferenceFile objectForKey: @"hiddenOnHomescreen"];
		_hiddenOnHomescreen = (object ? [object boolValue] : YES);

		object = [_preferenceFile objectForKey: @"hiddenInNotifcenter"];
		_hiddenInNotifcenter = (object ? [object boolValue] : NO);

		object = [_preferenceFile objectForKey: @"titleHidden"];
		_titleHidden = (object ? [object boolValue] : NO);
		
		object = [_preferenceFile objectForKey: @"lockscreenOptions"];
		_lockscreenOptions = (object ? (LOCKSCREEN_OPTIONS)[object intValue] : VISIBLE);
		
	} else {
		_isEnabled = NO;
	}
}

-(BOOL)isHiddenIdentifier:(NSString*)identifier
{
	if (_preferenceFile == Nil || identifier == Nil)
		return NO;
	if ([[_preferenceFile objectForKey: identifier] boolValue])
		return YES;
	else
		return NO;
}

-(void)eventReceived
{
	NSString *message = (self.isEnabled ? @"Enabled" : @"Disabled");
	[_preferenceFile setObject: [NSNumber numberWithBool: self.isEnabled] forKey: @"isEnabled"];

	id enabledBanner = [BBBulletinRequest new];
	[enabledBanner setTitle: @"Notification Privacy"];
	[enabledBanner setMessage: message];
	[enabledBanner setSectionID: @"libactivator"];
	[enabledBanner setDefaultAction: [BBAction action]];

	id controller = [%c(SBBulletinBannerController) sharedInstance];
	[[%c(SBBannerController) sharedInstance] _dismissIntervalElapsed];
	[controller observer:nil addBulletin:enabledBanner forFeed:2];

	[_preferenceFile writeToFile: FILEPATH atomically: YES];
}

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
	_isEnabled = !_isEnabled;
	[self eventReceived];
}

-(void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event
{
	_isEnabled = NO;
	[self eventReceived];
}

static void update (
    CFNotificationCenterRef center,
    void *observer,
    CFStringRef name,
    const void *object,
    CFDictionaryRef userInfo
)
{
	[[NPSettings sharedInstance] loadSettings];
}


-(id)init
{
	self = [super init];
	if (self){
		[self loadSettings];
	
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, update,
		 CFSTR("com.dpkgdan.notificationprivacy.settingsupdated"), NULL,
		  CFNotificationSuspensionBehaviorDeliverImmediately);
	  
		[[%c(LAActivator) sharedInstance] registerListener: self forName:@"com.dpkgdan.notificationprivacy"];
	}
	return self;
}

+(id)sharedInstance
{
	if (!_sharedInstance){
		_sharedInstance = [NPSettings new];
		return _sharedInstance;
	} else
		return _sharedInstance;
}

@end
