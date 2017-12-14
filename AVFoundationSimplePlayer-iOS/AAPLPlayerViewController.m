/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View controller containing a player view and basic playback controls.
*/


@import Foundation;
@import AVFoundation;
@import CoreMedia.CMTime;
#import "AAPLPlayerViewController.h"
#import "AAPLPlayerView.h"
#import <Analytics/SEGAnalytics.h>

// Private properties
@interface AAPLPlayerViewController ()
{
    AVPlayer *_player;
    AVURLAsset *_asset;
    id<NSObject> _timeObserverToken;
    AVPlayerItem *_playerItem;
}

@property AVPlayerItem *playerItem;
@property (nonatomic, strong) NSTimer *playheadTimer;

@property (readonly) AVPlayerLayer *playerLayer;
@property NSDictionary *metadata;

@end


@implementation AAPLPlayerViewController

// MARK: - View Handling

/*
	KVO context used to differentiate KVO callbacks for this class versus other
	classes in its class hierarchy.
*/
static int AAPLPlayerViewControllerKVOContext = 0;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[SEGAnalytics sharedAnalytics] screen:@"Main"];

    /*
        Update the UI when these player properties change.
    
        Use the context parameter to distinguish KVO for our particular observers and not
        those destined for a subclass that also happens to be observing these properties.
    */
    [self addObserver:self forKeyPath:@"asset" options:NSKeyValueObservingOptionNew context:&AAPLPlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.duration" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];

    self.playerView.playerLayer.player = self.player;

    // Use a weak self variable to avoid a retain cycle in the block.
    AAPLPlayerViewController __weak *weakSelf = self;
    _timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:
                                                                                                                              ^(CMTime time) {
                                                                                                                                  weakSelf.timeSlider.value = CMTimeGetSeconds(time);
                                                                                                                              }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)itemDidFinishPlaying:(NSNotification *)notification
{
    NSNumber *position = [NSNumber numberWithFloat:CMTimeGetSeconds(self.currentTime)];
    NSNumber *total = [NSNumber numberWithFloat:CMTimeGetSeconds(self.duration)];

    [self stopPlayheadTimer];
    [[SEGAnalytics sharedAnalytics] track:@"Video Playback Completed" properties:@{ @"session_id" : self.metadata[@"session_id"],
                                                                                    @"content_asset_id" : self.metadata[@"content_asset_id"],
                                                                                    @"position" : position,
                                                                                    @"sound" : self.metadata[@"sound"],
                                                                                    @"full_screen" : self.metadata[@"full_screen"],
                                                                                    @"total_length" : total,
                                                                                    @"livestream" : self.metadata[@"livestream"] }];

    [[SEGAnalytics sharedAnalytics] track:@"Video Content Completed" properties:@{
        @"asset_id" : self.metadata[@"asset_id"],
        @"pod_id" : self.metadata[@"pod_id"],
        @"title" : self.metadata[@"title"],
        @"season" : self.metadata[@"season"],
        @"episode" : self.metadata[@"episode"],
        @"genre" : self.metadata[@"genre"],
        @"program" : self.metadata[@"program"],
        @"total_length" : total,
        @"full_episode" : self.metadata[@"full_episode"],
        @"publisher" : self.metadata[@"publisher"],
        @"channel" : self.metadata[@"channel"],
        @"position" : position
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if (_timeObserverToken) {
        [self.player removeTimeObserver:_timeObserverToken];
        _timeObserverToken = nil;
    }
    NSNumber *position = [NSNumber numberWithFloat:CMTimeGetSeconds(self.currentTime)];
    NSNumber *total = [NSNumber numberWithFloat:CMTimeGetSeconds(self.duration)];
    [self stopPlayheadTimer];
    [self.player pause];
    [[SEGAnalytics sharedAnalytics] track:@"Video Playback Interrupted" properties:@{ @"session_id" : self.metadata[@"session_id"],
                                                                                      @"content_asset_id" : self.metadata[@"content_asset_id"],
                                                                                      @"video_player" : self.metadata[@"video_player"],
                                                                                      @"position" : position,
                                                                                      @"sound" : self.metadata[@"sound"],
                                                                                      @"full_screen" : self.metadata[@"full_screen"],
                                                                                      @"bitrate" : self.metadata[@"bitrate"],
                                                                                      @"total_length" : total,
                                                                                      @"livestream" : self.metadata[@"livestream"] }];


    [self removeObserver:self forKeyPath:@"asset" context:&AAPLPlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.duration" context:&AAPLPlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.rate" context:&AAPLPlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:&AAPLPlayerViewControllerKVOContext];
}

// MARK: - Properties

// Will attempt load and test these asset keys before playing
+ (NSArray *)assetKeysRequiredToPlay
{
    return @[ @"playable", @"hasProtectedContent" ];
}

- (AVPlayer *)player
{
    if (!_player)
        _player = [[AVPlayer alloc] init];
    return _player;
}

- (CMTime)currentTime
{
    return self.player.currentTime;
}
- (void)setCurrentTime:(CMTime)newCurrentTime
{
    [self.player seekToTime:newCurrentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (CMTime)duration
{
    return self.player.currentItem ? self.player.currentItem.duration : kCMTimeZero;
}

- (float)rate
{
    return self.player.rate;
}
- (void)setRate:(float)newRate
{
    self.player.rate = newRate;
}

- (AVPlayerLayer *)playerLayer
{
    return self.playerView.playerLayer;
}

- (AVPlayerItem *)playerItem
{
    return _playerItem;
}

- (void)setPlayerItem:(AVPlayerItem *)newPlayerItem
{
    if (_playerItem != newPlayerItem) {
        _playerItem = newPlayerItem;

        // If needed, configure player item here before associating it with a player
        // (example: adding outputs, setting text style rules, selecting media options)
        [self.player replaceCurrentItemWithPlayerItem:_playerItem];
    }
}

// MARK: - Asset Loading

- (void)asynchronouslyLoadURLAsset:(AVURLAsset *)newAsset
{
    /*
        Using AVAsset now runs the risk of blocking the current thread
        (the main UI thread) whilst I/O happens to populate the
        properties. It's prudent to defer our work until the properties
        we need have been loaded.
    */
    [newAsset loadValuesAsynchronouslyForKeys:AAPLPlayerViewController.assetKeysRequiredToPlay completionHandler:^{

        /*
            The asset invokes its completion handler on an arbitrary queue.
            To avoid multiple threads using our internal state at the same time
            we'll elect to use the main thread at all times, let's dispatch
            our handler to the main queue.
        */
        dispatch_async(dispatch_get_main_queue(), ^{

            if (newAsset != self.asset) {
                /*
                    self.asset has already changed! No point continuing because
                    another newAsset will come along in a moment.
                */
                return;
            }

            /*
                Test whether the values of each of the keys we need have been
                successfully loaded.
            */
            for (NSString *key in self.class.assetKeysRequiredToPlay) {
                NSError *error = nil;
                if ([newAsset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
                    NSString *message = [NSString localizedStringWithFormat:NSLocalizedString(@"error.asset_key_%@_failed.description", @"Can't use this AVAsset because one of it's keys failed to load"), key];

                    [self handleErrorWithMessage:message error:error];

                    return;
                }
            }

            // We can't play this asset.
            if (!newAsset.playable || newAsset.hasProtectedContent) {
                NSString *message = NSLocalizedString(@"error.asset_not_playable.description", @"Can't use this AVAsset because it isn't playable or has protected content");

                [self handleErrorWithMessage:message error:nil];

                return;
            }

            /*
                We can play this asset. Create a new AVPlayerItem and make it
                our player's current item.
            */
            self.playerItem = [AVPlayerItem playerItemWithAsset:newAsset];
        });
    }];
}

// MARK: - Heartbeat Timer

- (void)playHeadTimeEvent
{
    NSNumber *position = [NSNumber numberWithFloat:CMTimeGetSeconds(self.currentTime)];
    NSNumber *total = [NSNumber numberWithFloat:CMTimeGetSeconds(self.duration)];
    NSDictionary *props = @{
        @"session_id" : self.metadata[@"session_id"],
        @"asset_id" : self.metadata[@"asset_id"],
        @"pod_id" : self.metadata[@"pod_id"],
        @"title" : self.metadata[@"title"],
        @"season" : self.metadata[@"season"],
        @"episode" : self.metadata[@"episode"],
        @"genre" : self.metadata[@"genre"],
        @"program" : self.metadata[@"program"],
        @"total_length" : total,
        @"full_episode" : self.metadata[@"full_episode"],
        @"publisher" : self.metadata[@"publisher"],
        @"position" : position,
        @"channel" : self.metadata[@"channel"]
    };

    [[SEGAnalytics sharedAnalytics] track:@"Video Content Playing" properties:props];
}

- (void)startPlayheadTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playheadTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(playHeadTimeEvent) userInfo:nil repeats:YES];
    });
}

- (void)stopPlayheadTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.playheadTimer) {
            [self.playheadTimer invalidate];
            self.playheadTimer = nil;
        }
    });
}

