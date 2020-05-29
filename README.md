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

#### 测试代码在TestCaseViewController
```
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self zz_addObserverForKeyPath:NSStringFromSelector(@selector(name)) attachOption:VCE_OLE_TO_NEW withBlock:^(id  _Nonnull idObservedObject, NSString * _Nonnull strKeyPath, id  _Nullable idOldValue, id  _Nullable idNewValue) {
        NSLog(@"key=%@,oldvalue=%@,newvalue=%@",strKeyPath,idOldValue,idNewValue);
    }];
    
    if(_btnChangeName == nil){
        _btnChangeName = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnChangeName setBackgroundColor:UIColor.orangeColor];
        [_btnChangeName setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        [_btnChangeName setTitle:@"改变名字" forState:UIControlStateNormal];
        _btnChangeName.frame = CGRectMake(30, 150, CGRectGetWidth(self.view.frame)-60, 40);
        _btnChangeName.layer.cornerRadius = 5;
        _btnChangeName.layer.masksToBounds = YES;
        _btnChangeName.tag = 101;
        [_btnChangeName addTarget:self action:@selector(btnEvent:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_btnChangeName];
    }
    
}

-(void)btnEvent:(id)sender{
    NSString *strChangedName = [NSString stringWithFormat:@"test%ld",(long)_btnChangeName.tag];
    _btnChangeName.tag = _btnChangeName.tag + 1;
    self.name = strChangedName;
}


-(void)dealloc{
    [self zz_removeObserverforKeyPath:NSStringFromSelector(@selector(name))];
}
```
