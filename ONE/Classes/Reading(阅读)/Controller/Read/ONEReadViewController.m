//
//  ONEReadViewController.m
//  ONE
//
//  Created by 任玉祥 on 16/4/1.
//  Copyright © 2016年 ONE. All rights reserved.
//

#import "ONEReadViewController.h"
#import "ONEReadTitleButton.h"
#import "ONEReadTableViewController.h"
#import "ONEReadEssayViewController.h"
#import "ONEReadSerialViewController.h"
#import "ONEReadQuestionViewController.h"
#import "ONEReadAdView.h"
#import "ONEDataRequest.h"
#import "ONEReadAdItem.h"
#import "ONEReadListItem.h"

@interface ONEReadViewController () <ONEReadAdViewDelegate, UIScrollViewDelegate>
@property (nonatomic, weak) UIView              *adCoverView;
@property (nonatomic, weak) ONEReadAdView       *adView;
@property (nonatomic, strong) NSArray           *adDatas;

@property (nonatomic, weak) UIScrollView        *scrollView;
@property (nonatomic, weak) UIView              *titlesView;
@property (nonatomic, weak) UIView              *titlesLineView;
@property (nonatomic, weak) ONEReadTitleButton  *selectedBtn;

@property (nonatomic, strong) ONEReadListItem   *readList;
@end

@implementation ONEReadViewController

#pragma mark - lazy load
- (ONEReadAdView *)adView
{
    if (_adView == nil) {
        ONEReadAdView *adView = [[ONEReadAdView alloc] initWithFrame:_adCoverView.bounds];
        adView.delegate = self;
        adView.intervalTime = 4.0;
        [self.adCoverView addSubview:_adView = adView];
    }
    return _adView;
}

#pragma mark - initial
- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = false;
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupAdView];
    [self loadAdData];
    [self loadReadList];
    [self setupAllViewController];
}

- (void)setupAllViewController
{
    [self addChildViewController:[ONEReadEssayViewController new]];
    [self addChildViewController:[ONEReadSerialViewController new]];
    [self addChildViewController:[ONEReadQuestionViewController new]];
    
}

- (void)setupAdView
{
    UIView *adCoverView = [[UIView alloc] initWithFrame:CGRectMake(0, ONENavBMaxY, ONEScreenWidth, ONEScreenWidth * 0.4)];
    adCoverView.backgroundColor = [UIColor lightGrayColor];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top10"]];
    imageView.frame = adCoverView.bounds;
    [adCoverView addSubview:imageView];
    [self.view addSubview:_adCoverView = adCoverView];
}

#pragma mark - load data
/** 阅读列表 */
- (void)loadReadList
{
    [SVProgressHUD show];
    [ONEDataRequest requestReadList:nil parameters:nil succsee:^(ONEReadListItem *responseObject) {
        if (responseObject) {
            self.readList = responseObject;
        }
        [SVProgressHUD dismiss];
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
    }];
}

/** 广告 */
- (void)loadAdData
{
    [ONEDataRequest requestReadAdSuccess:^(NSArray *adDatas) {
        if (!adDatas.count) return;
        self.adDatas = adDatas;
    } failure:nil];
}
- (void)setAdDatas:(NSArray *)adDatas
{
    _adDatas = adDatas;
    
    NSMutableArray *imageNames = [NSMutableArray array];
    for (ONEReadAdItem *adItem in adDatas) [imageNames addObject:adItem.cover];
    self.adView.imageNames = imageNames;
}

- (void)setReadList:(ONEReadListItem *)readList
{
    _readList = readList;
    [self setupBaseView];
}


