#ifndef CamShift_h
#define CamShift_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CamShiftUtil : NSObject

- (instancetype)initWithBox:(CGRect)selection andImage:(UIImage *)image;
- (UIImage *)processImage:(UIImage *)image;

@end

#endif
