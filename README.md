# zzKVO 内容变化监视器

支持对属性过滤,过滤选项包括：空值到非空值、非空值到空值、以及常规的改变的事件触发

通过扩展NSObject, 自定义实现的一种KVO，回调以BLOCK方式代替Delegate

##使用方式

#### 添加头文件
```
#import "NSObject+zz.h"
```

#### 添加监视器调用方式如下：
```
[self zz_addObserverForKeyPath:NSStringFromSelector(@selector(name)) attachOption:VCE_OLE_TO_NEW withBlock:^(id  _Nonnull idObservedObject, NSString * _Nonnull strKeyPath, id  _Nullable idOldValue, id  _Nullable idNewValue) {
        NSLog(@"key=%@,oldvalue=%@,newvalue=%@",strKeyPath,idOldValue,idNewValue);
    }];
```
#### 移除监视器调用方式如下：
```
[self zz_removeObserverforKeyPath:NSStringFromSelector(@selector(name))];

```
