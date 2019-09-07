//
//  ViewController.m
//  JS和OC相互调用
//
//  Created by xiaoshayu on 2017/6/28.
//  Copyright © 2017 xiaoshayu. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface ViewController ()<UIWebViewDelegate,WKNavigationDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (copy, nonatomic) NSString * htmlString;
@property (strong, nonatomic) WKWebView * wkWebView;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1.用UIWebView实现URL拦截
    [self webViewInterceptUrl];
    
    
    // 2.用WKWebView实现URL拦截
//    [self wkwebViewInterceptUrl];
}

- (void)webViewInterceptUrl{
    self.descLabel.text = @"UIWebView拦截URL";
    self.wkWebView.hidden = YES;
    self.webView.hidden = NO;
    self.webView.delegate = self;
    [self.webView loadHTMLString:self.htmlString baseURL:nil];
}

- (void)wkwebViewInterceptUrl{
    self.descLabel.text = @"UWKWebView拦截URL";
    self.wkWebView.hidden = NO;
    self.webView.hidden = YES;
    self.webView.hidden = YES;
    [self.view addSubview:self.wkWebView];
    [self.wkWebView loadHTMLString:self.htmlString baseURL:nil];
    self.wkWebView.navigationDelegate = self;
}

- (IBAction)buttonClick:(UIButton *)button{
    switch (button.tag) {
        case 0:
        {
            NSLog(@"OC调用JS 无参");
            if (!self.webView.hidden) {
                [self.webView stringByEvaluatingJavaScriptFromString:@"ocCallJs()"];
            }else{
                [self.wkWebView evaluateJavaScript:@"ocCallJs()" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                    
                }];
            }
            
        }
            break;
        case 1:
        {
            NSLog(@"OC调用JS 一个参数");
            NSString * testJS = [NSString stringWithFormat:@"ocCallJs('%d')",arc4random_uniform(100)];
            if (!self.webView.hidden) {
                [self.webView stringByEvaluatingJavaScriptFromString:testJS];
            }else{
                [self.wkWebView evaluateJavaScript:testJS completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                    
                }];
            }
            
        }
            break;
        case 2:
        {
            NSLog(@"OC调用JS 两个参数");
            //NSArray * temp = @[@"123"];
            NSString * testJS = [NSString stringWithFormat:@"ocCallJs('%@','456')",@123];
            if (!self.webView.hidden) {
                // 注意 在 OC调用JS 给JS传参的时候 不能拼接数组或者字典类型到字符串中  @"alertSendMsg('param','456')"
                [self.webView stringByEvaluatingJavaScriptFromString:testJS];
            }else{
                [self.wkWebView evaluateJavaScript:testJS completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                    
                }];
            }
        }
            break;
    }
}

#pragma mark - UIWebViewDelegate
-(void)webViewDidStartLoad:(UIWebView *)webView{}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"webViewDidFinishLoad");
    //! 获取JS代码的执行环境/上下文/作用域
    JSContext * context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    //! 监听JS代码里面的jsToOc方法（执行效果上可以理解成重写了JS的jsToOc方法）
    context[@"ocClick"] = ^(NSString * str1, NSString * str2) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"str1 %@ , --- str2 %@ ,",str1,str2);
            // 要执行的oc代码
        });
    };
    
    // oc调用js
    // 写法1.
