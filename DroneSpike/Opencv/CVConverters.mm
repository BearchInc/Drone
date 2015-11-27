#import "CVConverters.h"
#import "ImageUtils.h"
#import <opencv2/core/core.hpp>
#import <opencv2/imgproc/imgproc.hpp>

extern "C" {
#import "libavcodec/avcodec.h"
#import "libswscale/swscale.h"
}

using namespace cv;
using namespace std;

@implementation CVConverters : NSObject

Vec3b blackColor = {0, 0, 0};
Vec3b whiteColor = {255, 255, 255};
Scalar white = Scalar(255,255,255);

+ (UIImage *) imageWithGrayscale: (AVFrame) frame {
    
    Mat image = [CVConverters cvMatFromAVFrame: frame];
    Mat image_copy;
    
    //    cv
    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    // invert image
    bitwise_not(image_copy, image_copy);
    cvtColor(image_copy, image, CV_BGR2BGRA);
    
    return [CVConverters imageFromCVMat: image];
}

+ (UIImage *) measureHeights: (UIImage*) image {
    Mat originalImage = [ImageUtils cvMatFromUIImage:image];
    Mat matrix = originalImage.clone();
    cvtColor(originalImage, matrix, CV_BGR2GRAY);
    
    for(int y=0;y<matrix.rows;y++) {
        for(int x=0;x<matrix.cols;x++) {
            
            Vec3b color = matrix.at<Vec3b>(cv::Point(x,y));
            if([CVConverters isCeilingColor:color]) {

            } else if([CVConverters isBuildingColor:color]) {
                matrix.at<Vec3b>(cv::Point(x,y)) = Vec3b(0, 0, 0);
            }
        }
    }

    int topbarSize = 60;
    int delta = 45;
    std::vector<Point2f> corners;
    corners.push_back(Point2f(94, 46));
    corners.push_back(Point2f(321, 46));
    corners.push_back(Point2f(403, 733));
    corners.push_back(Point2f(16, 733));
    
    Mat quad = matrix.clone();
    std::vector<Point2f> quad_pts;

//    quad_pts.push_back(Point2f(0, 0));
//    quad_pts.push_back(Point2f(quad.cols, 0));
//    quad_pts.push_back(Point2f(quad.cols, quad.rows));
//    quad_pts.push_back(Point2f(0, quad.rows));
//    
//    Mat transmtx = getPerspectiveTransform(corners, quad_pts);
//    warpPerspective(matrix, quad, transmtx, quad.size());

    int x = quad.cols/2;
    BOOL dashing = false;
    int length = 0;
    int x1 = 0, x2 = 0;
    int y1 = 0, y2 = 0;
    for(int y=0;y<quad.rows;y++) {
        Vec3b color = quad.at<Vec3b>(cv::Point(x,y));
        if([CVConverters equals:color color:blackColor]) {
            if(dashing == false) {
                x1 = x;
                y1 = y;
                dashing = true;
            }
            length++;
            quad.at<Vec3b>(cv::Point(x,y)) = Vec3b(255, 255, 255);
        } else {
            if(dashing) {
                float d = (y+y1)/2.0;
                float size = (float)length*0.8;
//                float meters = size + size*0.04*fabs(size*((quad.rows/2.0)-d)/(float)quad.rows);
                dashing = false;
        
                cv::line(originalImage, cv::Point(x1, y1), cv::Point(x,y), Scalar(255,0,0));
                putText(originalImage, std::to_string(size), cv::Point(x+10,y-length/2),
                        FONT_HERSHEY_COMPLEX_SMALL, 0.8, cvScalar(255,0,0));
                length = 0;
            }
        }
    }


    return [ImageUtils UIImageFromCVMat:originalImage];
}

