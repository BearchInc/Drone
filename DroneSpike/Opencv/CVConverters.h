#ifndef Converters_h
#define Converters_h

#import <UIKit/UIKit.h>
#import "libavutil/frame.h"

@interface CVConverters : NSObject
+ (UIImage *) imageFromAVFrame: (AVFrame) frame;
+ (UIImage *) imageWithGrayscale: (AVFrame) frame;
+ (UIImage *) markElements: (UIImage*) image;
+ (UIImage *) colorIn: (UIImage*)image atX:(int)x andY:(int)y;

@end

#endif /* Converters_h */
