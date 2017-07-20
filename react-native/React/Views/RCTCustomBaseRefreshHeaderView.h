//
//  PAFFBaseRefreshHeaderView.h
//  Pods
//
//  Created by wangliping on 17/2/4.
//
//

#import <UIKit/UIKit.h>

@interface RCTCustomBaseRefreshHeaderView : UIView

/**
准备刷新
 */
- (void)onPrepare;

/**
 下拉
 @param willRefresh 是否触发刷新状态
 @param offset 下拉offset
 */
- (void)onPull:(BOOL)willRefresh offset:(CGFloat)offset;

/**
 开始刷新
 */
- (void)onStart;

/**
 结束刷新
 */
- (void)onComplete;

@end
