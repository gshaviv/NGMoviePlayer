#import "NGMoviePlayerView.h"
#import "NGMoviePlayerLayerView.h"
#import "NGMoviePlayerControlView.h"


#define kNGFadeDuration             0.4


static char playerLayerReadyForDisplayContext;


@interface NGMoviePlayerView () {
    BOOL _statusBarVisible;
    BOOL _readyForDisplayTriggered;
}

@property (nonatomic, strong, readwrite) NGMoviePlayerControlView *controlsView;  // re-defined as read/write
@property (nonatomic, strong) NGMoviePlayerLayerView *playerLayerView;
@property (nonatomic, strong) UIView *placeholderView;
@property (nonatomic, strong) UIWindow *externalWindow;

- (void)setup;
- (void)updateUI;

@end


@implementation NGMoviePlayerView

@dynamic playerLayer;

@synthesize controlsView = _controlsView;
@synthesize controlsVisible = _controlsVisible;
@synthesize playerLayerView = _playerLayerView;
@synthesize placeholderView = _placeholderView;
@synthesize externalWindow = _externalWindow;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor blackColor];
        
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self setup];
    }
    
    return self;
}

- (void)dealloc {
    [self.playerLayer removeObserver:self forKeyPath:@"readyForDisplay"];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - KVO
////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &playerLayerReadyForDisplayContext) {
        BOOL ready = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        if (ready && !_readyForDisplayTriggered) {
            _readyForDisplayTriggered = YES;
            
            // fade out placeholderView
            [UIView animateWithDuration:1.
                             animations:^{
                                 self.placeholderView.alpha = 0.f;
                             } completion:^(BOOL finished) {
                                 [self.placeholderView removeFromSuperview];
                                 self.placeholderView = nil;
                             }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

/*- (void)layoutSubviews {
    [super layoutSubviews];
    
    
}*/

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerView Properties
////////////////////////////////////////////////////////////////////////

- (void)setControlsVisible:(BOOL)controlsVisible {
    [self setControlsVisible:controlsVisible animated:NO];
}

- (void)setControlsVisible:(BOOL)controlsVisible animated:(BOOL)animated {
    if (controlsVisible != _controlsVisible) {
        [self willChangeValueForKey:@"controlsVisible"];
        _controlsVisible = controlsVisible;
        [self didChangeValueForKey:@"controlsVisible"];
        
        if (controlsVisible) {
            [self bringSubviewToFront:self.controlsView];
        }
        
        [UIView animateWithDuration:animated ? kNGFadeDuration : 0.
                              delay:0.
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{        
                             self.controlsView.alpha = controlsVisible ? 1.f : 0.f;
                         } completion:nil];
        
        if (self.controlStyle == NGMoviePlayerControlStyleFullscreen) {
            [[UIApplication sharedApplication] setStatusBarHidden:(!controlsVisible) withAnimation:UIStatusBarAnimationFade];
        }
    }
}

- (void)setControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle != self.controlsView.controlStyle) {
        [self willChangeValueForKey:@"controlStyle"];
        self.controlsView.controlStyle = controlStyle;
        [self didChangeValueForKey:@"controlStyle"];
        
        // hide status bar in fullscreen, restore to previous state
        if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:!_statusBarVisible withAnimation:UIStatusBarAnimationFade];
        }
    }
}

- (NGMoviePlayerControlStyle)controlStyle {
    return self.controlsView.controlStyle;
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self.playerLayerView layer];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerView UI Update
////////////////////////////////////////////////////////////////////////

- (void)updateWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    [self.controlsView updateScrubberWithCurrentTime:(NSInteger)ceilf(currentTime) duration:(NSInteger)ceilf(duration)];
}

- (void)updateWithPlaybackStatus:(BOOL)isPlaying {
    [self.controlsView updateButtonsWithPlaybackStatus:isPlaying];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)setup {
    self.controlStyle = NGMoviePlayerControlStyleInline;
    _controlsVisible = NO;
    _statusBarVisible = ![UIApplication sharedApplication].statusBarHidden;
    _readyForDisplayTriggered = NO;
    
    // Placeholder
    _placeholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/playerBackground"]];
    _placeholderView.frame = self.bounds;
    _placeholderView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_placeholderView];
    
    // Controls
    _controlsView = [[NGMoviePlayerControlView alloc] initWithFrame:self.bounds];
    [self addSubview:_controlsView];
    
    // Player Layer
    _playerLayerView = [[NGMoviePlayerLayerView alloc] initWithFrame:self.bounds];
    _playerLayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_playerLayerView];
    
    [self.playerLayer addObserver:self
                       forKeyPath:@"readyForDisplay"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:&playerLayerReadyForDisplayContext];
}

@end
