//
//  PPPBlurryImageView.h
//  PPPBlurryImageView
//
//  Created by Yunfeng Liang on 15/7/22.
//
//

#import <GLKit/GLKit.h>

@interface PPPBlurryImageView : GLKView

@property (nonatomic) UIImage *image;
@property (nonatomic) CGFloat blur;
@property (nonatomic) NSUInteger beginTextureLevel;
@property (nonatomic) CGFloat textureLevelDecrease;

@end