// MARK: - IBActions

- (IBAction)playPauseButtonWasPressed:(UIButton *)sender
{
    if (self.player.rate != 1.0) {
        // not playing foward so play
        if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.duration)) {
            // at end so got back to begining
            self.currentTime = kCMTimeZero;
        }
        [self.player play];
        NSNumber *position = [NSNumber numberWithFloat:CMTimeGetSeconds(self.currentTime)];
        NSNumber *total = [NSNumber numberWithFloat:CMTimeGetSeconds(self.duration)];

        NSDictionary *props = @{
            @"session_id" : self.metadata[@"session_id"],
            @"content_asset_id" : self.metadata[@"asset_id"],
            @"pod_id" : self.metadata[@"pod_id"],
            @"title" : self.metadata[@"title"],
            @"season" : self.metadata[@"season"],
            @"episode" : self.metadata[@"episode"],
            @"genre" : self.metadata[@"genre"],
            @"program" : self.metadata[@"program"],
            @"total_length" : total,
            @"full_episode" : self.metadata[@"full_episode"],
            @"publisher" : self.metadata[@"publisher"],
            @"position" : position,
            @"channel" : self.metadata[@"channel"],
            @"video_player" : self.metadata[@"video_player"]
        };

        [[SEGAnalytics sharedAnalytics] track:@"Video Playback Started" properties:props options:@{
            @"Integrations" : @{
                @"Adobe Analytics" : @{
                    @"debug" : @YES
                }
            }
        }];
        [[SEGAnalytics sharedAnalytics] track:@"Video Content Started" properties:props];
        [self startPlayheadTimer];

    } else {
        // playing so pause
        [self.player pause];
        [self stopPlayheadTimer];
        NSNumber *position = [NSNumber numberWithFloat:CMTimeGetSeconds(self.currentTime)];
        NSNumber *total = [NSNumber numberWithFloat:CMTimeGetSeconds(self.duration)];

        [[SEGAnalytics sharedAnalytics] track:@"Video Playback Paused" properties:@{ @"session_id" : self.metadata[@"session_id"],
                                                                                     @"content_asset_id" : self.metadata[@"content_asset_id"],
                                                                                     @"video_player" : self.metadata[@"video_player"],
                                                                                     @"position" : position,
                                                                                     @"sound" : self.metadata[@"sound"],
                                                                                     @"full_screen" : self.metadata[@"full_screen"],
                                                                                     @"bitrate" : self.metadata[@"bitrate"],
                                                                                     @"total_length" : total,
                                                                                     @"livestream" : self.metadata[@"livestream"]
        }];
    }
}

