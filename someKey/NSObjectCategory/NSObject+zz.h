//
//  NSObject+zz.h
//
//  Created by xuanwenchao on 2020/5/28.
//  Copyright © 2020 zz. All rights reserved.
//

#import <Foundation/Foundation.h>


//触发事件的Block定义
typedef void(^TriggerEventBlock)(_Nonnull id idObservedObject, NSString * _Nonnull strKeyPath, _Nullable id idOldValue, _Nullable id idNewValue);


typedef NS_OPTIONS(NSUInteger, ValueChangeEventOption) {
    VCE_NONE = 0,
    VCE_SOME_TO_NULL, //监控目标从有值变为空值或nil时，触发监听事件
    VCE_NULL_TO_SOME, //监控目标从空值或Nil变为有值变时，触发监听事件
    VCE_OLE_TO_NEW,   //监控目标从一个值改变为另一个值时，触发监听事件
    VCE_MAX
};


NS_ASSUME_NONNULL_BEGIN

@interface NSObject (zz)
@property (nonatomic,strong)NSMutableArray* zzObserves;

//添加监视器
-(BOOL)zz_addObserver:(NSObject *)observer
                        forKeyPath:(NSString*)strKeyPath
                        attachOption:(ValueChangeEventOption)option
                        withBlock:(TriggerEventBlock)block;

-(BOOL)zz_addObserverForKeyPath:(NSString*)strKeyPath
                        attachOption:(ValueChangeEventOption)option
                          withBlock:(TriggerEventBlock)block;

//移除监视器
-(void)zz_removeObserver:(NSObject*)observer forKeyPath:(NSString*)strKeyPath;

-(void)zz_removeObserverforKeyPath:(NSString*)strKeyPath;

@end

NS_ASSUME_NONNULL_END
