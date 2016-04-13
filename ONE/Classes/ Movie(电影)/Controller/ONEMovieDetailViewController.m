//
//  ONEMovieDetailViewController.m
//  ONE
//
//  Created by 任玉祥 on 16/4/11.
//  Copyright © 2016年 ONE. All rights reserved.
//

#import "ONEMovieDetailViewController.h"
#import "ONEDefaultCellGroupItem.h"
#import "UITableView+Extension.h"
#import "ONEMovieDetailHeaderView.h"
#import "ONEDataRequest.h"
#import "ONEMovieResultItem.h"
#import "ONEMovieCommentItem.h"
#import "ONEMovieCommentCell.h"
#import "MJRefresh.h"
#import "ONEPersonDetailViewController.h"
#import "ONEMovieMoreViewController.h"


@interface ONEMovieDetailViewController () <ONEMovieDetailHeaderViewDelegate, ONEMovieCommentCellDelegate>
/** 评审团评论的模型 */
@property (nonatomic, strong) ONEMovieResultItem *movieReviewResult;
/** tableview组 */
@property (nonatomic, strong) NSArray *groups;
/** taberheader, 电影故事详情的View */
@property (nonatomic, weak) ONEMovieDetailHeaderView *headerView;
/** 用户评论的模型 */
@property (nonatomic, strong) NSMutableArray *commentArray;

@end

@implementation ONEMovieDetailViewController
static NSString *const movieCommentID = @"movieComment";
#pragma mark - initial
- (instancetype)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        self = [super initWithStyle: UITableViewStyleGrouped];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupView];
    [self loadData];
    [self setupGroup];
}

- (void)setupView
{
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, -38, 0);
    ONEMovieDetailHeaderView *headerView = [ONEMovieDetailHeaderView tableHeaderView];
    headerView.movie_id = _movie_id;
    headerView.reviewCount = self.movieReviewResult.count;
    headerView.delegate = self;
    _headerView = headerView;
    [self.tableView registerClass:[ONEMovieCommentCell class] forCellReuseIdentifier:movieCommentID];
    self.tableView.tableHeaderView = headerView;
    
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushMoreViewController) name:ONEMovieDetailHeaderViewDidClickAllReview object:nil];
}

#pragma mark - 加载数据
#pragma mark 加载 详情数据
- (void)loadData
{
    ONEWeakSelf
    [ONEDataRequest requestMovieReview:[_movie_id stringByAppendingPathComponent:@"review/1/0"] parameters:nil success:^(ONEMovieResultItem *movieReview) {
        if (movieReview) {
            weakSelf.movieReviewResult = movieReview;
            ONEDefaultCellGroupItem *group1 = weakSelf.groups.firstObject;
            group1.items = movieReview.data;
            [weakSelf.tableView reloadData];
        }
    } failure:nil];
 
    
    [ONEDataRequest requestMovieComment:[_movie_id stringByAppendingPathComponent:@"0"] parameters:nil success:^(NSMutableArray *movieComments) {
        if (movieComments.count) {
            weakSelf.commentArray = movieComments;
            ONEDefaultCellGroupItem *group2 = weakSelf.groups.lastObject;
            group2.items = weakSelf.commentArray;
            [weakSelf.tableView reloadData];
        }
    } failure:nil];
    
}

#pragma mark 加载更多评论
- (void)loadMore
{
    if (self.commentArray.count == 0) {
        [SVProgressHUD showErrorWithStatus:@"网络繁忙,请稍后再试!"];
        [self.tableView.mj_footer endRefreshing];
        return;
    }
    
    ONEWeakSelf
    ONEMovieCommentItem *item = [self.commentArray lastObject];
    [SVProgressHUD show];
    [ONEDataRequest requestMovieComment:[_movie_id stringByAppendingPathComponent:item.comment_id] parameters:nil success:^(NSArray *movieComments) {
        [SVProgressHUD dismiss];
        if (movieComments.count) {
            [weakSelf.commentArray addObjectsFromArray:movieComments];
            [weakSelf.tableView reloadData];
        }else{
            [SVProgressHUD showErrorWithStatus:@"没有数据了哦~~"];
        }

        [weakSelf.tableView.mj_footer  endRefreshing];
    } failure:^(NSError *error) {
         [weakSelf.tableView.mj_footer  endRefreshing];
    }];
    
   
}