#pragma mark - scrollView
- (void)setupBaseView
{
    NSArray *titles = @[@"短篇", @"连载", @"问题"];
  
    // scrollView
    {
        CGFloat scrollViewY = CGRectGetMaxY(self.adCoverView.frame);
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, scrollViewY, ONEScreenWidth, ONEScreenHeight - scrollViewY - ONETabBarH)];
        scrollView.delegate = self;
        scrollView.contentSize = CGSizeMake(scrollView.width * titles.count, 0);
        scrollView.pagingEnabled = true;
        scrollView.scrollsToTop = false;
        scrollView.showsVerticalScrollIndicator = false;
        scrollView.showsHorizontalScrollIndicator = false;
        [self.view addSubview:_scrollView = scrollView];
    }

    
    // titlesView
    {
        UIView *titlesView = [[UIView alloc] initWithFrame:CGRectMake(0, _scrollView.y, ONEScreenWidth, ONETitleViewH)];
        titlesView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
        [self.view addSubview: _titlesView = titlesView];
    }
    
    // titleBtn
    {
        CGFloat titleButtonW = ONEScreenWidth / titles.count;
        for (NSInteger i = 0; i < titles.count; i++)
        {
            ONEReadTitleButton *titleBtn = [[ONEReadTitleButton alloc] initWithFrame:CGRectMake(i * titleButtonW, 0, titleButtonW, _titlesView.height)];
            titleBtn.tag = i;
            [titleBtn setTitle:titles[i] forState:UIControlStateNormal];
            [titleBtn addTarget:self action:@selector(titleBtnClick:) forControlEvents:UIControlEventTouchUpInside];
            [_titlesView addSubview:titleBtn];
            
            if (i == 0) [self titleBtnClick:titleBtn];
        }
    }
    
    // titleLineView
    {
        CGFloat titleLineViewH = 2;
        CGFloat titleLineViewY = ONETitleViewH - titleLineViewH;
        
        UIView *titlesLineView = [UIView new];
        titlesLineView.backgroundColor = [_selectedBtn titleColorForState:UIControlStateSelected];
        titlesLineView.frame = CGRectMake(0, titleLineViewY, 0, titleLineViewH);
        [self.titlesView addSubview:_titlesLineView = titlesLineView];
        
        [_selectedBtn.titleLabel sizeToFit];
        titlesLineView.width = _selectedBtn.titleLabel.width;
        titlesLineView.centerX = _selectedBtn.width * 0.5;
    }
}

#pragma mark - Events
- (void)titleBtnClick:(ONEReadTitleButton *)btn
{
    if (self.selectedBtn == btn) return;
    
    self.selectedBtn.selected = false;
    btn.selected = true;
    self.selectedBtn = btn;
    
    [UIView animateWithDuration:0.2 animations:^{

        self.titlesLineView.centerX = btn.centerX;
        self.titlesLineView.width = btn.titleLabel.width;
        
        CGPoint offset = self.scrollView.contentOffset;
        offset.x = btn.tag * self.scrollView.width;
        self.scrollView.contentOffset = offset;
        
    } completion:^(BOOL finished) {
        // 懒加载
        ONEReadTableViewController *childVc = self.childViewControllers[btn.tag];
        childVc.view.frame = self.scrollView.bounds;
        childVc.readList   = self.readList;
        [self.scrollView addSubview:childVc.view];
        
    }];
    
    
    // 设置滚动到顶部
    for (NSInteger i = 0; i < self.childViewControllers.count; i++)
    {
        UIViewController *childVc = self.childViewControllers[i];
        
        if (!childVc.isViewLoaded) continue;
        if (![childVc.view isKindOfClass:[UIScrollView class]]) continue;

        UIScrollView *scrollView = (UIScrollView *)childVc.view;
        scrollView.scrollsToTop = i == btn.tag;

    }
}

#pragma mark - dcrollView delegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger index = scrollView.contentOffset.x / ONEScreenWidth;
    [self titleBtnClick:self.titlesView.subviews[index]];
}



#pragma mark - ONEReadAdViewDelegate
- (void)readAdView:(ONEReadAdView *)readAdView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ONELog(@"点击了广告 %zd == %zd", indexPath.section, indexPath.row)
}

@end
