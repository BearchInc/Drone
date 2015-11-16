#ifndef Converters_h
#define Converters_h

#import <opencv2/core/core.hpp>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include "libavutil/frame.h"

@interface CVConverters : NSObject
+ (cv::Mat) cvMatFromAVFrame: (AVFrame *) frame;
@end

#endif /* Converters_h */