#pragma mark - 初始化组
- (void)setupGroup
{
    ONEDefaultCellGroupItem *group1 = [ONEDefaultCellGroupItem new];
    group1.items = self.movieReviewResult.data;
    group1.footerHeight = 40;
    group1.headerView = [ONEMovieDetailHeaderView reviewSectionHeaderView];
    group1.footerView = [ONEMovieDetailHeaderView reviewSectionFooterView];
    
    ONEDefaultCellGroupItem *group2 = [ONEDefaultCellGroupItem new];
    group2.items = self.commentArray;
    group2.headerView = [ONEMovieDetailHeaderView commentSectionHeaderView];
    group2.footerHeight = 0;
    group2.footerView = nil;
    self.groups = @[group1, group2];
}



#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.groups[section] items].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ONEMovieCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:movieCommentID];
    if (indexPath.section == 0) cell.commentCellType = ONEMovieCommentCellTypeMovieReview;
    if (indexPath.section == 1) cell.commentCellType = ONEMovieCommentCellTypeMovieComment;
    cell.commentItem = [self.groups[indexPath.section] items][indexPath.row];
    cell.movie_id = _movie_id;
    cell.delegate = self;
    return cell;
}

- (void)pushMoreViewController
{
    ONEMovieMoreViewController *moreVc = [ONEMovieMoreViewController new];
    moreVc.movie_id = _movie_id;
    moreVc.title = @"评审团短评";
    moreVc.MoreViewControllerType = ONEMovieMoreViewControllerTypeReview;
    [self.navigationController pushViewController:moreVc animated:true];
}

#pragma mark - delegate Methods
#pragma mark movieDetailHeaderView
- (void)movieDetailHeaderView:(ONEMovieDetailHeaderView *)movieDetailHeaderView didChangedStoryContent:(CGFloat)height
{
    self.headerView.height += height;
    self.tableView.tableHeaderView = self.headerView;
}
- (void)movieDetailHeaderView:(ONEMovieDetailHeaderView *)movieDetailHeaderView didClickUserIcon:(NSString *)user_id
{
    ONEPersonDetailViewController *persionDetailVc = [ONEPersonDetailViewController new];
    persionDetailVc.user_id = user_id;
    [self.navigationController pushViewController:persionDetailVc animated:true];
}
- (void)movieDetailHeaderView:(ONEMovieDetailHeaderView *)movieDetailHeaderView didClickAllBtn:(NSString *)title
{
    ONEMovieMoreViewController *moreVc = [ONEMovieMoreViewController new];
    moreVc.movie_id = _movie_id;
    moreVc.title =  title;
    moreVc.MoreViewControllerType = ONEMovieMoreViewControllerTypeMovieStory;
    [self.navigationController pushViewController:moreVc animated:true];
}

#pragma mark commentCell
- (void)movieCommentCell:(ONEMovieCommentCell *)commentCell didClickUserIcon:(NSString *)user_id
{
    ONEPersonDetailViewController *persionDetailVc = [ONEPersonDetailViewController new];
    persionDetailVc.user_id = user_id;
    [self.navigationController pushViewController:persionDetailVc animated:true];
}

#pragma mark tableView
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static ONEMovieCommentCell *cell;
    if (cell == nil) cell = [tableView dequeueReusableCellWithIdentifier:movieCommentID];
    cell.commentItem = [self.groups[indexPath.section] items][indexPath.row];

    return cell.rowHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ONEDefaultCellGroupItem *group = self.groups[section];
    return group.headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    ONEDefaultCellGroupItem *group = self.groups[section];
    return group.footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    ONEDefaultCellGroupItem *group = self.groups[section];
    return group.footerHeight;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
