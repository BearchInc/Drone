#import "VideoMotionViewController.h"
#import "PBJVideoPlayerController.h"
#import "EKMovieMaker.h"
#import "ImageUtils.h"
#import "opencv2/video/background_segm.hpp"
#import "opencv2/video/tracking.hpp"
#import "opencv2/imgproc/imgproc.hpp"
#import "CamshiftUtil.h"

using namespace cv;
using namespace std;

@interface VideoMotionViewController () {
    UIImage *histUIImage;
}
@property (weak, nonatomic) IBOutlet UIImageView *uiImageView;
@property (weak, nonatomic) IBOutlet UIView *videoContainer;

@end

@implementation VideoMotionViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *frames = [self extractFrames:@"test3" andExtension:@"mov"];
    NSMutableArray *matFrames = [NSMutableArray new];

    CGRect selection = CGRectMake(180, 234, 24, 25);
    CamshiftUtil *camshiftUtil = [[CamshiftUtil alloc] initWithSelection: selection];
    
    for (UIImage *frame in frames) {
        UIImage *resultImage = [camshiftUtil meanShift:frame];
        [matFrames addObject: resultImage];
    }
    
//    UIImage *resultImage = [ImageUtils UIImageFromCVMat:result];
//    
//    UIImageView *ygoView = [[UIImageView alloc] initWithImage:resultImage];
//    
//    ygoView.frame = self.view.bounds;
//    [self.view addSubview:ygoView];
    
    [self createVideo: matFrames];
}


- (void) createVideo:(NSArray *) images {
    
    EKMovieMaker *movieMaker    = [[EKMovieMaker alloc] initWithImages: images];
    movieMaker.movieSize       = CGSizeMake(320.0f, 568.0f);
    movieMaker.frameDuration   = .05f;
    
    [movieMaker createMovieWithCompletion:^(NSString *moviePath) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            PBJVideoPlayerController *videoPlayerController = [[PBJVideoPlayerController alloc] init];
            //    videoPlayerController.delegate = self;
            videoPlayerController.view.frame = self.view.bounds;
            
            videoPlayerController.videoPath = moviePath;
            
            [self addChildViewController:videoPlayerController];
            [self.videoContainer addSubview:videoPlayerController.view];
            [videoPlayerController didMoveToParentViewController:self];
        });
    }];
}

- (NSMutableArray *)extractFrames:(NSString *)fileName andExtension:(NSString *)extension {
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
    NSMutableArray *uiImages = [NSMutableArray new];
    
    AVURLAsset *movieAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    
    CMTime totalDuration = movieAsset.duration;
    
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
    assetImageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    assetImageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    assetImageGenerator.appliesPreferredTrackTransform = YES;

    int currentFrame = 2;
    
    while (currentFrame < totalDuration.value - 200) {
        CGImageRef frameRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(currentFrame, totalDuration.timescale) actualTime:nil error:nil];
        
        UIImage *currentImage = [[UIImage alloc] initWithCGImage:frameRef];
        currentFrame += 30;
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
@end