- (IBAction)rewindButtonWasPressed:(UIButton *)sender
{
    self.rate = MAX(self.player.rate - 2.0, -2.0); // rewind no faster than -2.0
    [self stopPlayheadTimer];
}

- (IBAction)fastForwardButtonWasPressed:(UIButton *)sender
{
    self.rate = MIN(self.player.rate + 2.0, 2.0); // fast forward no faster than 2.0
    [self stopPlayheadTimer];
}

- (IBAction)timeSliderDidChange:(UISlider *)sender
{
    self.currentTime = CMTimeMakeWithSeconds(sender.value, 1000);
    [self.player pause];
}

- (IBAction)channelUpButtonPressed:(id)sender
{
    [self stopPlayheadTimer];
    self.playerView.playerLayer.player = nil;
    self.playerView.playerLayer.player = self.player;

    [[SEGAnalytics sharedAnalytics] screen:@"Big Buck Bunny"];

    NSURL *movieURL = [[NSBundle mainBundle] URLForResource:@"BigBuck" withExtension:@"mp4"];
    self.asset = [AVURLAsset assetWithURL:movieURL];
    self.metadata = @{
        @"session_id" : @"19238109",
        @"asset_id" : @"1234",
        @"content_asset_id" : @"1234",
        @"video_player" : @"vimeo",
        @"sound" : @100,
        @"pod_id" : @"podId2",
        @"full_screen" : @YES,
        @"bitrate" : @50,
        @"livestream" : @NO,
        @"pod_id" : @"65462",
        @"title" : @"Big Buck Bunny: Peach",
        @"season" : @"1",
        @"episode" : @"1",
        @"genre" : @"cartoon",
        @"program" : @"Big Buck Bunny",
        @"full_episode" : @"true",
        @"publisher" : @"Blender Foundation",
        @"channel" : @"Creative Commons"
    };
}

- (IBAction)channelDownButtonPressed:(id)sender
{
    [self stopPlayheadTimer];
    self.playerView.playerLayer.player = nil;
    self.playerView.playerLayer.player = self.player;

    [[SEGAnalytics sharedAnalytics] screen:@"Popeye: NearlyWeds"];

    NSURL *movieURL = [[NSBundle mainBundle] URLForResource:@"PopeyeMovie" withExtension:@"mp4"];
    self.asset = [AVURLAsset assetWithURL:movieURL];
    self.metadata = @{
        @"session_id" : @"32423905",
        @"asset_id" : @"5678",
        @"pod_id" : @"podId1",
        @"content_asset_id" : @"5678",
        @"video_player" : @"mp4",
        @"sound" : @100,
        @"full_screen" : @YES,
        @"bitrate" : @50,
        @"livestream" : @NO,
        @"pod_id" : @"65462",
        @"title" : @"Nearlyweds",
        @"season" : @"2",
        @"episode" : @"26",
        @"genre" : @"cartoon",
        @"program" : @"Popeye",
        @"full_episode" : @"true",
        @"publisher" : @"Time Warner",
        @"channel" : @"CBS",
    };
}


