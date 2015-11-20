//
//  CamshiftUtil.m
//  DroneSpike
//
//  Created by Ygor Bruxel on 11/20/15.
//  Copyright © 2015 Bearch Inc. All rights reserved.
//

#import "CamshiftUtil.h"
#import "ImageUtils.h"
#import "opencv2/video/background_segm.hpp"
#import "opencv2/video/tracking.hpp"
#import "opencv2/imgproc/imgproc.hpp"

using namespace std;
using namespace cv;

@interface CamshiftUtil() {
    cv::Rect selection;
    int vmin;
    int vmax;
    int smin;
    Scalar redColor;
    Scalar greenColor;
    RotatedRect trackBox;
    cv::Rect trackWindow;
    cv::Rect previewsTrackWindow;
    bool hasHist;
    int hsize;
    const float* phranges;
    Mat hist, hue, mask;
}

@end

@implementation CamshiftUtil

- (instancetype)initWithSelection:(CGRect)regionOfInterest {
    self = [super init];
    if (self) {
        selection = cv::Rect(regionOfInterest.origin.x, regionOfInterest.origin.y, regionOfInterest.size.width, regionOfInterest.size.height);
        vmin = 10;
        vmax = 256;
        smin = 30;
        redColor = Scalar(255, 0, 0);
        greenColor = Scalar(0, 255, 0);
        hasHist = false;
        hsize = 16;
        
        float* hranges = new float[2]{0,180};
        phranges = hranges;
        hue = Mat::zeros(200, 320, CV_8UC3);
        mask = Mat::zeros(200, 320, CV_8UC3);
    }
    return self;
}

- (UIImage *)meanShift:(UIImage *)uiFrame {
    Mat frame, hsv = Mat::zeros(200, 320, CV_8UC3), backproj;
    
    Mat imageMat = [ImageUtils cvMatFromUIImage:uiFrame];

    cvtColor(imageMat, frame, CV_BGRA2BGR);
    cvtColor(frame, hsv, CV_BGR2HSV);
    
    inRange(hsv, Scalar(0, smin, MIN(vmin, vmax)), Scalar(180, 256, MAX(vmin, vmax)), mask);
    
    Mat kernel = getStructuringElement( MORPH_RECT,
                                       cv::Size( (2 * 1 + 1), (2 * 1 + 1)),
                                       cv::Point( 1, 1 ) );
    
    erode(hsv, hsv, kernel, cv::Point(-1,-1), 2);
    dilate(hsv, hsv, kernel, cv::Point(-1,-1), 2);

    int ch[] = {0, 0};
    hue.create(hsv.size(), hsv.depth());
    mixChannels(&hsv, 1, &hue, 1, ch, 1);
    
    if (!hasHist) {
        hasHist = true;
        
        Mat roi(hue, selection), maskroi(mask, selection);
        Mat histimg = Mat::zeros(200, 320, CV_8UC3);
        
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
//                ellipse(imageMat, trackBox, color);
    rectangle(imageMat, trackWindow.tl(), trackWindow.br(), color);
//        [resultImages addObject:;
    previewsTrackWindow = trackWindow;
//    }
    
    return [ImageUtils UIImageFromCVMat:imageMat];
}

@end

