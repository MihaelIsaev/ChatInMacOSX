//
//  MacStreamingPlayerController.m
//  MacStreamingPlayer
//
//  Created by Matt Gallagher on 28/10/08.
//  Copyright Matt Gallagher 2008. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import <QuartzCore/CoreAnimation.h>
#import "MacStreamingPlayerController.h"
#import "AudioStreamer.h"

@implementation MediaKeyExampleApp

- (void)sendEvent:(NSEvent *)theEvent
{
	BOOL shouldHandleMediaKeyEventLocally = ![SPMediaKeyTap usesGlobalMediaKeyTap];
	if(shouldHandleMediaKeyEventLocally && [theEvent type] == NSSystemDefined && [theEvent subtype] == SPSystemDefinedEventMediaKeys)
		[(id)[self delegate] mediaKeyTap:nil receivedMediaKeyEvent:theEvent];
	[super sendEvent:theEvent];
}

@end

@implementation MacStreamingPlayerController

static MacStreamingPlayerController *shared;

+ (MacStreamingPlayerController *)shared
{
    return shared;
}

- (id)init
{
    if(shared)
        NSLog(@"Error: You are creating a second Chat shared object");
    shared = self;
    return self;
}

//
// setButtonImage:
//
// Used to change the image on the playbutton. This method exists for
// the purpose of inter-thread invocation because
// the observeValueForKeyPath:ofObject:change:context: method is invoked
// from secondary threads and UI updates are only permitted on the main thread.
//
// Parameters:
//    image - the image to set on the play button.
//
- (void)setButtonImage:(NSImage *)image
{
	[button.layer removeAllAnimations];
	if (!image)
	{
		[button setImage:[NSImage imageNamed:@"playbutton"]];
	}
	else
	{
		[button setImage:image];
		
		if ([button.image isEqual:[NSImage imageNamed:@"loadingbutton"]])
		{
			[self spinButton];
		}
	}
}

//
// destroyStreamer
//
// Removes the streamer, the UI update timer and the change notification
//
- (void)destroyStreamer
{
	if (streamer)
	{
		[[NSNotificationCenter defaultCenter]
			removeObserver:self
			name:ASStatusChangedNotification
			object:streamer];
		[progressUpdateTimer invalidate];
		progressUpdateTimer = nil;
		
		[streamer stop];
		[streamer release];
		streamer = nil;
	}
}

//
// createStreamer
//
// Creates or recreates the AudioStreamer object.
//
- (void)createStreamer
{
	if (streamer)
	{
		return;
	}

	[self destroyStreamer];
	
	NSString *escapedValue =
		[(NSString *)CFURLCreateStringByAddingPercentEscapes(
			nil,
			(CFStringRef)@"http://hepster.ru:8000/play",
			NULL,
			NULL,
			kCFStringEncodingUTF8)
		autorelease];

	NSURL *url = [NSURL URLWithString:escapedValue];
	streamer = [[AudioStreamer alloc] initWithURL:url];
	
	progressUpdateTimer =
		[NSTimer
			scheduledTimerWithTimeInterval:0.1
			target:self
			selector:@selector(updateProgress:)
			userInfo:nil
			repeats:YES];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(playbackStateChanged:)
		name:ASStatusChangedNotification
		object:streamer];
}

//
// spinButton
//
// Shows the spin button when the audio is loading. This is largely irrelevant
// now that the audio is loaded from a local file.
//
- (void)spinButton
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	CGRect frame = NSRectToCGRect([button frame]);
	button.layer.anchorPoint = CGPointMake(0.5, 0.5);
	button.layer.position = CGPointMake(frame.origin.x + 0.5 * frame.size.width, frame.origin.y + 0.5 * frame.size.height);
	[CATransaction commit];

	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanFalse forKey:kCATransactionDisableActions];
	[CATransaction setValue:[NSNumber numberWithFloat:2.0] forKey:kCATransactionAnimationDuration];

	CABasicAnimation *animation;
	animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	animation.fromValue = [NSNumber numberWithFloat:0.0];
	animation.toValue = [NSNumber numberWithFloat:-2 * M_PI];
	animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
	animation.delegate = self;
	[button.layer addAnimation:animation forKey:@"rotationAnimation"];

	[CATransaction commit];
}

//
// animationDidStop:finished:
//
// Restarts the spin animation on the button when it ends. Again, this is
// largely irrelevant now that the audio is loaded from a local file.
//
// Parameters:
//    theAnimation - the animation that rotated the button.
//    finished - is the animation finised?
//
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)finished
{
	if (finished)
	{
		[self spinButton];
	}
}

