//
//  PAFFRefreshHeaderView.m
//  Pods
//
//  Created by wangliping on 17/2/4.
//
//

#import "RCTCustomRefreshHeaderView.h"
#import "Masonry.h"
#import "PAFFUIKitThemeConfig.h"
#import "DeviceMacros.h"
#import "PAFFStyle.h"
#import "PAFFUIKitMacro.h"

#define kRefreshControlHeight           60 //控件高度
#define kRefreshControlWidth            [UIScreen mainScreen].bounds.size.width
#define kFLIP_ANIMATION_DURATION        0.18f
#define kIMAGE_ANIMATION_DURATION       1.5

#define kRefreshNormalText                  @"下拉即可刷新..."
#define kRefreshPullingText                 @"松开即可刷新..."
#define kRefreshRefreshingText              @"加载中..."
#define kRefreshComplete                    @"刷新完成"
#define kRefreshArrowImg                    @"refresh_header_arrow"
#define kRefreshLoadingImg                  @"refresh_header_loading"

@interface RCTCustomRefreshHeaderView()

//下拉图片和文案容器
@property (nonatomic, strong) UIView *continerView;

@property (nonatomic, strong) UIImageView *imageView;           //下拉图片

@property (nonatomic, strong) UILabel *label;                   //描述文字

@end

@implementation RCTCustomRefreshHeaderView


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(0, 0, kRefreshControlWidth, kRefreshControlHeight)];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {

    _continerView = [[UIView alloc] init];
    [self addSubview:_continerView];
    UIImage *normalImage = [UIImage imageNamed:kRefreshArrowImg];
    _imageView = [[UIImageView alloc] initWithImage:normalImage];
    [_continerView addSubview:_imageView];
    [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_continerView);
        make.left.equalTo(_continerView).offset(PA_LENGTH_a(5));
        make.size.mas_lessThanOrEqualTo(CGSizeMake(16, 16));
    }];
    _label = [[UILabel alloc] init];
    _label.textColor = [UIColor darkGrayColor];
    _label.font = [UIFont systemFontOfSize:12];
    [_continerView addSubview:_label];
    [_label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_continerView);
        make.left.equalTo(_imageView.mas_right).offset(PA_LENGTH_a(2));
        make.right.equalTo(_continerView).mas_offset(-PA_LENGTH_a(5));
    }];
    [_continerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.height.mas_equalTo(@(kRefreshControlHeight));
    }];

}

#pragma mark -public 
- (void)onPrepare {
    _continerView.hidden = YES;
    _label.text = kRefreshNormalText;
    [_label sizeToFit];
    _imageView.image = [UIImage imageNamed:kRefreshArrowImg];
    [_imageView.layer removeAllAnimations];
    [CATransaction begin];
    [CATransaction setAnimationDuration:kFLIP_ANIMATION_DURATION];
    _imageView.layer.transform = CATransform3DIdentity;
    [CATransaction commit];
}

- (void)onPull:(BOOL)willRefresh offset:(CGFloat)offset {
    _continerView.hidden = NO;
    [self updateLabelConstraints:true];
    if (willRefresh) {
        _label.text = kRefreshPullingText;
        [_label sizeToFit];
        [CATransaction begin];
        [CATransaction setAnimationDuration:kFLIP_ANIMATION_DURATION];
        _imageView.layer.transform = CATransform3DMakeRotation(-M_PI, 0.0f, 0.0f, 1.0f);
        [CATransaction commit];
    } else {
        CGFloat rota = -offset - kRefreshControlHeight/2.0;
        if (rota < 0.00001) {
            _imageView.layer.transform = CATransform3DIdentity;
            return;
        }
        CGFloat rotation = M_PI*(rota*2 / kRefreshControlHeight);
        [CATransaction begin];
        [CATransaction setAnimationDuration:kFLIP_ANIMATION_DURATION];
        _imageView.layer.transform = CATransform3DMakeRotation(-rotation, 0.0f, 0.0f, 1.0f);
        [CATransaction commit];
    }

}

- (void)onStart {
    [self updateLabelConstraints:true];
    _continerView.hidden = NO;
    _label.text = kRefreshRefreshingText;
    _imageView.image = [UIImage imageNamed:kRefreshLoadingImg];
    CABasicAnimation *baseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    baseAnimation.fromValue = @(0);
    baseAnimation.toValue = @(2*M_PI);
    baseAnimation.repeatCount = HUGE_VALF;
    baseAnimation.autoreverses = NO;
    baseAnimation.removedOnCompletion = NO;
    baseAnimation.fillMode = kCAFillModeForwards;
    baseAnimation.duration = kIMAGE_ANIMATION_DURATION;
    CAMediaTimingFunction *function = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    baseAnimation.timingFunction = function;
    [_imageView.layer addAnimation:baseAnimation forKey:@"rotationAnimation"];

}

- (void)onComplete {
    [self updateLabelConstraints:false];
    _label.text = kRefreshComplete;
    _imageView.layer.transform = CATransform3DIdentity;
}

- (void)updateLabelConstraints:(BOOL)reset{
    if (reset) {
        _imageView.hidden = NO;
        [_label mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_imageView.mas_right).offset(PA_LENGTH_a(2));
        }];
    } else {
        _imageView.hidden = YES;
        [_label mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_imageView.mas_right).offset(-_imageView.frame.size.width);
        }];
    }
}

@end
