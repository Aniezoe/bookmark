//
//  DesktopBookmark.h
//  DesktopBookmark
//
//  Created by niezhiqiang on 2021/7/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BookmarkModel : NSObject

@property (nonatomic, strong) NSString *title;//图标title
@property (nonatomic, strong) NSString *imageName;//图标名字
@property (nonatomic, strong) NSString *urlScheme;//页面urlScheme
@property (nonatomic, strong) NSString *moduleID;//模块标识（传入模块的名称）

@end

@interface DesktopBookmark : NSObject

//创建桌面快捷方式
+ (void)createDesktopBookmarkWithModel:(BookmarkModel *)model;

@end

NS_ASSUME_NONNULL_END
