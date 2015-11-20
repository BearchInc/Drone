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

+ (UIImage *) thresholding: (UIImage*) image {
    cv::Mat matrix = [ImageUtils cvMatFromUIImage:image];
    cv::Scalar ceilingColor = CV_RGB(234, 230, 222);
    
    for(int y=0;y<matrix.rows;y++)
    {
        for(int x=0;x<matrix.cols;x++)
        {
            cv::Vec3b color = matrix.at<cv::Vec3b>(cv::Point(x,y));
            if([CVConverters isCeilingColor:color])
            {
                color[0] = 255;
                color[1] = 255;
                color[2] = 0;
                matrix.at<cv::Vec3b>(cv::Point(x,y)) = color;
            }
            
        }
    }
    
    return [ImageUtils UIImageFromCVMat:matrix];
}

+ (BOOL) isCeilingColor: (cv::Vec3b)pixel {
    int r = (int)pixel[0];
    int g = (int)pixel[1];
    int b = (int)pixel[2];
    return (r >= 233 && r <= 235) && (g >= 229 && g <= 231) && (b >= 221 && b <= 223);
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