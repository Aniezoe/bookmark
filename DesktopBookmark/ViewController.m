//
//  ViewController.m
//  DesktopBookmark
//
//  Created by niezhiqiang on 2021/7/10.
//

#import "ViewController.h"
#import "DesktopBookmark.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *addButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    [_addButton setCenter:self.view.center];
    [_addButton addTarget:self action:@selector(addBookmark) forControlEvents:UIControlEventTouchUpInside];
    [_addButton setTitle:@"添加桌面快捷方式" forState:UIControlStateNormal];
    [_addButton setBackgroundColor:UIColor.blackColor];
    [self.view addSubview:_addButton];
}

- (void)addBookmark {
    NSString *urlScheme = @"bookmark://com.tool.desktopbookmark";
    BookmarkModel *model = [[BookmarkModel alloc] init];
    model.title = @"书签";
    model.urlScheme = urlScheme;
    model.moduleID = @"主页";
    model.imageName = @"bookmark";
    [DesktopBookmark createDesktopBookmarkWithModel:model];
}


@end
