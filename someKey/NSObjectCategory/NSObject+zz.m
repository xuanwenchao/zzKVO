//
//  NSObject+zz.m
//
//  Created by xuanwenchao on 2020/5/28.
//  Copyright © 2020 zz. All rights reserved.
//

#import "NSObject+zz.h"
#import <objc/runtime.h>
#import <objc/message.h>

//动态创建类的前缀名
#define kDynamicClassPrefix @"kDynamicClassPrefix_"

//为NSObject动态关联的属性标识
static const char*  kAssociatedObservedPropertyName = "kAssociatedObservedPropertyName";

//纯C函数的声明
static NSString * generateSetterStringFromKey(NSString* strKey);


#pragma mark - custom model for dynamic property
//该模型结构，将用来添加到NSObject的动态属性中
@interface ObservedInfoModel : NSObject
@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *strKeyPath;
@property (nonatomic, copy) NSString *strSetter;
@property (nonatomic, copy) TriggerEventBlock block;
@property (nonatomic, assign) ValueChangeEventOption option;
@end

@implementation ObservedInfoModel
//用来生产一个新的Model
+(instancetype)CreateModelWithObserver:(NSObject*)observer
                            forKeyPath:(NSString*)strKeyPath
                            attachOption:(ValueChangeEventOption)option
                            withBlock:(TriggerEventBlock)block{
    ObservedInfoModel *model = [[ObservedInfoModel alloc] init];
    model.observer   = observer;
    model.strKeyPath = strKeyPath;
    model.option     = option;
    model.block      = block;
    model.strSetter  = generateSetterStringFromKey(strKeyPath);
    return model;
}

@end

#pragma mark - utils funtion with C
//通用传入key得到setter方法的字符串
static NSString * generateSetterStringFromKey(NSString* strKey){
    if(strKey.length <= 0){
        NSLog(@"generateSetterStringFromKey Failed! \n cause strKey is nil.");
        return nil;
    }
    
    NSString *strFirstLetter = [[strKey substringToIndex:1] uppercaseString];
    NSString *strTailString  = [strKey substringFromIndex:1];
    
    //生成setter方法的字符串
    NSString *strSetter = [NSString stringWithFormat:@"set%@%@",strFirstLetter,strTailString];
    
    return strSetter;
}

//通用传入setter的SEL得到getter的SEL
static SEL generateGetterSELWithSetterSEL(SEL selForSetter){
    
    if(selForSetter == nil){
        return nil;
    }
    
    //得到setKey字符串中的Key 转为getter
    NSString *strSetter = NSStringFromSelector(selForSetter);
    NSString *strTemp   = [strSetter substringFromIndex:3];
    NSString *strGetter = [[strTemp substringWithRange:NSMakeRange(0, 1)] lowercaseString];
    strGetter = [strTemp stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:strGetter];
    
    //通过字符串生成对应的SEL
    SEL selGetter = NSSelectorFromString(strGetter);
    
    return selGetter;
}

//动态创建的新的类，中的class方法的实现,并不返回真实的类，而是返回其父类
static Class dynamic_Class(id self, SEL _cmd)
{
    return class_getSuperclass(object_getClass(self));
}

//动态创建新的类中,新的setter方法
static void setter_for_dynamic_class(id self, SEL _cmd, id idNewValue){
    
    //通用传入setter的SEL得到getter的SEL
    SEL selGetter = generateGetterSELWithSetterSEL(_cmd);
    
    //判断getter方法是否存在
    if(![self respondsToSelector:selGetter]){
        @throw [NSException exceptionWithName:@"未能找到SEL异常" reason:@"Could not found getter method." userInfo:nil];
        return;
    }
    
    //通过getter方法得到变更之前的值,此处如果使用performselect会有警告
    IMP imp = [self methodForSelector:selGetter];
    id (*funcGetter)(id,SEL) = (void *)imp;
    id idOldValue = funcGetter(self,selGetter);

    struct objc_super superClass;
    superClass.receiver = self;
    superClass.super_class = class_getSuperclass(object_getClass(self));
    
    //因为objc_msgSendSuper是一个万能的向父类发送消息机制，使用之前先定义为函数指针，明确参数类型
    void (*objc_msgSendSuperCasted)(void*, SEL, id) = (void*)objc_msgSendSuper;
    
    //因为当前的实列对象的setter方法已经补重写，所以还需要调用原来的setter方法
    objc_msgSendSuperCasted(&superClass,_cmd, idNewValue);
    
    //最后将当前已经在监控列中的信息找出来，对所有符合option的block进行通知
    NSMutableArray *arrObserves = objc_getAssociatedObject(self, kAssociatedObservedPropertyName);
    NSString *strSetter = NSStringFromSelector(_cmd);
    for(ObservedInfoModel *m in arrObserves){
        if([m.strSetter isEqualToString:strSetter]){
            if((m.option == VCE_NULL_TO_SOME && idOldValue == nil) ||
               (m.option == VCE_SOME_TO_NULL && (idOldValue !=nil && idNewValue == nil)) ||
               (m.option == VCE_OLE_TO_NEW)){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0x00), ^{
                    m.block(self, m.strKeyPath, idOldValue, idNewValue);
                });
            }
            
        }
    }
}


