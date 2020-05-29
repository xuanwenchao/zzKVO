# zzKVO
NSObject Category For zzKVO

实现KVO，回调以BLOCK方式代替Delegate


## 添加监视器调用方式如下：
```
[self zz_addObserverForKeyPath:NSStringFromSelector(@selector(name)) attachOption:VCE_OLE_TO_NEW withBlock:^(id  _Nonnull idObservedObject, NSString * _Nonnull strKeyPath, id  _Nullable idOldValue, id  _Nullable idNewValue) {
        NSLog(@"key=%@,oldvalue=%@,newvalue=%@",strKeyPath,idOldValue,idNewValue);
    }];
```
## 移除监视器调用方式如下：
```
-(void)dealloc{
    [self zz_removeObserverforKeyPath:NSStringFromSelector(@selector(name))];
}
```
