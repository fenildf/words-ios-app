//
//  LGWordDetailController.m
//  Word
//
//  Created by Charles Cao on 2018/2/7.
//  Copyright © 2018年 Charles. All rights reserved.
//

#import "LGWordDetailController.h"
#import "LGWordDetailCell.h"
#import "LGWordDetailHeaderFooterView.h"
#import "LGPlayer.h"
#import "LGWordErrorViewController.h"
#import "LGTodayReviewWordModel.h"
#import "LGFinishWordTaskView.h"

@interface LGWordDetailController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) LGWordDetailModel *detailModel; //当前单词,重写 setter 刷新界面

@end

@implementation LGWordDetailController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	if (self.controllerType == LGWordDetailReciteWords)
	{
		[self requestReciteWordsData];
		
	}else if (self.controllerType == LGWordDetailEbbinghausReview)
	{
		[self requestWordDetailWidthID:self.ebbinghausReviewWordIdArray.firstObject];
			
	}else if (self.controllerType == LGWordDetailTodayReview)
	{
		[self requestTodayReviewWord];
		[self.vagueOrForgotButton setTitle:@"忘记" forState:UIControlStateNormal];
				
	}else if (self.controllerType == LGWordDetailReview)
	{
		[self.vagueOrForgotButton setTitle:@"忘记" forState:UIControlStateNormal];
		self.currentNum = @(self.total.integerValue - self.reviewWordIdArray.count + 1).stringValue;
		[self requestWordDetailWidthID:self.reviewWordIdArray.firstObject];
	
	}else if (self.controllerType == LGWordDetailDictationPrompt)
	{
		self.statusViewHeightConstraint.constant = 0;
		self.detailModel = self.dictationPromptWord;
		self.familiarItemButton.hidden = YES;
		self.title = @"听写练习";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"backArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissController)];
    }else if (self.controllerType == LGWordDetailSearch){
        self.title = self.searchWordStr;
        self.statusViewHeightConstraint.constant = 0;
        self.familiarItemButton.hidden = YES;
        [self requestWordDetailWidthID:self.searchWordID];
    }
	
	[self.wordTabelView registerNib:[UINib nibWithNibName:@"LGWordDetailHeaderFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"LGWordDetailHeaderFooterView"];
}

#pragma mark - Setter  Getter

- (void)setCurrentNum:(NSString *)currentNum{
	_currentNum = currentNum;
	self.title = [NSString stringWithFormat:@"%ld/%ld",currentNum.integerValue,self.total.integerValue];
}

- (void)setTotal:(NSString *)total{
	_total = total;
	self.title = [NSString stringWithFormat:@"%ld/%ld",self.currentNum.integerValue,total.integerValue];
}

- (void)setDetailModel:(LGWordDetailModel *)detailModel {
	_detailModel = detailModel;
	self.wordLabel.text = detailModel.words.word;
	self.translateLabel.text = detailModel.words.translate;
	if (detailModel.did) {
		self.currentNum = @(detailModel.did.integerValue + 1).stringValue;
	}
	[self.playerButton setTitle:[NSString stringWithFormat:@"  %@",detailModel.words.phonetic_us] forState:UIControlStateNormal];
	[self.wordTabelView reloadData];
}

#pragma mark - 请求数据

/**
 * 请求背单词接口,code = 98进入复习模式
 */
- (void)requestReciteWordsData {
	[LGProgressHUD showHUDAddedTo:self.view];
	[self.request requestReciteWordsCompletion:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			NSInteger code = [NSString stringWithFormat:@"%@",response[@"code"]].integerValue;
			if (code == 1){
				self.detailModel = [LGWordDetailModel mj_objectWithKeyValues:response];
			}else if (code == 98){
				[self requestEbbinghausReviewWordArray];
			}
		}
	}];
}

/**
 通过单词id请求单词详情
 
 @param wordID 单词id
 */
- (void)requestWordDetailWidthID:(NSString *)wordID{
	[LGProgressHUD showHUDAddedTo:self.view];
	[self.request requestWordDetailWidthID:wordID completion:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			self.detailModel = [LGWordDetailModel mj_objectWithKeyValues:response];
		}
	}];
}

/**
 请求艾宾浩斯复习列表
 */
- (void)requestEbbinghausReviewWordArray{
	[self.request requestEbbinghausReviewList:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			self.ebbinghausReviewWordIdArray  = [NSMutableArray arrayWithArray:response[@"words"]];
			[self pushNextWordDetailController:LGWordDetailEbbinghausReview animated:NO];
		}
	}];
}


/**
 请求今日复习单词
 */
- (void)requestTodayReviewWord {
	
	[self.request requestTodayReviewWordsWithStatus:self.todayReviewStatus completion:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			LGTodayReviewWordModel *reviewWordModel = [LGTodayReviewWordModel mj_objectWithKeyValues:response];
			self.total = reviewWordModel.all;
			self.currentNum = @(reviewWordModel.did.integerValue + 1).stringValue;
			[self requestWordDetailWidthID:reviewWordModel.wordsId];
		}
	}];
}

#pragma mark -

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Action

//播放语音
- (IBAction)playeAction:(id)sender {
	[[LGPlayer sharedPlayer] playWithUrl:self.detailModel.words.us_audio completion:^(LGError *error) {
		[self isNormal:error];
	}];
}


//熟识
- (IBAction)familiarAction:(id)sender {
	[self updateWordStatus:LGWordStatusFamiliar];
}

//认识
- (IBAction)knowAction:(id)sender {
	[self updateWordStatus:LGWordStatusKnow];
}

