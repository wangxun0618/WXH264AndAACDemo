//
//  UIColor+Extension.m
//  WXH264Demo
//
//  Created by xun wang on 2020/3/5.
//  Copyright © 2020 LYColud. All rights reserved.
//

#import "UIColor+Extension.h"


@implementation UIColor (Extension)


+ (UIColor*)randomColor {
    
    NSInteger aRedValue = arc4random() %255;
    
    NSInteger aGreenValue = arc4random() %255;
    
    NSInteger aBlueValue = arc4random() %255;
    
    UIColor *randColor = [UIColor colorWithRed:aRedValue /255.0f green:aGreenValue /255.0f blue:aBlueValue /255.0f alpha:1.0f];
    
    return randColor;
    
}


@end
