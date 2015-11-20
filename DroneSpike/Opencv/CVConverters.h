#ifndef Converters_h
#define Converters_h

#import <UIKit/UIKit.h>
#import "libavutil/frame.h"

@interface CVConverters : NSObject
+ (UIImage *) imageFromAVFrame: (AVFrame) frame;
+ (UIImage *) imageWithGrayscale: (AVFrame) frame;
+ (UIImage *) thresholding: (UIImage*) image;
@end

#endif /* Converters_h */
