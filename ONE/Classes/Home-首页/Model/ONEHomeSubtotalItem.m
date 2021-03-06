//
//  ONEHomeSubtotalItem.m
//  ONE
//
//  Created by 任玉祥 on 16/4/15.
//  Copyright © 2016年 任玉祥. All rights reserved.
//

#import "ONEHomeSubtotalItem.h"

@implementation ONEHomeSubtotalItem

#define itemWidth (ONEScreenWidth * 0.5 - ONEDefaultMargin)
- (CGFloat)height
{
    if (_height) return _height;
    
    _height += itemWidth * 0.75;
    _height += [self.hp_content boundingRectWithSize:CGSizeMake(itemWidth - ONEDefaultMargin, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]} context:nil].size.height + 5;
    
    return _height;
}
@end
