//
//  DSLogger.m
//  MarcoPolo
//
//  Created by David Symonds on 22/07/07.
//

#import "DSLogger.h"


#define DSLOGGER_CAPACITY	128

static DSLogger *shared_Logger = nil;


@implementation DSLogger

+ (DSLogger *)sharedLogger
{
	if (!shared_Logger) {
		shared_Logger = [[DSLogger alloc] init];
	}

	return shared_Logger;
}

- (id)init
{
	if (!(self = [super init]))
		return nil;

	lock = [[NSLock alloc] init];

	timestampFormatter = [[NSDateFormatter alloc] init];
	[timestampFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[timestampFormatter setDateFormat:@"HH:mm:ss.SSS"];

	buffer = [[NSMutableArray alloc] initWithCapacity:DSLOGGER_CAPACITY];
	startIndex = count = 0;

	return self;
}

- (void)dealloc
{
	[lock release];
	[timestampFormatter release];
	[buffer release];

	[super dealloc];
}

- (void)logFromFunction:(const char *)function withFormat:(NSString *)format, ...
{
	[lock lock];

	va_list ap;
	va_start(ap, format);
	NSString *line = [NSString stringWithFormat:@"%@ %s\n\t%@",
		[timestampFormatter stringFromDate:[NSDate date]],
		function,
		[[[NSString alloc] initWithFormat:format arguments:ap] autorelease]];
	va_end(ap);

	if (count < DSLOGGER_CAPACITY) {
		[buffer addObject:line];
		++count;
	} else {
		[buffer replaceObjectAtIndex:startIndex withObject:line];
		startIndex = (startIndex + 1) % DSLOGGER_CAPACITY;
	}

	[lock unlock];
}

// XXX: horribly inefficient!
- (NSString *)buffer
{
	if (count == 0)
		return @"";

	[lock lock];
	NSMutableString *buf = [NSMutableString string];
	int i = startIndex, cnt = count;

	while (cnt > 0) {
		[buf appendString:[buffer objectAtIndex:i]];
		if (cnt > 1)
			[buf appendString:@"\n"];

		i = (i + 1) % DSLOGGER_CAPACITY;
		--cnt;
	}

	[lock unlock];
	return buf;
}

@end