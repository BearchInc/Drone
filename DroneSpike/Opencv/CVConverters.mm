#import "CVConverters.h"
#import "ImageUtils.h"
#import <opencv2/core/core.hpp>
#import <opencv2/imgproc/imgproc.hpp>

extern "C" {
#import "libavcodec/avcodec.h"
#import "libswscale/swscale.h"
}

@implementation CVConverters : NSObject


+ (UIImage *) imageWithGrayscale: (AVFrame) frame {
    
    cv::Mat image = [CVConverters cvMatFromAVFrame: frame];
    cv::Mat image_copy;
    
    //    cv::cv
    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    // invert image
    bitwise_not(image_copy, image_copy);
    cvtColor(image_copy, image, CV_BGR2BGRA);
    
    return [CVConverters imageFromCVMat: image];
}

+ (UIImage *) markElements: (UIImage*) image {
    cv::Mat originalImage = [ImageUtils cvMatFromUIImage:image];
    cv::Mat buildingImage = originalImage.clone();
    cv::cvtColor(originalImage, buildingImage, CV_BGR2GRAY);
    cv::Mat ceilingImage = buildingImage.clone();
    
    cv::Vec3b blackColor = {0, 0, 0};
    for(int y=0;y<buildingImage.rows;y++)
    {
        for(int x=0;x<buildingImage.cols;x++)
        {
            cv::Vec3b color = buildingImage.at<cv::Vec3b>(cv::Point(x,y));
            if([CVConverters isCeilingColor:color])
            {
                ceilingImage.at<cv::Vec3b>(cv::Point(x,y)) = blackColor;
            } else if([CVConverters isBuildingColor:color]) {
                buildingImage.at<cv::Vec3b>(cv::Point(x,y)) = blackColor;
            }
        }
    }
//    return [ImageUtils UIImageFromCVMat:matrix];
    cv::threshold(buildingImage, buildingImage, 1, 255, CV_THRESH_BINARY);
    cv::threshold(ceilingImage, ceilingImage, 1, 255, CV_THRESH_BINARY);
    std::vector<std::vector<cv::Point> > buildingContours;
    std::vector<std::vector<cv::Point> > ceilingContours;
    
    cv::findContours(buildingImage, buildingContours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE );
    cv::findContours(ceilingImage, ceilingContours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE );
    
    cv::Scalar ceilingColor = cv::Scalar(255, 0, 0);
    cv::Scalar buildingColor = cv::Scalar(0, 0, 255);
    for (size_t idx = 0; idx < buildingContours.size(); idx++) {
        cv::drawContours(originalImage, buildingContours, idx, buildingColor);
    }
    for (size_t idx = 0; idx < ceilingContours.size(); idx++) {
        cv::drawContours(originalImage, ceilingContours, idx, ceilingColor);
    }
    
    return [ImageUtils UIImageFromCVMat:originalImage];
}


+ (BOOL) isCeilingColor: (cv::Vec3b)pixel {
    cv::Vec3b ceilingColor = {228, 228, 228};
    return [CVConverters equals:pixel color:ceilingColor];
}

+ (BOOL) isBuildingColor: (cv::Vec3b)pixel {
    return (pixel[0] >= 198 && pixel[0] <= 230) &&
            (pixel[1] >= 198 && pixel[1] <= 230) &&
            (pixel[2] >= 198 && pixel[2] <= 230);
}

+ (UIImage *) colorIn: (UIImage*)image atX:(int)x andY:(int)y {
    cv::Mat matrix = [ImageUtils cvMatFromUIImage:image];
    cv::cvtColor(matrix, matrix, CV_BGR2GRAY);

    cv::Vec3b color = matrix.at<cv::Vec3b>(cv::Point(x,y));
    NSLog(@"X%d Y%d: R%d G%d B%d A%d", x, y, (int)color[0], (int)color[1], (int)color[2], (int)color[3]);
    color[0] = 0; color[1] = 255; color[2] = 255;
    // mark points around clicked are
    for(int i=-5; i<5; i++) {
        for(int j=-5; j<5; j++) {
            matrix.at<cv::Vec3b>(cv::Point(x+i,y+j)) = color;
        }
    }
    return [ImageUtils UIImageFromCVMat:matrix];
}

+ (BOOL) equals:(cv::Vec3b)pixel color:(cv::Vec3b)color {
    return pixel[0] == color[0] && pixel[1] == color[1] && pixel[2] == color[2];
}


+ (cv::Mat) cvMatFromAVFrame: (AVFrame) frame {
    AVFrame dst;
    cv::Mat m;
    
    memset(&dst, 0, sizeof(dst));
    
    int w = frame.width, h = frame.height;
    m = cv::Mat(h, w, CV_8UC3);
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
    cv::Mat m = [CVConverters cvMatFromAVFrame: frame];
    return [CVConverters imageFromCVMat: m];
}


+ (UIImage *) imageFromCVMat: (cv::Mat) cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
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