//
//  PAFFRefreshControlManager.m
//  Pods
//
//  Created by wangliping on 17/1/9.
//
//

#import "RCTCustomRefreshControlManager.h"
#import "RCTCustomRefreshControl.h"


@implementation RCTCustomRefreshControlManager

RCT_EXPORT_MODULE(PAFFRefreshControl);

- (UIView *)view {
    RCTCustomRefreshControl *refreshCtrl = [[RCTCustomRefreshControl alloc] init];
    return refreshCtrl;
}

/**
 *  RN设置刷新状态
 *
 *  BOOL
 *  @return 更新信息
 */
RCT_EXPORT_VIEW_PROPERTY(refreshing, BOOL)

/**
 *  RN设置组件是否可用
 *
 *  BOOL
 *  @return 更新信息
 */
RCT_EXPORT_VIEW_PROPERTY(enabled, BOOL)

/**
 *  刷新回调
 *
 *  onRefresh 回调方法
 *  @return 更新信息
 */
RCT_EXPORT_VIEW_PROPERTY(onRefresh, RCTDirectEventBlock)

@end