//
// buttonPressed:
//
// Handles the play/stop button. Creates, observes and starts the
// audio streamer when it is a play button. Stops the audio streamer when
// it isn't.
//
// Parameters:
//    sender - normally, the play/stop button.
//
- (IBAction)playPressed:(NSButton*)sender
{
    if (([sender isKindOfClass:[NSButton class]])?sender.state:!button.state)
	{
		button.state = 1;
        [self createStreamer];
		[streamer start];
        [timePlayed setHidden:NO];
	}
	else
	{
		button.state = 0;
        [streamer pause];
        [timePlayed setHidden:NO];
	}
}

- (IBAction)stopPressed:(id)sender
{
    [timePlayed setHidden:YES];
    button.state = 0;
    if(streamer)
        [streamer stop];
}

//
// playbackStateChanged:
//
// Invoked when the AudioStreamer
// reports that its playback status has changed.
//
- (void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([streamer isWaiting])
	{
		[timePlayed setHidden:NO];
        [timePlayed setTitle:@"подключение..."];
	}
	else if ([streamer isPlaying])
	{
		//[self stopPressed:self];
	}
	else if ([streamer isIdle])
	{
		[self destroyStreamer];
		[self stopPressed:self];
	}
}

//
// sliderMoved:
//
// Invoked when the user moves the slider
//
// Parameters:
//    aSlider - the slider (assumed to be the progress slider)
//
- (IBAction)sliderMoved:(NSSlider *)aSlider
{
	if (streamer.duration)
	{
		double newSeekTime = ([aSlider doubleValue] / 100.0) * streamer.duration;
		[streamer seekToTime:newSeekTime];
	}
}

//
// updateProgress:
//
// Invoked when the AudioStreamer
// reports that its playback progress has changed.
//
- (void)updateProgress:(NSTimer *)updatedTimer
{
    if([streamer isWaiting])
        [timePlayed setTitle:@"подключение..."];
    else if([streamer isPlaying])
    {
        int tempHour    = streamer.progress / 3600.0f;
        int tempMinute  = streamer.progress / 60.0f - tempHour * 60.0f;
        int tempSecond  = streamer.progress - (tempHour * 3600.0f + tempMinute * 60.0f);
        
        if (tempHour == 0)
            [timePlayed setTitle:[NSString stringWithFormat:@"%@:%@", [NSString stringWithFormat:(tempMinute<10)?@"0%i":@"%i", tempMinute], [NSString stringWithFormat:(tempSecond<10)?@"0%i":@"%i", tempSecond]]];
        else
            [timePlayed setTitle:[NSString stringWithFormat:@"%@:%@:%@", [NSString stringWithFormat:(tempHour<10)?@"0%i":@"%i", tempHour], [NSString stringWithFormat:(tempMinute<10)?@"0%i":@"%i", tempMinute], [NSString stringWithFormat:(tempSecond<10)?@"0%i":@"%i", tempSecond]]];
        [timePlayed setState:0];
    }
}

//
// textFieldShouldReturn:
//
// Dismiss the text field when done is pressed
//
// Parameters:
//    sender - the text field
//
// returns YES
//
- (BOOL)textFieldShouldReturn:(NSTextField *)sender
{
	[sender resignFirstResponder];
	[self createStreamer];
	return YES;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[self destroyStreamer];
	if (progressUpdateTimer)
	{
		[progressUpdateTimer invalidate];
		progressUpdateTimer = nil;
	}
	[super dealloc];
}

-(void)enableMediakeyListener
{
	if([SPMediaKeyTap usesGlobalMediaKeyTap])
		[[[SPMediaKeyTap alloc] initWithDelegate:self] startWatchingMediaKeys];
}

-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event
{
	NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
	int keyFlags = ([event data1] & 0x0000FFFF);
	BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
	int keyRepeat = (keyFlags & 0x1);
	if (keyIsPressed) {
		NSString *debugString = [NSString stringWithFormat:@"%@", keyRepeat?@", repeated.":@"."];
		switch (keyCode) {
			case NX_KEYTYPE_PLAY:
                [self playPressed:event];
				break;
			case NX_KEYTYPE_FAST:
                //NSLog(@"next");
				break;
			case NX_KEYTYPE_REWIND:
                //NSLog(@"prev");
				break;
			default:
				debugString = [NSString stringWithFormat:@"Key %d pressed%@", keyCode, debugString];
				break;
                // More cases defined in hidsystem/ev_keymap.h
		}
	}
}

@end
