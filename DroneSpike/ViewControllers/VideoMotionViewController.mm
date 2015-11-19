#import "VideoMotionViewController.h"
#import "PBJVideoPlayerController.h"
#import "EKMovieMaker.h"
#import "ImageUtils.h"
#import "opencv2/video/background_segm.hpp"
#import "opencv2/video/tracking.hpp"
#import "opencv2/imgproc/imgproc.hpp"

using namespace cv;
using namespace std;

@interface VideoMotionViewController () {
    cv::Rect selection;
    BOOL hasHist;
    RotatedRect trackBox;
    int vmin;
    int vmax;
    int smin;
    UIImage *histUIImage;
}
@property (weak, nonatomic) IBOutlet UIImageView *uiImageView;
@property (weak, nonatomic) IBOutlet UIView *videoContainer;

@end

@implementation VideoMotionViewController

- (void)initValues {
    selection = cv::Rect(180, 234, 24, 25);
    hasHist = false;
    
    vmin = 10;
    vmax = 256;
    smin = 30;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initValues];
    NSArray *frames = [self extractFrames:@"test3" andExtension:@"mov"];
    NSArray *images = [self meanShift: frames];
    
    
//    UIImage *resultImage = [ImageUtils UIImageFromCVMat:result];
//    
//    UIImageView *ygoView = [[UIImageView alloc] initWithImage:resultImage];
//    
//    ygoView.frame = self.view.bounds;
//    [self.view addSubview:ygoView];
    
    
    [self createVideo: images];
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

- (NSArray *)meanShift:(NSArray *)frames {
    cv::Rect trackWindow;
    cv::Rect previewsTrackWindow;
    
    NSMutableArray *resultImages = [NSMutableArray new];
    int hsize = 16;
    float hranges[] = {0,180};
    const float* phranges = hranges;
    Mat frame, hsv, hue, mask, hist, histimg = Mat::zeros(200, 320, CV_8UC3), backproj;
    
    Scalar redColor = Scalar(255, 0, 0);
    Scalar greenColor = Scalar(0, 255, 0);
    
    for (UIImage *image in frames) {
        Mat imageMat = [ImageUtils cvMatFromUIImage:image];
        
        
        cvtColor(imageMat, frame, CV_BGRA2BGR);
        cvtColor(frame, hsv, CV_BGR2HSV);
        
        
        
        int _vmin = vmin, _vmax = vmax;
        inRange(hsv, Scalar(0, smin, MIN(_vmin,_vmax)), Scalar(180, 256, MAX(_vmin, _vmax)), mask);
        
        Mat kernel = getStructuringElement( MORPH_RECT,
                                           cv::Size( (2 * 1 + 1), (2 * 1 + 1)),
                                           cv::Point( 1, 1 ) );
        
        erode(hsv, hsv, kernel, cv::Point(-1,-1), 2);
        dilate(hsv, hsv, kernel, cv::Point(-1,-1), 2);
        
//        mask = cv2.inRange(hsv, greenLower, greenUpper)
//        mask = cv2.erode(mask, None, iterations=2)
//        mask = cv2.dilate(mask, None, iterations=2)
        
        int ch[] = {0, 0};
        hue.create(hsv.size(), hsv.depth());
        mixChannels(&hsv, 1, &hue, 1, ch, 1);
    
        if (!hasHist) {
            hasHist = true;
            
            Mat roi(hue, selection), maskroi(mask, selection);
            
            calcHist(&roi, 1, 0, maskroi, hist, 1, &hsize, &phranges);
            normalize(hist, hist, 0, 255, NORM_MINMAX);
            
            trackWindow = selection;
            rectangle(imageMat, selection.tl(), selection.br(), Scalar(0, 0, 255), 1);
            
            
            previewsTrackWindow = selection;
            
            histimg = Scalar::all(0);
            int binW = histimg.cols / hsize;
            Mat buf(1, hsize, CV_8UC3);
            for( int i = 0; i < hsize; i++ ) {
                buf.at<Vec3b>(i) = Vec3b(saturate_cast<uchar>(i*180./hsize), 255, 255);
            }
            cvtColor(buf, buf, COLOR_HSV2BGR);
            
            for( int i = 0; i < hsize; i++ ) {
                int val = saturate_cast<int>(hist.at<float>(i)*histimg.rows/255);
                
                cv::Point topLeft = cv::Point(i * binW, histimg.rows);
                cv::Point bottomRight = cv::Point((i + 1) * binW, histimg.rows - val);
                
                rectangle(histimg, topLeft, bottomRight, Scalar(buf.at<Vec3b>(i)), -1, 8 );
            }
            
            histUIImage = [ImageUtils UIImageFromCVMat: histimg];
            self.uiImageView.image = histUIImage;
        }
    
        calcBackProject(&hue, 1, 0, hist, backproj, &phranges);
        backproj &= mask;
        trackBox = CamShift(backproj, trackWindow,
                            TermCriteria( TermCriteria::EPS | TermCriteria::COUNT, 10, 1 ));
    
        if( trackWindow.area() <= 1 ) {
            int cols = backproj.cols;
            int rows = backproj.rows;
            int r = (MIN(cols, rows) + 5)/6;
            trackWindow = cv::Rect(trackWindow.x - r, trackWindow.y - r, trackWindow.x + r, trackWindow.y + r) &
            cv::Rect(0, 0, cols, rows);
        }
    
        //    if( backprojMode )
        //        cvtColor( backproj, image, COLOR_GRAY2BGR );
        
        Scalar color = (previewsTrackWindow.area() * 1.1) < trackWindow.area() ? redColor : greenColor;
//        ellipse(imageMat, trackBox, color);
        rectangle(imageMat, trackWindow.tl(), trackWindow.br(), color);
        [resultImages addObject:[ImageUtils UIImageFromCVMat:imageMat]];
        previewsTrackWindow = trackWindow;
    }

    return resultImages;
}
@end