//不认识
- (IBAction)notKnowAction:(id)sender {
	[self updateWordStatus:LGWordStatusIncognizance];
}

// 在背单词模式下标记为模糊,其他复习模式下标记为忘记
- (IBAction)vagueOrForgotAction:(id)sender {
	
	[self updateWordStatus:self.controllerType == LGWordDetailReciteWords ? LGWordStatusVague : LGWordStatusForget];
}

- (void)dismissController{
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 修改单词状态

- (void)updateWordStatus:(LGWordStatus) status{
	
	if (self.detailModel.words.ID == nil) return;
	
	switch (self.controllerType) {
		case LGWordDetailReciteWords:
			[self updateReciteWordStatus:status];
			break;
			
		case LGWordDetailEbbinghausReview:
			[self updateEbbinghausReviewWordStatus:status];
			break;
			
		case LGWordDetailTodayReview:
			[self updateReviewWordStatus:status];
			break;
		case LGWordDetailReview:
			[self updateReviewWordStatus:status];
			break;
		default:
			break;
	}
}


/**
 背单词模式下更新单词状态,并跳转到下一个单词
 
 @param status 单词状态
 */
- (void)updateReciteWordStatus:(LGWordStatus) status {
	[LGProgressHUD showHUDAddedTo:self.view];
	[self.request updateWordStatus:self.detailModel.words.ID status:status completion:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			[self pushNextWordDetailController:LGWordDetailReciteWords  animated:YES];
		}
	}];
}


/**
 在艾宾浩斯复习模式下更新单词状态,并跳转到下一个单词
 循环复习 id 列表, 如果标记单词为认识,则从复习id列表中移除该单词,
 如果标记为其他状态,则把该单词移动到复习列表最后,直到所有单词都标记为认识
 当复习id列表为空时,进入背单词模式(LGWordDetailReciteWords)
 
 @param status 单词状态
 */
- (void)updateEbbinghausReviewWordStatus:(LGWordStatus) status {
	[LGProgressHUD showHUDAddedTo:self.view];
	[self.request updateWordStatus:self.detailModel.words.ID status:status completion:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			NSString *wordID = self.ebbinghausReviewWordIdArray.firstObject;
			[self.ebbinghausReviewWordIdArray removeObjectAtIndex:0];
			if (status != LGWordStatusKnow) {
				[self.ebbinghausReviewWordIdArray addObject:wordID];
			}
			LGWordDetailControllerType tempType = ArrayNotEmpty(self.ebbinghausReviewWordIdArray) ? LGWordDetailEbbinghausReview : LGWordDetailReciteWords;
			[self pushNextWordDetailController:tempType  animated:YES];
		}
	}];
}


/**
 复习模式下修改单词状态,并跳转到下一个单词
 
 @param status 单词状态
 */
- (void)updateReviewWordStatus:(LGWordStatus) status {
	[LGProgressHUD showHUDAddedTo:self.view];
	[self.request updateReviewWordStatus:status wordId:self.detailModel.words.ID completion:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			if (self.controllerType == LGWordDetailReview) {
				[self.reviewWordIdArray removeObjectAtIndex:0];
			}
			[self pushNextWordDetailController:self.controllerType  animated:YES];
		}
	}];
}

/**
 跳转到下一个 WordDetailController
 当当前进度(currentNum) 等于 总进度(total)时,显示完成任务提醒框
 @param type  下一个 controller 的模式
 @param animated 是否跳转动画
 */
- (void)pushNextWordDetailController:(LGWordDetailControllerType) type animated:(BOOL)animated{
	
	if (self.currentNum.integerValue >= self.total.integerValue) {
        
        LGFinishWordTaskType finishType;
        if (type == LGWordDetailReciteWords || type == LGWordDetailEbbinghausReview) {
            finishType = LGFinishReciteWords;
        }else{
            finishType = LGFinishReview;
        }
        
		[LGFinishWordTaskView showFinishToView:self.view.window type:finishType sureBlock:^{
			[self.navigationController popViewControllerAnimated:YES];
		}];
		
	}else{
		LGWordDetailController *wordDetailController = STORYBOARD_VIEWCONTROLLER(@"ReciteWords", @"LGWordDetailController");
		wordDetailController.controllerType = type;
		wordDetailController.total = self.total;
		wordDetailController.reviewWordIdArray = self.reviewWordIdArray;
		wordDetailController.ebbinghausReviewWordIdArray = self.ebbinghausReviewWordIdArray;
		wordDetailController.todayReviewStatus = self.todayReviewStatus;
		NSMutableArray *controllerArray = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
		[controllerArray removeObject:self];
		[controllerArray addObject:wordDetailController];
		[self.navigationController setViewControllers:controllerArray animated:animated];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.detailModel.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	
	return self.detailModel.dataSource[section].cellContent.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.wordTabelView) {
		LGWordDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LGWordDetailCell"];
		NSString *content = self.detailModel.dataSource[indexPath.section].cellContent[indexPath.row];
		BOOL isFirst = indexPath.row == 0;
		BOOL isLast  = indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1;
		[cell setContentStr:content isFirst:isFirst isLast:isLast];
		return cell;
	}
	return nil;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	LGWordDetailHeaderFooterView *heaerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"LGWordDetailHeaderFooterView"];
	heaerView.titleLabel.text = self.detailModel.dataSource[section].sectionTitle;
	return heaerView;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"WordDetailToError"]) {
		LGWordErrorViewController *controller = segue.destinationViewController;
		controller.wordID = self.detailModel.words.ID;
	}
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
}


@end
