#include <opencv2/opencv.hpp>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "ImageUtils.h"
#import "MotionDetectionViewController.h"

@implementation MotionDetectionViewController

-(void) viewDidLoad
{
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView: self.cameraView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
//    [self.videoCamera switchCameras];
    substractor = new BackgroundSubtractorMOG2(500, 40, true);
}

- (IBAction)startDetection:(id)sender {
    [self.videoCamera start];
}

#ifdef __cplusplus
- (void) processImage:(cv::Mat &)frame
{
//    resize(frame, frame, cv::Size(frame.size().width/2, frame.size().height/2) );
    
    cvtColor(frame, frame, COLOR_BGR2RGB);
    cvtColor(frame, frame, COLOR_BGR2GRAY);
    GaussianBlur(frame, frame, cv::Size(7,7), 4, 4);

//    Canny(frame, frame, 20, 60, 3);
    
    (*substractor)(frame, frame, -1);
    
    NSLog(@"Processing frame...");
    
}
#endif

@end