//    [context[@"ocCallJs"] callWithArguments:@[@"111",@"222"]];
    
    // 写法2.
    NSString *jsStr = [NSString stringWithFormat:@"ocCallJs('%d','%d')",15,20];
    [context evaluateScript:jsStr];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    [self jsCallOCMethodWithRequest:request];
    return YES;
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    NSString * absoluteString = [navigationAction.request.URL.absoluteString stringByRemovingPercentEncoding];
    NSString * scheme = @"testhtml://";
    // JS调用OC
    if ([absoluteString hasPrefix:scheme]) {
        [self jsCallOCMethodWithRequest:navigationAction.request];
        decisionHandler(WKNavigationActionPolicyCancel);
    }else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)jsCallOCMethodWithRequest:(NSURLRequest *)request{
    void (^AlertViewBlock)(NSString * title,NSString * message,NSString * cancel) = ^(NSString * title,NSString * message,NSString * cancel){
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:nil];
        [alertView show];
    };
    
    NSString * urlString = request.URL.absoluteString;
    NSString * scheme = @"testhtml://";
    if ([urlString hasPrefix:scheme]) {
        //
        NSString * subString = [urlString substringFromIndex:scheme.length];
        NSArray * temp = [subString componentsSeparatedByString:@"?"];
        NSString * method = [temp firstObject];
        if ([method isEqualToString:@"method1"]) {
            AlertViewBlock(@"JS调用OC方法",@"无参",@"取消");
        }else if ([method isEqualToString:@"method2"]) {
            NSString * param = [temp lastObject];
            AlertViewBlock(@"JS调用OC方法",[NSString stringWithFormat:@"一个参数\n参数为:%@",param],@"取消");
        }else if ([method isEqualToString:@"method3"]) {
            NSString * string = [temp lastObject];
            NSRange range = [string rangeOfString:@"&"];
            NSString * param1 = [string substringToIndex:range.location];
            NSString * param2 = [string substringFromIndex:range.location + 1];
            AlertViewBlock(@"JS调用OC方法",[NSString stringWithFormat:@"两个参数\n参数为:%@,%@",param1,param2],@"取消");
        }
    }
}
- (NSString *)htmlString{
    if (!_htmlString) {
        _htmlString = @"<html>\
        <head>\
        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" /> \
        <title>TestHtml</title> <style>.btn{height:50px; width:60%; padding: 0px 30px; background-color: #0071E7; border: solid 1px #0071E7; border-radius:5px; font-size: 1.0em; color: white} </style> \
        <script> \
        function alertMobile() { alert('OC调用JS 无参') } \
        function alertName(msg) { alert('OC调用JS 一个参数 ' + msg )} \
        function alertSendMsg(num,msg) { alert('OC调用JS 两个参数:' + num + ',' + msg) } \
        \
        function btnClick1() { location.href = \"testhtml://method1\"} \
        function btnClick2() { location.href = \"testhtml://method2?iPhone7Plus\"} \
        function btnClick3() { location.href = \"testhtml://method3?QQ&weChat\"}\
        function btnClick4() { ocClick('10');}\
        function JSCallOC(a,b) { var url = \"jscalloc://\" + \"action\" + \"?\" + \"params\";\
        loadURL(url);}\
        function ocCallJs(action, params) { document.getElementById(\"returnValue\").innerHTML = action + '?' + params;}\
        </script>\
        </head>\
        <body>\
        <br/>\
        <br/>\
        <div><label>JS 调用OC的方法</label></div>\
        <br/>\
        <br/>\
        <div id=\"div1\"><button class=\"btn\" type=\"button\" onclick=\"btnClick1()\">JS调用OC方法 无参</button></div><br/>\
        <div><button class=\"btn\" type=\"button\" onclick=\"btnClick2()\">JS调用OC方法 一个参数</button></div><br/>\
        <div><button class=\"btn\" type=\"button\" onclick=\"btnClick3()\">JS调用OC方法 两个参数</button></div><br/>\
        <div><button class=\"btn\" type=\"button\" onclick=\"btnClick4()\">JS调用OC方法(JavaScriptCore)</button></div><br/>\
        <label>OC调用JS传入的参数<label>\
        <div id = \"returnValue\" style = \"font-size: 18px; border: 1px dotted; height: 50px;\"> </div></body>\
        </html>";
    }
    
    return _htmlString;
}

- (WKWebView *)wkWebView{
    if(!_wkWebView){
        WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc] init];
        configuration.userContentController = [[WKUserContentController alloc] init];
        WKPreferences * preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        preferences.minimumFontSize = 30.0;
        configuration.preferences = preferences;
        CGRect frame = CGRectMake(0, 90, self.view.frame.size.width, 200);
        _wkWebView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
    }
    return _wkWebView;
}
@end
