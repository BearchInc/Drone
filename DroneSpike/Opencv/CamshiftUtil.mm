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
	Mat hist, hue, mask, hsv;
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
        hue = Mat::zeros(180, 320, CV_8UC3);
        mask = Mat::zeros(180, 320, CV_8UC3);
		

    }
    return self;
}

- (UIImage *)camshift:(UIImage *)uiFrame {
	Mat imageMat = [ImageUtils cvMatFromUIImage:uiFrame];
	Mat frame = Mat::zeros(180, 320, CV_8UC3), backproj;
	hsv = Mat::zeros(180, 320, CV_8UC3);
	cvtColor(imageMat, frame, CV_BGRA2BGR);
	cvtColor(frame, hsv, CV_BGR2HSV);
	
	if (!hasHist) {
		hasHist = YES;
	
		inRange(hsv, Scalar(0, smin, MIN(vmin, vmax)), Scalar(180, 256, MAX(vmin, vmax)), mask);
		
		int ch[] = {0, 0};
		hue.create(hsv.size(), hsv.depth());
		mixChannels(&hsv, 1, &hue, 1, ch, 1);
		
		Mat roi(hue, selection), maskroi(mask, selection);
		
		
		
		calcHist(&roi, 1, 0, maskroi, hist, 1, &hsize, &phranges);
		normalize(hist, hist, 0, 255, NORM_MINMAX);
		
		trackWindow = selection;
		previewsTrackWindow = selection;
	}
	

	calcBackProject(&hue, 1, 0, hist, backproj, &phranges);
	
	backproj &= mask;
	trackBox = CamShift(backproj, trackWindow, TermCriteria( TermCriteria::EPS | TermCriteria::COUNT, 10, 1 ));

	Scalar color = (previewsTrackWindow.area() * 1.1) < trackWindow.area() ? redColor : greenColor;
	previewsTrackWindow = trackWindow;
	rectangle(imageMat, trackBox.boundingRect().tl(), trackBox.boundingRect().br(), color);
	rectangle(imageMat, selection.tl(), selection.br(), Scalar(0, 0, 255), 2);
	
	return [ImageUtils UIImageFromCVMat:imageMat];
}

//6 # take first frame of the video
//7 ret,frame = cap.read()
//8
//9 # setup initial location of window
//10 r,h,c,w = 250,90,400,125  # simply hardcoded the values
//11 track_window = (c,r,w,h)
//12
//13 # set up the ROI for tracking
//14 roi = frame[r:r+h, c:c+w]
//15 hsv_roi =  cv2.cvtColor(roi, cv2.COLOR_BGR2HSV)
//16 mask = cv2.inRange(hsv_roi, np.array((0., 60.,32.)), np.array((180.,255.,255.)))
//17 roi_hist = cv2.calcHist([hsv_roi],[0],mask,[180],[0,180])
//18 cv2.normalize(roi_hist,roi_hist,0,255,cv2.NORM_MINMAX)
//19
//20 # Setup the termination criteria, either 10 iteration or move by atleast 1 pt
//21 term_crit = ( cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 1 )
//22
//23 while(1):
//24     ret ,frame = cap.read()
//25
//26     if ret == True:
//27         hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
//28         dst = cv2.calcBackProject([hsv],[0],roi_hist,[0,180],1)
//29
//30         # apply meanshift to get the new location
//31         ret, track_window = cv2.CamShift(dst, track_window, term_crit)
//32
//33         # Draw it on image
//34         pts = cv2.boxPoints(ret)
//35         pts = np.int0(pts)
//36         img2 = cv2.polylines(frame,[pts],True, 255,2)
//37         cv2.imshow('img2',img2)
//38
//39         k = cv2.waitKey(60) & 0xff
//40         if k == 27:
//41             break
//42         else:
//43             cv2.imwrite(chr(k)+".jpg",img2)
//44
//45     else:
//46         break
//47
//48 cv2.destroyAllWindows()
//49 cap.release()

- (UIImage *)meanShift:(UIImage *)uiFrame {
	Mat imageMat = [ImageUtils cvMatFromUIImage:uiFrame];
	Mat frame, hsv = Mat::zeros(180, 320, CV_8UC3), backproj;
	
	NSLog(@"Image wxh: %f x %f", uiFrame.size.width, uiFrame.size.height);
	
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
		

        calcHist(&roi, 1, 0, maskroi, hist, 1, &hsize, &phranges);
        normalize(hist, hist, 0, 255, NORM_MINMAX);
        
        trackWindow = selection;
        rectangle(imageMat, selection.tl(), selection.br(), Scalar(0, 0, 255), 1);
        
        
        previewsTrackWindow = selection;

		Mat histimg = Mat::zeros(200, 320, CV_8UC3);
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
    trackBox = CamShift(backproj, trackWindow, TermCriteria( TermCriteria::EPS | TermCriteria::COUNT, 10, 1 ));
    
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
//	ellipse(imageMat, trackBox, color);
    rectangle(imageMat, trackWindow.tl(), trackWindow.br(), color);
//        [resultImages addObject:;
    previewsTrackWindow = trackWindow;
//    }
	rectangle(imageMat, selection.tl(), selection.br(), Scalar(0, 0, 255), 2);
    
    return [ImageUtils UIImageFromCVMat:imageMat];
}

@end

