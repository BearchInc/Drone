//
//  DetectVideoViewController.m
//  DroneSpike
//
//  Created by Ygor Bruxel on 11/12/15.
//  Copyright © 2015 Bearch Inc. All rights reserved.
//

#import "DetectVideoViewController.h"
#import "opencv2/imgproc/imgproc.hpp"
//#import <UIKit/UIKit.h>
//#import <Accelerate/Accelerate.h>
//#import <AVFoundation/AVFoundation.h>
//#import <ImageIO/ImageIO.h>
//#include "opencv2/core/core.hpp"


@interface DetectVideoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *videoView;

@end

@implementation DetectVideoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:_videoView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)startProcessing:(id)sender {
    [self.videoCamera start];
}


#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(cv::Mat &)image {
    // Do some OpenCV stuff with the image
    Mat image_copy;
//    cv::cv
    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    // invert image
    bitwise_not(image_copy, image_copy);
    cvtColor(image_copy, image, CV_BGR2BGRA);
    
}
#endif

@end
