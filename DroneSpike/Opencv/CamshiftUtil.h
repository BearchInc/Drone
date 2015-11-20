//
//  CamshiftUtil.h
//  DroneSpike
//
//  Created by Ygor Bruxel on 11/20/15.
//  Copyright © 2015 Bearch Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CamshiftUtil : NSObject

- (instancetype)initWithSelection:(CGRect)selection;
- (NSArray *)meanShift:(NSArray *)frames;

@end