#pragma mark - category for NSObject
@implementation NSObject (zz)
@dynamic zzObserves;

//添加监视器
-(BOOL)zz_addObserver:(NSObject *)observer
           forKeyPath:(NSString*)strKeyPath
           attachOption:(ValueChangeEventOption)option
            withBlock:(TriggerEventBlock)block{
    
    //生成setKey字符串和对应的SEL
    NSString *strSetterForKey = generateSetterStringFromKey(strKeyPath);
    SEL selForSetter          = NSSelectorFromString(strSetterForKey);
    
    //判断当前实列对象，是否有KEY对应的setter方法,因为需要通过重写setter来实现监控数据变化
    Method methodForSetter    = class_getInstanceMethod([self class], selForSetter);
    if(!methodForSetter){
        NSLog(@"Could not found setter named: %@",strSetterForKey);
        return NO;
    }
    
    Class classSelf = object_getClass(self);
    NSString *className = NSStringFromClass(classSelf); //得到类名的完整字符串
    
    //判断当前实列的类名，是否为动态创建的新类
    if(![className hasPrefix:kDynamicClassPrefix]){
        //创建一个新的类，继承自当前类，并将当前实列对象 ,关联到新创建的动态类
        classSelf = [self createDynamicClassWithClassName:className];
        
        //此时的classSelf已经指向新创建的动态类
        object_setClass(self, classSelf);
    }
    
    //判断新创建的动态类中，是否存在key对应的setter方法, 如果还没有，则添加新的setter方法，代替原有类中的setter
    unsigned int methodCount = 0;
    BOOL      bIsFoundSetter = NO;
    Method* methodList = class_copyMethodList(classSelf, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL sel = method_getName(methodList[i]);
        if (selForSetter == sel) {
            bIsFoundSetter = YES;
            break;;
        }
    }
    free(methodList);

    //如果没有找到setter则需要为其添加一个setter方法
    if(bIsFoundSetter == NO){
        //新的动态类中没有找到对应的setter
        const char *types = method_getTypeEncoding(methodForSetter);
        
        // @return YES if the method was added successfully, otherwise NO
        //  (for example, the class already contains a method implementation with that name).
        //该方法只有在已经存在同名的selecter时会返回失败，当前已经判断不存在因为认为一定成功
        class_addMethod(classSelf, selForSetter, (IMP)setter_for_dynamic_class, types);
    }
    
    //用来保存ObservedInfoModel的动态属性，如果第一次使用，需要创建生成
    if(self.zzObserves == nil){
        self.zzObserves = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    //将需要监控的相关信息存入动态属性
    ObservedInfoModel *m = [ObservedInfoModel CreateModelWithObserver:observer forKeyPath:strKeyPath attachOption:option withBlock:block];
    [self.zzObserves addObject: m];
    
    return YES;
}

-(BOOL)zz_addObserverForKeyPath:(NSString*)strKeyPath
           attachOption:(ValueChangeEventOption)option
            withBlock:(TriggerEventBlock)block{
    return [self zz_addObserver:self forKeyPath:strKeyPath attachOption:option withBlock:block];
}

//移除监视器
-(void)zz_removeObserver:(NSObject*)observer forKeyPath:(NSString*)strKeyPath{
    for(ObservedInfoModel *m in self.zzObserves){
        if(m.observer == observer && [m.strKeyPath isEqualToString:strKeyPath]){
            [self.zzObserves removeObject:m];
            break;
        }
    }
}

-(void)zz_removeObserverforKeyPath:(NSString*)strKeyPath{
    [self zz_removeObserver:self forKeyPath:strKeyPath];
}


//实现动态变量zzObserves的setter和getter方法
-(void)setZzObserves:(NSMutableArray *)zzObserves{
    objc_setAssociatedObject(self, kAssociatedObservedPropertyName, zzObserves,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSMutableArray*)getZzObserves{
    NSMutableArray *array = objc_getAssociatedObject(self, kAssociatedObservedPropertyName);
    return array;
}


//通过原始类名，生成动态类名，并注册动态创建的新类
-(Class)createDynamicClassWithClassName:(NSString*) strClassName{
    NSString *strDynamicClassName = [kDynamicClassPrefix stringByAppendingString:strClassName];
    Class clsDynamic = NSClassFromString(strDynamicClassName);
    if(clsDynamic){
        //如果动态类已经存在，说明并不是首次执行，该方法，因此可直接返回
        return clsDynamic;
    }
    
    //如果动态类还不存在，则创建出一个新的动态类，该类继承自strClassName
    Class clsOld = NSClassFromString(strClassName);
    clsDynamic = objc_allocateClassPair(clsOld, strDynamicClassName.UTF8String, 0x00);
    
    //获取父类的calss方法的TypeEncoding ，
    Method methodOfSuperClass = class_getInstanceMethod(clsOld, @selector(class));
    const char *types = method_getTypeEncoding(methodOfSuperClass);
    
    //此处，将新创建的动态类的class方法进行改变，返为的 class为其父类的class
    class_addMethod(clsDynamic, @selector(class), (IMP)dynamic_Class, types);
    objc_registerClassPair(clsDynamic);
    
    return clsDynamic;
}


@end










