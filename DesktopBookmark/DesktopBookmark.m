//
//  DesktopBookmark.m
//  DesktopBookmark
//
//  Created by niezhiqiang on 2021/7/10.
//

#import <UIKit/UIKit.h>
#import "DesktopBookmark.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

@implementation BookmarkModel

@end

@interface DesktopBookmark ()

@property (nonatomic, copy) NSString *webRootDir;
@property (nonatomic, strong) GCDWebServer *webServer;

@end

@implementation DesktopBookmark

+ (instancetype)sharedInstance {
    static DesktopBookmark *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = paths[0];
        self.webRootDir = [documentsPath stringByAppendingPathComponent:@"server/web"];
        BOOL isDirectory = YES;
        BOOL exsit = [[NSFileManager defaultManager] fileExistsAtPath:_webRootDir isDirectory:&isDirectory];
        if(!exsit){
            [[NSFileManager defaultManager] createDirectoryAtPath:_webRootDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)createDesktopBookmarkWithModel:(BookmarkModel *)model {
    DesktopBookmark *bookmark = [DesktopBookmark sharedInstance];
    [bookmark startLocalServerWithModel:model];
    NSString *urlStrWithPort = [NSString stringWithFormat:@"http://127.0.0.1:%zd", bookmark.webServer.port];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStrWithPort]];
}

- (void)startLocalServerWithModel:(BookmarkModel *)model {
    NSString *html = [DesktopBookmark createRedirectHtmlWithModel:model];
    self.webServer = [[GCDWebServer alloc] init];
    [_webServer addDefaultHandlerForMethod:@"GET"
                              requestClass:[GCDWebServerRequest class]
                              processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        return [GCDWebServerDataResponse responseWithHTML:html];
    }];

    [_webServer addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        NSError *error;
        NSString *redirectPath = [[NSString alloc] initWithContentsOfFile:[DesktopBookmark webRedirectPath] encoding:NSUTF8StringEncoding error:&error];
        NSURL *url = [NSURL URLWithString:redirectPath];
        return [GCDWebServerResponse responseWithRedirect:url permanent:NO];
    }];

    [_webServer startWithPort:0 bonjourName:nil];
}

- (void)applicationDidBecomeActive {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (self.webServer.isRunning) {
            [self.webServer stop];
            self.webServer = nil;
        }
    });
}

- (void)applicationDidEnterBackground {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(2);
        [self.webServer stop];
        self.webServer = nil;
    });
}

+ (NSString *)webRedirectPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = paths[0];
    NSString *webRootDir = [documentsPath stringByAppendingPathComponent:@"server/web"];
    BOOL isDirectory = YES;
    BOOL exsit = [[NSFileManager defaultManager] fileExistsAtPath:webRootDir isDirectory:&isDirectory];
    if(!exsit){
        [[NSFileManager defaultManager] createDirectoryAtPath:webRootDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [NSString stringWithFormat:@"%@/server/web/redirectPath",documentsPath];
}

+ (NSString *)createRedirectHtmlWithModel:(BookmarkModel *)model {
    NSString *title = model.title;
    NSString *urlScheme = model.urlScheme;
    NSString *moduleID = model.moduleID;
    NSString *imageName = model.imageName;
    
    NSMutableString *taragerUrl = [NSMutableString stringWithFormat:@"<html><head><meta content=\"yes\" name=\"apple-mobile-web-app-capable\" /><meta content=\"text/html; charset=UTF-8\" http-equiv=\"Content-Type\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, user-scalable=no\" /><title>%@</title></head><body bgcolor=\"#ffffff\">",title];
    NSString *htmlUrlScheme = [NSString stringWithFormat:@"<a href=\"%@",urlScheme];
    NSString *dataUrlStr = [NSString stringWithFormat:@"%@=%@&%@=%@\" id=\"qbt\" style=\"display: none;\"></a>",@"10000",moduleID,@"1",@(1)];
    
    UIImage *image = [UIImage imageNamed:imageName];
    NSData *imageData = UIImagePNGRepresentation(image);
    
    NSString *base6ImageStr = [imageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    NSString *imageUrlStr = [NSString stringWithFormat:@"<span id=\"msg\"></span></body><script>if (window.navigator.standalone == true) {    var lnk = document.getElementById(\"qbt\");    var evt = document.createEvent('MouseEvent');    evt.initMouseEvent('click');    lnk.dispatchEvent(evt);}else{    var addObj=document.createElement(\"link\");    addObj.setAttribute('rel','apple-touch-icon-precomposed');    addObj.setAttribute('href','data:image/png;base64,%@');",base6ImageStr];
    
    UIImage *bubbleImage = [UIImage imageNamed:@"bubble"];
    NSData *bubbleImageData = UIImagePNGRepresentation(bubbleImage);
    NSString *base6BubbleImageStr = [bubbleImageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    NSString *orientationchangeJS = @"<script>window.addEventListener('orientationchange',function () {if (window.orientation == 0) {document.getElementById('img-div').setAttribute('style', 'width:267px;position:fixed;bottom:8px;left:50vw;margin-left:-133.5px;');document.getElementById('img-bottom').setAttribute('style', 'width:267px;');} else {document.getElementById('img-div').setAttribute('style', 'width:160px;position:fixed;bottom:8px;left:50vw;margin-left:-80px;');document.getElementById('img-bottom').setAttribute('style', 'width:160px;');}},false);</script>";
    
    NSString *lastHtmlStr = [NSString stringWithFormat:@"document.getElementsByTagName(\"head\")[0].appendChild(addObj);    document.getElementById(\"msg\").innerHTML='<div style=\"font-size:14px;position:fixed;width:100vw;top: 30px;text-align:center;left:0;\"> <div style=\"width:75px;margin: 0 auto;border-radius:12px;margin-bottom:10px;overflow:hidden;box-shadow: 0 6px 14px 0 rgba(9,40,71,0.2);\"><img id=\"i\" src=\"data:image/png;base64,%@\" style=\"width:75px;\"></div> 添加快捷方式到主屏幕 </div><div  id=\"img-div\" style=\"width:267px;position:fixed;bottom:8px;left:50vw;margin-left:-133.5px;\"><img id=\"img-bottom\" src=\"data:image/png;base64,%@\" style=\"width:267px;\"></div>';}</script>%@</html>", base6ImageStr, base6BubbleImageStr,orientationchangeJS];
    
    [taragerUrl appendString:htmlUrlScheme];
    [taragerUrl appendString:dataUrlStr];
    
    NSString *dataUrlEncode = [[NSString stringWithFormat:@"data:text/html;charset=UTF-8,%@", taragerUrl] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *imageUrlEncode = [imageUrlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *lastHtmlStrEncode = [lastHtmlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSData *data = [[NSString stringWithFormat:@"%@%@%@",dataUrlEncode,imageUrlEncode,lastHtmlStrEncode] dataUsingEncoding:NSUTF8StringEncoding];
    [data writeToFile:[DesktopBookmark webRedirectPath] atomically:YES];
             
    NSString *finalHtml = [NSString stringWithFormat:@"%@%@%@",taragerUrl,imageUrlStr,lastHtmlStr];
    
    return finalHtml;
}

@end
