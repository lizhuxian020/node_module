//
//  PAFFRefreshControl.m
//  TestRefresh
//
//  Created by wangliping on 17/1/5.
//  Copyright © 2017年 PingAn. All rights reserved.
//

#import "RCTCustomRefreshControl.h"
#import "RCTCustomBaseRefreshHeaderView.h"
#import "RCTCustomRefreshHeaderView.h"


#define kRefreshThresholdMulti    1.0   //阀值倍数量
#define kRefreshTimeout           8.0   //刷新超时

typedef NS_ENUM(NSInteger, PAFFRefreshState) {
    PAFFRefreshStateNormal = 1,     //普通状态
    PAFFRefreshStatePulling,        //释放刷新
    PAFFRefreshStateRefreshing,     //刷新状态
    PAFFRefreshStateComplete        //完成状态
};

@interface RCTCustomRefreshControl()

@property (nonatomic, assign) CGFloat originalOffsetY;//初始偏移量，ScrollView可能设置ContentInset 计算偏移是会除去这一部分
@property (nonatomic, strong) RCTCustomBaseRefreshHeaderView *headerView;//自定义头部
@property (nonatomic, assign) id refreshTarget;  //
@property (nonatomic, assign) SEL refreshAction; //
@property (nonatomic, assign) PAFFRefreshState refreshState;//下拉状态
@property (nonatomic, weak) UIScrollView *superScrollView;//控件父视图为ScrollView及子视图
@property (nonatomic, assign) CGFloat refreshHeaderThreshold;   //触发下拉刷新的阀值
@property (nonatomic, assign) CGFloat refreshHeaderHeight;      //下拉刷新头部高度
@property (nonatomic, assign) BOOL isHandler; //是否手势触发刷新
@property (nonatomic, assign) BOOL isRefreshing;
@end

@implementation RCTCustomRefreshControl


static Class _classz = NULL;

+ (void)setHeaderClass:(Class)classz {
    if (classz) _classz = classz;
}

+ (Class)getHeaderClass {
    return _classz;
}

#pragma mark - life cycle
- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithTarget:nil action:NULL];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setBounds:(CGRect)bounds {
}

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    if (!_classz) {
        _classz = [RCTCustomRefreshHeaderView class];
    }
     _headerView = [[_classz alloc] init];
    _refreshHeaderHeight = _headerView.frame.size.height;
    self = [super initWithFrame:CGRectMake(0, -_refreshHeaderHeight, [UIScreen mainScreen].bounds.size.width , _refreshHeaderHeight)];
    if (self) {
        self.refreshTarget = target;
        self.refreshAction = action;
        _refreshHeaderThreshold = _refreshHeaderHeight * kRefreshThresholdMulti;
        self.tintColor = [UIColor clearColor];
        [self addSubview:_headerView];
        [self setRefreshState:PAFFRefreshStateNormal];
        _refreshTimeout = 8;
        self.enabled = YES;
    }
    return self;
}

#pragma mark -override
- (void)willMoveToSuperview:(UIView *)newSuperview {

    [super willMoveToSuperview:newSuperview];
    if (newSuperview && ![newSuperview isKindOfClass:[UIScrollView class]]) return;
    [self removeObservers];
    if (newSuperview) {
        self.superScrollView = (UIScrollView *)newSuperview;
        [self addObservers];
    }

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if(!self.enabled){
        return;
    }

    if ([keyPath isEqualToString:@"contentOffset"]){
        if (![self.superScrollView isKindOfClass:[UIScrollView class]]) return;
        if (self.refreshState == PAFFRefreshStateRefreshing || _isRefreshing) {
            return; //如果处于刷新状态返回
        }

        UIScrollView *superScrollView = (UIScrollView *)self.superScrollView;
        if (superScrollView.isDragging) {
            [self updateFrame];
            if (!self.originalOffsetY) {
                self.originalOffsetY = - superScrollView.contentInset.top;
            }
            CGFloat normalPullingOffset = self.originalOffsetY - _refreshHeaderThreshold;

            if (self.refreshState != PAFFRefreshStateRefreshing && superScrollView.contentOffset.y > normalPullingOffset) {
                self.refreshState = PAFFRefreshStateNormal;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_headerView) [_headerView onPull:NO offset:superScrollView.contentOffset.y+superScrollView.contentInset.top];
                });
            } else if (self.refreshState != PAFFRefreshStateRefreshing && superScrollView.contentOffset.y < normalPullingOffset) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_headerView) [_headerView onPull:YES offset:superScrollView.contentOffset.y + superScrollView.contentInset.top];
                });
                self.refreshState = PAFFRefreshStatePulling;
            }
        } else if (!superScrollView.isDragging) {
            if (self.refreshState == PAFFRefreshStatePulling) {
                _isHandler = YES;
                self.refreshState = PAFFRefreshStateRefreshing;
                //超时结束刷新
                if (_refreshTimeout > 0) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_refreshTimeout *_refreshTimeout * 1000000000ull * 0.8)), dispatch_get_main_queue(), ^{
                        [self endRefreshing];
                    });
                }

            }

        }

    }

}


