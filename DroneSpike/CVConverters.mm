#import "CVConverters.h"
#import <opencv2/core/core.hpp>

extern "C" {
#import "libavcodec/avcodec.h"
#import "libswscale/swscale.h"
}

@implementation CVConverters : NSObject

+ (UIImage *) imageFromAVFrame: (AVFrame) frame {
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
    
    if (w != 0 || h != 0) {
        NSLog(@"######## w=%d, h=%d, src_pixfmt=%d, dst_pixfmt=%d", w, h, src_pixfmt, dst_pixfmt);
        convert_ctx = sws_getContext(w, h, src_pixfmt, w, h, dst_pixfmt, SWS_FAST_BILINEAR, NULL, NULL, NULL);
        sws_scale(convert_ctx, frame.data, frame.linesize, 0, h, dst.data, dst.linesize);
        sws_freeContext(convert_ctx);
    }
    
    
    return [CVConverters UIImageFromCVMat: m];
}


+ (UIImage *) UIImageFromCVMat: (cv::Mat) cvMat
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