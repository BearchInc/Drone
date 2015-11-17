#import "VideoMotionViewController.h"
#import "PBJVideoPlayerController.h"
#import "EKMovieMaker.h"
#import "ImageUtils.h"
#import "opencv2/video/background_segm.hpp"
#import "opencv2/video/tracking.hpp"
#import "opencv2/imgproc/imgproc.hpp"

using namespace cv;
using namespace std;

@interface VideoMotionViewController ()



@end

@implementation VideoMotionViewController

- (void)viewDidLoad {
//    cv::
    [super viewDidLoad];

    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mov"];
    NSMutableArray *array = [self extractFrames: path];
    
    Mat result = [self meanShift: array];
    
    UIImage *resultImage = [ImageUtils UIImageFromCVMat:result];
    
    UIImageView *ygoView = [[UIImageView alloc] initWithImage:resultImage];
    
    ygoView.frame = self.view.bounds;
    [self.view addSubview:ygoView];
    
    
//    [self createVideo: array];
}

- (Mat) meanShift:(NSMutableArray *) images {
    cv::BackgroundSubtractorMOG2 *backgroundSubtractor;
    backgroundSubtractor = new cv::BackgroundSubtractorMOG2(10, 16, false);
    
    

//    for (int i = 0; i < images.count; i++) {
    
        Mat bgr, hsv, dst, hist = Mat::zeros(200, 320, CV_8UC3), backproj;
    
        // it was not a pointer in the function
        Mat imageMat = [ImageUtils cvMatFromUIImage:images[0]];
        cvtColor(imageMat, bgr, CV_BGRA2BGR);
        cvtColor(bgr, hsv, CV_BGR2HSV);
    
//    CV_BGR2HSV
    
//    return hsv;
    
    
        vector<int> vec = vector<int>(0);
        vector<float> floatVec = vector<float>(0, 180);
        float hranges[] = {0,180};
        const float* phranges = hranges;
//        vector<Mat> hsVector = vector<Mat>(hsv);
        NSLog(@"%@", @"heck");
//        calcBackProject(hsv, vec, imageMat, dst, floatVec, 1);
        NSLog(@"%d", hist.dims);
        int *channels = 0;
        calcBackProject(&hsv, 1, channels, hist, backproj, &phranges);
//        calcBackProject(&hue, 1, 0, hist, backproj, &phranges);
    
//# Setup the termination criteria, either 10 iteration or move by atleast 1 pt
//        21 term_crit = ( cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 1 )
    
    NSLog(@"%@", @"ygor");
        cv::Rect trackWindow = cv::Rect(10,20,20,20);
        RotatedRect rotatedRect = CamShift(dst, trackWindow, TermCriteria( TermCriteria::EPS | TermCriteria::COUNT, 10, 1 ));
            NSLog(@"%@", @"lagarto");
        rectangle(dst, trackWindow.tl(), trackWindow.br(), 1);
    
    return dst;
//#Draw it on image
        
//    }
}

//while(1):
//ret ,frame = cap.read()
//
//if ret == True:
//hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
//dst = cv2.calcBackProject([hsv],[0],roi_hist,[0,180],1)
//
//# apply meanshift to get the new location
//ret, track_window = cv2.meanShift(dst, track_window, term_crit)
//
//# Draw it on image
//x,y,w,h = track_window
//img2 = cv2.rectangle(frame, (x,y), (x+w,y+h), 255,2)
//cv2.imshow('img2',img2)
//
//k = cv2.waitKey(60) & 0xff
//if k == 27:
//break
//else:
//cv2.imwrite(chr(k)+".jpg",img2)
//
//else:
//break
//
//cv2.destroyAllWindows()
//cap.release()

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