- (void)setRefreshState:(PAFFRefreshState)refreshState {

    if (_refreshState == refreshState) {
        return;
    }
    _refreshState = refreshState;

    switch (refreshState) {
        case PAFFRefreshStateNormal:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_headerView) [_headerView onPrepare];
            });
        }
            break;

        case PAFFRefreshStateRefreshing:
        {
            _isRefreshing = YES;
            CGFloat insertTop = _superScrollView.contentInset.top;
            insertTop += _refreshHeaderHeight;
            CGPoint contentOffset = _superScrollView.contentOffset;
            contentOffset.y = - insertTop;
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.25 animations:^{
                    _superScrollView.contentInset = UIEdgeInsetsMake(insertTop, 0.0f, 0.0f, 0.0f);
                    _superScrollView.contentOffset = contentOffset;
                } completion:^(BOOL finished) {
                    [self doAction];
                }];
            });

        }
            break;
        case PAFFRefreshStateComplete:
        {
            _isHandler = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_headerView) [_headerView onComplete];
            });

        }
            break;
        case PAFFRefreshStatePulling:
        {
        }
            break;
    }

}

#pragma mark - public
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    self.refreshTarget = target;
    self.refreshAction = action;
}

- (void)beginRefreshing {
    if (_refreshState == PAFFRefreshStateRefreshing || _isRefreshing || !self.enabled) {
        return;
    }
    [self setRefreshState:PAFFRefreshStateRefreshing];

}

- (void)endRefreshing {

    if (self.refreshState != PAFFRefreshStateRefreshing || !self.enabled) {
        return;
    }

    if (![self.superScrollView isKindOfClass:[UIScrollView class]])
        return;
    
    UIScrollView *superScrollView = (UIScrollView *)self.superScrollView;
    CGFloat insertTop = superScrollView.contentInset.top;

    if (insertTop - _refreshHeaderHeight >= 0)
        insertTop -= _refreshHeaderHeight;

    [self setRefreshState:PAFFRefreshStateComplete];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:.25 animations:^{
            [superScrollView setContentInset:UIEdgeInsetsMake(insertTop, 0.0f, 0.0f, 0.0f)];
        } completion:^(BOOL finished) {
            _isRefreshing = NO;   
        }];
    });

}

- (BOOL)isRefreshing {
    return self.refreshState == PAFFRefreshStateRefreshing;
}

- (void)setRefreshing:(BOOL)refreshing {
    [self updateFrame];
    _isHandler = NO;
    if (!refreshing) {
        [self endRefreshing];
    } else {
        [self beginRefreshing];
    }
    _refreshing = refreshing;

}

#pragma mark - private
- (void)updateFrame {
    self.frame = CGRectMake(0, -_refreshHeaderHeight, [UIScreen mainScreen].bounds.size.width, _refreshHeaderHeight);
}

- (void)removeObservers {

    [self.superview removeObserver:self forKeyPath:@"contentOffset"];

}

- (void)addObservers {

    [self.superScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];

}


- (void)doRefreshAction {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (self.refreshTarget && [self.refreshTarget respondsToSelector:self.refreshAction]) {
        [self.refreshTarget performSelector:self.refreshAction];
    }
#pragma clang diagnostic pop
}

- (void)doAction {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_headerView) [_headerView onStart];
    });
    if (_onRefresh && _isHandler) {
        self.onRefresh(@{});
    }
    [self doRefreshAction];
}

@end