// MARK: - KV Observation

// Update our UI when player or player.currentItem changes
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &AAPLPlayerViewControllerKVOContext) {
        // KVO isn't for us.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if ([keyPath isEqualToString:@"asset"]) {
        if (self.asset) {
            [self asynchronouslyLoadURLAsset:self.asset];
        }
    } else if ([keyPath isEqualToString:@"player.currentItem.duration"]) {
        // Update timeSlider and enable/disable controls when duration > 0.0

        // Handle NSNull value for NSKeyValueChangeNewKey, i.e. when player.currentItem is nil
        NSValue *newDurationAsValue = change[NSKeyValueChangeNewKey];
        CMTime newDuration = [newDurationAsValue isKindOfClass:[NSValue class]] ? newDurationAsValue.CMTimeValue : kCMTimeZero;
        BOOL hasValidDuration = CMTIME_IS_NUMERIC(newDuration) && newDuration.value != 0;
        double newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0;

        self.timeSlider.maximumValue = newDurationSeconds;
        self.timeSlider.value = hasValidDuration ? CMTimeGetSeconds(self.currentTime) : 0.0;
        self.rewindButton.enabled = hasValidDuration;
        self.playPauseButton.enabled = hasValidDuration;
        self.fastForwardButton.enabled = hasValidDuration;
        self.timeSlider.enabled = hasValidDuration;
        self.startTimeLabel.enabled = hasValidDuration;
        self.durationLabel.enabled = hasValidDuration;
        int wholeMinutes = (int)trunc(newDurationSeconds / 60);
        self.durationLabel.text = [NSString stringWithFormat:@"%d:%02d", wholeMinutes, (int)trunc(newDurationSeconds) - wholeMinutes * 60];

    } else if ([keyPath isEqualToString:@"player.rate"]) {
        // Update playPauseButton image

        double newRate = [change[NSKeyValueChangeNewKey] doubleValue];
        UIImage *buttonImage = (newRate == 1.0) ? [UIImage imageNamed:@"PauseButton"] : [UIImage imageNamed:@"PlayButton"];
        [self.playPauseButton setImage:buttonImage forState:UIControlStateNormal];

    } else if ([keyPath isEqualToString:@"player.currentItem.status"]) {
        // Display an error if status becomes Failed

        // Handle NSNull value for NSKeyValueChangeNewKey, i.e. when player.currentItem is nil
        NSNumber *newStatusAsNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus newStatus = [newStatusAsNumber isKindOfClass:[NSNumber class]] ? newStatusAsNumber.integerValue : AVPlayerItemStatusUnknown;

        if (newStatus == AVPlayerItemStatusFailed) {
            [self handleErrorWithMessage:self.player.currentItem.error.localizedDescription error:self.player.currentItem.error];
        }

    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

// Trigger KVO for anyone observing our properties affected by player and player.currentItem
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"duration"]) {
        return [NSSet setWithArray:@[ @"player.currentItem.duration" ]];
    } else if ([key isEqualToString:@"currentTime"]) {
        return [NSSet setWithArray:@[ @"player.currentItem.currentTime" ]];
    } else if ([key isEqualToString:@"rate"]) {
        return [NSSet setWithArray:@[ @"player.rate" ]];
    } else {
        return [super keyPathsForValuesAffectingValueForKey:key];
    }
}

// MARK: - Error Handling

- (void)handleErrorWithMessage:(NSString *)message error:(NSError *)error
{
    NSLog(@"Error occured with message: %@, error: %@.", message, error);

    NSString *alertTitle = NSLocalizedString(@"alert.error.title", @"Alert title for errors");
    NSString *defaultAlertMesssage = NSLocalizedString(@"error.default.description", @"Default error message when no NSError provided");
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:alertTitle message:message ?: defaultAlertMesssage preferredStyle:UIAlertControllerStyleAlert];

    NSString *alertActionTitle = NSLocalizedString(@"alert.error.actions.OK", @"OK on error alert");
    UIAlertAction *action = [UIAlertAction actionWithTitle:alertActionTitle style:UIAlertActionStyleDefault handler:nil];
    [controller addAction:action];

    [self presentViewController:controller animated:YES completion:nil];
}

@end
