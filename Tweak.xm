#import <notify.h>

#ifdef DEBUG
#define NSLog(FORMAT, ...) NSLog(@"[Hue: %s / %i] %@", __FILE__, __LINE__, [NSString stringWithFormat:FORMAT, ##__VA_ARGS__])

#else
#define NSLog(FORMAT, ...) do {} while (0);
#endif

#define CALL_ORIGIN NSLog(@"Origin: [%@]", [[[[NSThread callStackSymbols] objectAtIndex:1] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] objectAtIndex:1])

@interface PCPersistentTimer : NSObject
-(id)initWithFireDate:(id)date serviceIdentifier:(NSString*)ident target:(id)target selector:(SEL)sel userInfo:(id)userInfo;
-(void)scheduleInRunLoop:(id)runLoop;
@end

@implementation UIColor (HueExtensions)
- (UIColor*)blendWithColor:(UIColor*)color2 alpha:(CGFloat)alpha2 {
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    [self getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [color2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];

    return [UIColor colorWithRed:(r1+r2)/2 green:(g1+g2)/2 blue:(b1+b2)/2 alpha:(a1+a2)/2];
}
@end

typedef NS_ENUM(NSInteger, HueDaySegment) {
	HueDaySegmentMorning = 6,
	HueDaySegmentMidday = 11,
	HueDaySegmentSundown = 17,
	HueDaySegmentNight = 21
};

HueDaySegment daySegmentForHour(int hour) {
	if (hour >= 6 && hour < 11) {
		return HueDaySegmentMorning;
	}
	else if (hour >= 11 && hour < 17) {
		return HueDaySegmentMidday;
	}
	else if (hour >= 17 && hour < 21) {
		return HueDaySegmentSundown;
	}
	return HueDaySegmentNight;
}
HueDaySegment nextDaySegmentForHour(int hour) {
	if (hour >= 6 && hour < 11) {
		return HueDaySegmentMidday;
	}
	else if (hour >= 11 && hour < 17) {
		return HueDaySegmentSundown;
	}
	else if (hour >= 17 && hour < 21) {
		return HueDaySegmentNight;
	}
	return HueDaySegmentMorning;
}

void adjustColorsToHour(int hour, CGFloat *red, CGFloat *green, CGFloat *blue) {
	if (hour >= 6 && hour < 11) {
    	//yellow
    	NSLog(@"Hour %i is yellow", hour);
		*red = 255;
		*green = 252;
		*blue = 11;
	}
	else if (hour >= 11 && hour < 17) {
		//light blue
		NSLog(@"Hour %i is light blue", hour);
		*red = 91;
		*green = 230;
		*blue = 186;
	}
	else if (hour >= 17 && hour < 21) {
		//orange
		NSLog(@"Hour %i is orange", hour);
		*red = 230;
		*green = 147;
		*blue = 23;
	}
	else {
		//dark blue
		NSLog(@"Hour %i is dark blue", hour);
		*red = 54;
		*green = 33;
		*blue = 198;
	}
}

NSMutableArray* allLabels;

@interface HueColorModel : NSObject {
	UIColor* _currentColor;
}
+(id)sharedInstance;
-(UIColor*)currentTimeCoordinatedColor;
-(void)updateCurrentColor;
@end 

@implementation HueColorModel
+ (id)sharedInstance {
	static dispatch_once_t p = 0;
	__strong static id _sharedObject = nil;
	 
	dispatch_once(&p, ^{
		_sharedObject = [[self alloc] init];
	});

	return _sharedObject;
}
-(UIColor*)currentTimeCoordinatedColor {
	if (!_currentColor) [self updateCurrentColor];
	return _currentColor;
}
-(void)updateCurrentColor {
	//update every label everywhere
	//lol
	for (UILabel* label in allLabels) {
		[label setTextColor:[label textColor]];
	}

	NSDate* date = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *hourComp = [gregorian components:NSCalendarUnitHour fromDate:date];
    NSDateComponents *minuteComp = [gregorian components:NSCalendarUnitMinute fromDate:date];

    NSInteger formattedHour = [hourComp hour];
    NSInteger formattedMinute = [minuteComp minute];

    CGFloat beginMinutes = (formattedHour * 60) + formattedMinute;
    CGFloat endMinutes = nextDaySegmentForHour(formattedHour) * 60;
    NSLog(@"beginMinutes: %i", (int)beginMinutes);
    NSLog(@"endMinutes: %i", (int)endMinutes);

    CGFloat startTime = formattedHour * 60;
	CGFloat progress = beginMinutes;
	if (endMinutes < startTime) endMinutes += 12*60	;
	CGFloat formattedTimeProgess = (progress - startTime)/(endMinutes - startTime);

/*
    CGFloat formattedTimeProgess = (beginMinutes < endMinutes) ? 
    								(beginMinutes - formattedHour*60)/(endMinutes - formattedHour*60) : 
    								(endMinutes - formattedHour*60)/(beginMinutes - formattedHour*60);
*/
    NSLog(@"formattedTimeProgess: %f", formattedTimeProgess);

    CGFloat red;
    CGFloat green;
    CGFloat blue;
    adjustColorsToHour(formattedHour, &red, &green, &blue);

    CGFloat finalRed;
    CGFloat finalGreen;
    CGFloat finalBlue;
    adjustColorsToHour(nextDaySegmentForHour(formattedHour), &finalRed, &finalGreen, &finalBlue);

    NSLog(@"red: %f", red);
    NSLog(@"green: %f", green);
    NSLog(@"blue: %f", blue);

    NSLog(@"finalRed: %f", finalRed);
    NSLog(@"finalGreen: %f", finalGreen);
    NSLog(@"finalBlue: %f", finalBlue);

    CGFloat newRed = (1.0 - formattedTimeProgess) * red + formattedTimeProgess * finalRed;
	CGFloat newGreen = (1.0 - formattedTimeProgess) * green + formattedTimeProgess * finalGreen;
	CGFloat newBlue = (1.0 - formattedTimeProgess) * blue + formattedTimeProgess * finalBlue;
	NSLog(@"newRed: %f", newRed);
	NSLog(@"newGreen: %f", newGreen);
	NSLog(@"newBlue: %f", newBlue);
	if (!_currentColor) _currentColor = [[UIColor alloc] init];
	_currentColor = [UIColor colorWithRed:newRed/255 green:newGreen/255 blue:newBlue/255 alpha:1.0];

	NSLog(@"New _currentColor is %@", _currentColor);
}
@end

%hook UILabel
-(id)initWithFrame:(CGRect)frame {
	id r = %orig;
	if (r) {
		[allLabels addObject:r];
	}
	return r;
}
-(void)layoutSubviews {
	%orig;

	[self setTextColor:[self textColor]];
}
-(id)textColor {
	UIColor* r = %orig;
	if (r) { 
		//We mix the two colors together 
		//This applies our color to whatever color originally would have been there
		CGFloat alpha = [r getRed:nil green:nil blue:nil alpha:&alpha];
		return [[[HueColorModel sharedInstance] currentTimeCoordinatedColor] blendWithColor:r alpha:alpha];
		//return [[HueColorModel sharedInstance] currentTimeCoordinatedColor];
	}
	return r;
}

-(void)setTextColor:(id)color {
	%orig([self textColor]);
}
%end

PCPersistentTimer* timer = nil;

void updateLabels() {
	for (UILabel* label in allLabels) {
		[label setTextColor:[label textColor]];
	}
}

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application {
	%orig;

	//get the color for the first time
	[[HueColorModel sharedInstance] updateCurrentColor];
	updateLabels();

	timer = [[%c(PCPersistentTimer) alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:60] serviceIdentifier:@"com.phillipt.hue" target:self selector:@selector(timerFired) userInfo:nil];
    [timer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
}
%new
-(void)timerFired {
	//reset the timer
	timer = [[%c(PCPersistentTimer) alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:60] serviceIdentifier:@"com.phillipt.hue" target:self selector:@selector(timerFired) userInfo:nil];
    [timer scheduleInRunLoop:[NSRunLoop mainRunLoop]];

    //update the color
    [[HueColorModel sharedInstance] updateCurrentColor];

    //send the notification for apps to update their labels
    notify_post("com.phillipt.hue.update");
}
%end

%hook UIApplication
-(id)init {
	id r = %orig;
	if (r) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), 
									NULL, 
									(CFNotificationCallback)updateLabels, 
									CFSTR("com.phillipt.hue.update"), 
									NULL, 
									CFNotificationSuspensionBehaviorCoalesce);

		allLabels = [[NSMutableArray alloc] init];
	}
	return r;
}
%end 
