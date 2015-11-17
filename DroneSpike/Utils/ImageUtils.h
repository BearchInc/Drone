#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "opencv2/imgproc/imgproc.hpp"

@interface ImageUtils : NSObject

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;

@end

