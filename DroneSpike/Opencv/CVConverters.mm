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
    cv::Mat matrix = [ImageUtils cvMatFromUIImage:image];
    
    for(int y=0;y<matrix.rows;y++)
    {
        for(int x=0;x<matrix.cols;x++)
        {
            cv::Vec3b color = matrix.at<cv::Vec3b>(cv::Point(x,y));
            if([CVConverters isCeilingColor:color])
            {
                color[0] = 255;
                color[1] = 0;
                color[2] = 255;
                matrix.at<cv::Vec3b>(cv::Point(x,y)) = color;
            }
            
        }
    }
    
    return [ImageUtils UIImageFromCVMat:matrix];
}

/*2015-11-20 17:55:24.690 DroneSpike[2230:797497] X220 Y393: R224 G220 B213 A95
 2015-11-20 17:55:25.680 DroneSpike[2230:797497] X310 Y475: R212 G255 B223 A95
 2015-11-20 17:55:26.927 DroneSpike[2230:797497] X199 Y461: R212 G205 B255 A95
 2015-11-20 17:55:27.984 DroneSpike[2230:797497] X212 Y329: R225 G221 B214 A95
 2015-11-20 17:55:29.528 DroneSpike[2230:797497] X259 Y394: R220 G213 B255 A95
 2015-11-20 17:55:31.109 DroneSpike[2230:797497] X80 Y576: R226 G223 B215 A95
 2015-11-20 17:55:32.336 DroneSpike[2230:797497] X71 Y432: R225 G217 B255 A95
 2015-11-20 17:55:34.894 DroneSpike[2230:797497] X347 Y453: R219 G212 B255 A95*/

+ (BOOL) isCeilingColor: (cv::Vec3b)pixel {
    int ceiling1 [3] = {230, 222, 255};
    int ceiling2 [3] = {234, 230, 222};
    int ceiling3 [3] = {222, 255, 234};
    return [CVConverters equals:pixel color:ceiling1] || [CVConverters equals:pixel color:ceiling2] || [CVConverters equals:pixel color:ceiling3];
}


+ (UIImage *) colorIn: (UIImage*)image atX:(int)x andY:(int)y {
    cv::Mat matrix = [ImageUtils cvMatFromUIImage:image];
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

+ (BOOL) equals:(cv::Vec3b)pixel color:(int*)color {
    int r = (int)pixel[0];
    int g = (int)pixel[1];
    int b = (int)pixel[2];
    return r == color[0] && g == color[1] && b == color[2];
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
    enum PixelFormat dst_pixfmt = PIX_FMT_BGR24;
    
    convert_ctx = sws_getContext(w, h, src_pixfmt, w, h, dst_pixfmt, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    sws_scale(convert_ctx, frame.data, frame.linesize, 0, h, dst.data, dst.linesize);
    sws_freeContext(convert_ctx);
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