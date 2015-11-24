#import <UIKit/UIKit.h>
#include <opencv2/opencv.hpp>
#import <opencv2/highgui/cap_ios.h>

using namespace cv;

@interface MotionDetectionViewController : UIViewController<CvVideoCameraDelegate>
{
    Ptr<BackgroundSubtractor> substractor;
}

@property (weak, nonatomic) IBOutlet UIImageView *cameraView;
@property (nonatomic, retain) CvVideoCamera *videoCamera;

@end
