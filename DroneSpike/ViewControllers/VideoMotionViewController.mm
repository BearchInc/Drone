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
    
    Mat result = [self meanShift2: array[0]];
    
    UIImage *resultImage = [ImageUtils UIImageFromCVMat:result];
    
    UIImageView *ygoView = [[UIImageView alloc] initWithImage:resultImage];
    
    ygoView.frame = self.view.bounds;
    [self.view addSubview:ygoView];
    
    
//    [self createVideo: array];
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

- (Mat)meanShift2:(UIImage *) _image {
    
    int vmin = 10, vmax = 256, smin = 30;
    int hsize = 16;
    cv::Rect selection = cv::Rect(38, 30, 170, 280);
    float hranges[] = {0,180};
    const float* phranges = hranges;
    cv::Rect trackWindow;
    
    
    
    
    Mat frame, hsv, hue, mask, hist, histimg = Mat::zeros(200, 320, CV_8UC3), backproj;
    
    Mat imageMat = [ImageUtils cvMatFromUIImage:_image];
    cvtColor(imageMat, frame, CV_BGRA2BGR);
    cvtColor(frame, hsv, CV_BGR2HSV);
    
    
    int _vmin = vmin, _vmax = vmax;
    
    inRange(hsv, Scalar(0, smin, MIN(_vmin,_vmax)),
            Scalar(180, 256, MAX(_vmin, _vmax)), mask);
    int ch[] = {0, 0};
    hue.create(hsv.size(), hsv.depth());
    mixChannels(&hsv, 1, &hue, 1, ch, 1);
    
    Mat roi(hue, selection), maskroi(mask, selection);
    calcHist(&roi, 1, 0, maskroi, hist, 1, &hsize, &phranges);
    normalize(hist, hist, 0, 255, NORM_MINMAX);
    
    trackWindow = selection;
    
    histimg = Scalar::all(0);
    int binW = histimg.cols / hsize;
    Mat buf(1, hsize, CV_8UC3);
    for( int i = 0; i < hsize; i++ )
        buf.at<Vec3b>(i) = Vec3b(saturate_cast<uchar>(i*180./hsize), 255, 255);
    cvtColor(buf, buf, COLOR_HSV2BGR);
    
    for( int i = 0; i < hsize; i++ ) {
        int val = saturate_cast<int>(hist.at<float>(i)*histimg.rows/255);
        rectangle( histimg, cv::Point(i * binW, histimg.rows),
                  cv::Point((i + 1) * binW, histimg.rows - val),
                  Scalar(buf.at<Vec3b>(i)), -1, 8 );
    }
    
    calcBackProject(&hue, 1, 0, hist, backproj, &phranges);
    backproj &= mask;
    RotatedRect trackBox = CamShift(backproj, trackWindow,
                                    TermCriteria( TermCriteria::EPS | TermCriteria::COUNT, 10, 1 ));
    if( trackWindow.area() <= 1 ) {
        int cols = backproj.cols, rows = backproj.rows, r = (MIN(cols, rows) + 5)/6;
        trackWindow = cv::Rect(trackWindow.x - r, trackWindow.y - r,
                           trackWindow.x + r, trackWindow.y + r) &
        cv::Rect(0, 0, cols, rows);
    }
    
//    if( backprojMode )
//        cvtColor( backproj, image, COLOR_GRAY2BGR );
//    ellipse( image, trackBox, NULL, 3, 1);
    ellipse(imageMat, trackBox, Scalar(0,0,255));
    
    return imageMat;
}


- (Mat) meanShift:(NSMutableArray *) images {
    cv::BackgroundSubtractorMOG2 *backgroundSubtractor;
    backgroundSubtractor = new cv::BackgroundSubtractorMOG2(10, 16, false);
    
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



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