void sortCorners(std::vector<Point2f>& corners, Point2f center)
{
    std::vector<Point2f> top, bot;
    
    for (int i = 0; i < corners.size(); i++)
    {
        if (corners[i].y < center.y)
            top.push_back(corners[i]);
        else
            bot.push_back(corners[i]);
    }
    
    Point2f tl = top[0].x > top[1].x ? top[1] : top[0];
    Point2f tr = top[0].x > top[1].x ? top[0] : top[1];
    Point2f bl = bot[0].x > bot[1].x ? bot[1] : bot[0];
    Point2f br = bot[0].x > bot[1].x ? bot[0] : bot[1];
    
    corners.clear();
    corners.push_back(tl);
    corners.push_back(tr);
    corners.push_back(br);
    corners.push_back(bl);
}



+ (int) findEndOfLineForPointX:(int)x Y:(int)y image:(Mat)image {
//    int originalX = x;
//    int originalY = y;
    Vec3b blackColor = Vec3b(0,0,0);
    while(y < image.rows-1) {
        Vec3b a1 = image.at<Vec3b>(cv::Point(x-1,y+1));
        Vec3b a2 = image.at<Vec3b>(cv::Point(x,y+1));
        Vec3b a3 = image.at<Vec3b>(cv::Point(x+1,y+1));
        if([CVConverters equals:a1 color:blackColor]) {
            x--;
            y++;
        } else if([CVConverters equals:a2 color:blackColor]) {
            y++;
        } else if([CVConverters equals:a3 color:blackColor]) {
            x++;
            y++;
        } else {
            NSLog(@"%d", y);
            return 0;
        }
    }
    return 0;
}

+ (BOOL) isCeilingColor: (Vec3b)pixel {
    Vec3b ceilingColor = {228, 228, 228};
    return [CVConverters equals:pixel color:ceilingColor];
}

+ (BOOL) isBuildingColor: (Vec3b)pixel {
    return (pixel[0] >= 198 && pixel[0] <= 230) &&
            (pixel[1] >= 198 && pixel[1] <= 230) &&
            (pixel[2] >= 198 && pixel[2] <= 230);
}

+ (UIImage *) colorIn: (UIImage*)image atX:(int)x andY:(int)y {
    Mat matrix = [ImageUtils cvMatFromUIImage:image];
    cvtColor(matrix, matrix, CV_BGR2GRAY);

    Vec3b color = matrix.at<Vec3b>(cv::Point(x,y));
    NSLog(@"X%d Y%d: R%d G%d B%d A%d", x, y, (int)color[0], (int)color[1], (int)color[2], (int)color[3]);
    color[0] = 0; color[1] = 255; color[2] = 255;
    // mark points around clicked are
    for(int i=-5; i<5; i++) {
        for(int j=-5; j<5; j++) {
            matrix.at<Vec3b>(cv::Point(x+i,y+j)) = color;
        }
    }
    return [ImageUtils UIImageFromCVMat:matrix];
}

+ (BOOL) equals:(Vec3b)pixel color:(Vec3b)color {
    return pixel[0] == color[0] && pixel[1] == color[1] && pixel[2] == color[2];
}


+ (Mat) cvMatFromAVFrame: (AVFrame) frame {
    AVFrame dst;
    Mat m;
    
    memset(&dst, 0, sizeof(dst));
    
    int w = frame.width, h = frame.height;
    m = Mat(h, w, CV_8UC3);
    dst.data[0] = (uint8_t *)m.data;
    avpicture_fill( (AVPicture *)&dst, dst.data[0], PIX_FMT_BGR24, w, h);
    
    struct SwsContext *convert_ctx=NULL;
    enum PixelFormat src_pixfmt = (enum PixelFormat)frame.format;
    enum PixelFormat dst_pixfmt = PIX_FMT_RGB24;
    
    convert_ctx = sws_getContext(w, h, src_pixfmt, w, h, dst_pixfmt, SWS_FAST_BILINEAR, NULL, NULL, NULL);
	sws_scale(convert_ctx, frame.data, frame.linesize, 0, h, dst.data, dst.linesize);
    sws_freeContext(convert_ctx);
	
	cv::resize(m, m, cv::Size(320, 180));
    return m;
}

+ (UIImage *) imageFromAVFrame: (AVFrame) frame {
    Mat m = [CVConverters cvMatFromAVFrame: frame];
    return [CVConverters imageFromCVMat: m];
}


+ (UIImage *) imageFromCVMat: (Mat) cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end