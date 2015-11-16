#import "CVConverters.h"
#include "libavcodec/avcodec.h"
//#include "libswscale/swscale.h"

@implementation CVConverters : NSObject

+ (cv::Mat) cvMatFromAVFrame:(AVFrame *)frame {
    AVFrame dst;
    cv::Mat m;
    
    memset(&dst, 0, sizeof(dst));

    int w = frame->width, h = frame->height;
    m = cv::Mat(h, w, CV_8UC3);
    dst.data[0] = (uint8_t *)m.data;
//    avpicture_fill( (AVPicture *)&dst, dst.data[0], PIX_FMT_BGR24, w, h);
//
//    struct SwsContext *convert_ctx=NULL;
//    enum PixelFormat src_pixfmt = (enum PixelFormat)frame->format;
//    enum PixelFormat dst_pixfmt = PIX_FMT_BGR24;
//    convert_ctx = sws_getContext(w, h, src_pixfmt, w, h, dst_pixfmt,
//                                 SWS_FAST_BILINEAR, NULL, NULL, NULL);
//    sws_scale(convert_ctx, frame->data, frame->linesize, 0, h,
//              dst.data, dst.linesize);
//    sws_freeContext(convert_ctx);
    
    return m;
}

@end