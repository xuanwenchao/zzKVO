//
//  TestCaseViewController.m
//  someKey
//
//  Created by xuanwenchao on 2020/5/28.
//  Copyright © 2020 zz. All rights reserved.
//

#import "TestCaseViewController.h"
#import "NSObject+zz.h"

@interface TestCaseViewController ()
@property (nonatomic,strong)NSString *name;
@property (nonatomic,strong)UIButton *btnChangeName;

@end

@implementation TestCaseViewController
@synthesize name;

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




@end
