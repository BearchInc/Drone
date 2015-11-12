//
//  DetectVideoViewController.h
//  DroneSpike
//
//  Created by Ygor Bruxel on 11/12/15.
//  Copyright © 2015 Bearch Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>

using namespace cv;

//#include "opencv2/core/core.hpp"
//#include "opencv2/highgui/highgui.hpp"

@interface DetectVideoViewController : UIViewController<CvVideoCameraDelegate>

@property (nonatomic, strong) CvVideoCamera* videoCamera;

@end
