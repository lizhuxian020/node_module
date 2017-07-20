//
//  PAFFRefreshControl.h
//  TestRefresh
//
//  Created by wangliping on 17/1/5.
//  Copyright © 2017年 PingAn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCTComponent.h"

@interface RCTCustomRefreshControl : UIControl

@property (nonatomic, assign) NSTimeInterval refreshTimeout;//下拉刷新超时时间

@property (nonatomic, assign) BOOL automaticallyChangeAlpha;//是否自动调整透明度

@property (nonatomic, assign) BOOL refreshing;//是否处于刷新

@property (nonatomic, copy) RCTDirectEventBlock onRefresh;//是否处于刷新

//开始刷新
- (void)beginRefreshing;

//结束刷新
- (void)endRefreshing;

/**
 自定义下拉刷新头部
 @param 刷新头部
 */
+ (void)setHeaderClass:(Class)classz;

//获取下拉刷新头部
+ (Class)getHeaderClass;

@end
