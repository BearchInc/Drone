#import "VideoMotionViewController.h"
#import "PBJVideoPlayerController.h"
#import "EKMovieMaker.h"

@interface VideoMotionViewController ()

@end

@implementation VideoMotionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mov"];
    
    NSMutableArray *array = [self extractFrames: path];
    [self createVideo: array];
}

- (void) createVideo:(NSMutableArray *) images {
    
    EKMovieMaker *movieMaker    = [[EKMovieMaker alloc] initWithImages: images];
    movieMaker.movieSize       = CGSizeMake(320.0f, 568.0f);
    movieMaker.frameDuration   = .1f;
    
    [movieMaker createMovieWithCompletion:^(NSString *moviePath) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            PBJVideoPlayerController *videoPlayerController = [[PBJVideoPlayerController alloc] init];
            //    videoPlayerController.delegate = self;
            videoPlayerController.view.frame = self.view.bounds;
            
            videoPlayerController.videoPath = moviePath;
            
            [self addChildViewController:videoPlayerController];
            [self.view addSubview:videoPlayerController.view];
            [videoPlayerController didMoveToParentViewController:self];
        });
    }];
}

- (NSMutableArray *)extractFrames:(NSString *)filepath
{
    NSMutableArray *uiImages = [NSMutableArray new];
    
    AVURLAsset *movieAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filepath] options:nil];
    
    CMTime totalDuration = movieAsset.duration;
    
    
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
    assetImageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    assetImageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    assetImageGenerator.appliesPreferredTrackTransform = YES;

    int currentFrame = 2;
    
    while (currentFrame < totalDuration.value - 200) {
        CGImageRef frameRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(currentFrame, totalDuration.timescale) actualTime:nil error:nil];
        
        UIImage *currentImage = [[UIImage alloc] initWithCGImage:frameRef];
        currentFrame += 60;
        [uiImages addObject: currentImage];
        
        // Create path.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *name = [NSString stringWithFormat:@"Image %d.png", currentFrame];
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:name];
        
        // Save image.
        [UIImagePNGRepresentation(currentImage) writeToFile:filePath atomically:YES];
        NSLog(@"%@", filePath);
    }
    

    return uiImages;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
