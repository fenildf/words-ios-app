//
//  LGAtPKController.m
//  Word
//
//  Created by Charles Cao on 2018/3/22.
//  Copyright © 2018年 Charles. All rights reserved.
//

#import "LGAtPKController.h"
#import "LGPKAnswerCell.h"
#import "LGTool.h"
#import "JPUSHService.h"
#import "LGPlayer.h"
#import "LGJPushReceiveMessageModel.h"

//倒计时时间
NSInteger countDown = 20;

@interface LGAtPKController () <UITableViewDelegate, UITableViewDataSource>
{
	dispatch_source_t timer;
}
@property (nonatomic, assign) NSInteger currentWordIndex;//当前单词 在 pkModel.words 中的 index
@property (nonatomic, strong) LGPKWordModel *currentWordModel; //当前显示单词

@property (nonatomic, assign) NSInteger currentTime; //当前倒计时

@end

@implementation LGAtPKController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self.navigationController setNavigationBarHidden:YES];
	[self.userHeadImageView sd_setImageWithURL:[NSURL URLWithString:WORD_DOMAIN(self.currentUserModel.image)] placeholderImage:[UIImage imageNamed:@"pk_default_opponent"]];
	[self.opponentImageView sd_setImageWithURL:[NSURL URLWithString:WORD_DOMAIN(self.opponentModel.image)] placeholderImage:[UIImage imageNamed:@"pk_default_opponent"]];
	self.currentWordModel = self.pkModel.words.firstObject;
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[self addNotification];
}

- (void)viewDidDisappear:(BOOL)animated{
	[super viewDidDisappear:animated];
	[self removeNotification];
}

- (void)addNotification{
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
	/*********************** 接收自定义消息 **************************/
	
	[defaultCenter addObserver:self selector:@selector(networkDidReceiveMessage:) name:kJPFNetworkDidReceiveMessageNotification object:nil];
	
	/*********************** app 退到后台时 **************************/

	[defaultCenter addObserver:self selector:@selector(applicationExit) name:UIApplicationWillResignActiveNotification object:nil];
	
	/*********************** 激活 app 时 **************************/
	[defaultCenter addObserver:self selector:@selector(applicationBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)removeNotification{
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter removeObserver:self name:kJPFNetworkDidReceiveMessageNotification object:nil];
	[defaultCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	[defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)networkDidReceiveMessage:(NSNotification *)notification {
	
	LGJPushReceiveMessageModel *pushModel = [LGJPushReceiveMessageModel mj_objectWithKeyValues:notification.userInfo];
	if (pushModel.extras.type == 4) {
		LGAtPKModel *pkModel = pushModel.extras.message;
		LGAccuracyModel *currentUser;
		LGAccuracyModel *opponentUser;
		if ([pkModel.user1.uid isEqualToString:self.currentUserModel.uid]) {
			currentUser  = pkModel.user1;
			opponentUser = pkModel.user2;
		}else{
			currentUser  = pkModel.user2;
			opponentUser = pkModel.user1;
		}
		self.userWinLabel.text = [NSString stringWithFormat:@"%@%%",currentUser.accuracy];
		self.opponentWinLabel.text = [NSString stringWithFormat:@"%@%%",opponentUser.accuracy];
		CGFloat tem = currentUser.accuracy.floatValue + opponentUser.accuracy.floatValue;
		self.winProgressView.progress = tem == 0 ? 0.5 : currentUser.accuracy.integerValue / tem;
	}
	
}

//退出 app
- (void)applicationExit{
	[self.request requestPKExit:self.currentUserModel.uid totalId:self.pkModel.totalId currentQuestionIndex:self.currentWordIndex + 1 duration:countDown - self.currentTime];
}


/**
 激活 app,重连 Pk
 code = 0 超时失败,返回首页
 code = 1 重连成功
 */
- (void)applicationBecomeActive{
	[LGProgressHUD showHUDAddedTo:self.view];
	[self.request requestPKConnect:self.currentUserModel.uid totalId:self.pkModel.totalId completion:^(id response, LGError *error) {
		if ([self isNormal:error showInView:self.view.window]) {
			
			/**
			 重连后应该到第几题,如果超过题目总数则调用结果接口
			 如果没超过题目总数,则跳转到该题目
			 num 从 1 开始
			 */
			NSInteger num = [NSString stringWithFormat:@"%@",response[@"num"]].integerValue;
			if (num > self.pkModel.words.count) {
				[self requestFinishPK];
			}else{
				NSInteger time = [NSString stringWithFormat:@"%@",response[@"time"]].integerValue;
				[self setCurrentWordModel:self.pkModel.words[num - 1] beginCountDown:time];
			}
		}else{
			[self.navigationController popToRootViewControllerAnimated:YES];
		}
	}];
}

- (IBAction)playAudio:(id)sender {
	[[LGPlayer sharedPlayer]playWithUrl:self.currentWordModel.uk_audio completion:nil];
}


#pragma mark - setter getter




/**
 设置当前 题目

 @param currentWordModel 当前题目
 @param time 题目倒计时时长
 */
- (void)setCurrentWordModel:(LGPKWordModel *)currentWordModel beginCountDown:(NSInteger)time{
	_currentWordModel = currentWordModel;
	self.wordLabel.text = currentWordModel.word;
	[self.audioButton setTitle:currentWordModel.phonetic_uk forState:UIControlStateNormal];
	self.tableView.allowsSelection = YES;
	[self.tableView reloadData];
	[self beginCountDown:time];
}

- (void)setCurrentWordModel:(LGPKWordModel *)currentWordModel{
	_currentWordModel  = currentWordModel;
	[self setCurrentWordModel:currentWordModel beginCountDown:countDown];
}

- (void)setCurrentTime:(NSInteger)currentTime{
	_currentTime = currentTime;
	self.timeLabel.text = [NSString stringWithFormat:@"%lds",currentTime];
	if (currentTime == 0) {
		[self nextQuestionWithCurrentAnswer:@"" duration:countDown];
	}
}

- (NSInteger)currentWordIndex{
	return [self.pkModel.words indexOfObject:self.currentWordModel];
}

#pragma mark -
/**
 倒计时

 @param second 倒计时总共时长
 */
- (void)beginCountDown:(NSInteger)second{
	if (timer) {
		dispatch_source_cancel(timer);
	}
	timer = [LGTool beginCountDownWithSecond:second completion:^(NSInteger currtentSecond) {
		self.currentTime = currtentSecond;
	}];
}

/**
 下一题,先提交当前题目答案,不用等待服务器 response ,再刷新下一题
 如果当前题目为最后一题,则到结果页或者等待对手页

 @param answer 当前答案
 @param duration 答题所用时间
 */
- (void)nextQuestionWithCurrentAnswer:(NSString *)answer duration:(NSInteger)duration{
	//提交答案
	[self commitAnswer:answer duration:duration];
	
	NSArray<LGPKWordModel *> *words = self.pkModel.words;
	if (self.currentWordIndex == words.count - 1) {
		[self requestFinishPK];
	}else{
		self.currentWordModel = words[self.currentWordIndex + 1];

	}
}


/**
 请求结束 PK
 code = 1,跳转结果页
 code = 2,显示等待对手页面
 */
- (void)requestFinishPK{
	[LGProgressHUD showHUDAddedTo:self.view];
	[self.request requestPKFinish:self.opponentModel.uid totalId:self.pkModel.totalId completion:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			NSInteger code = [NSString stringWithFormat:@"%@",response[@"code"]].integerValue;
			if (code == 1) {
				[self performSegueWithIdentifier:@"PKToResult" sender:nil];
			}else{
				[self showWait];
			}
		}
	}];
}


/**
 显示等待对手页面,请求
 code = 1结果页
 code = 2每2秒请求一次轮询接口(requestPKPoll)
 */
- (void)showWait {
	self.tableView.hidden   = YES;
	self.audioButton.hidden = YES;
	self.wordLabel.hidden   = YES;
	self.timeLabel.hidden   = YES;
	self.waitImageView.hidden = NO;
	[LGProgressHUD showHUDAddedTo:self.view];
	[self.request requestPKPoll:self.opponentModel.uid totalId:self.pkModel.totalId completion:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			NSInteger code = [NSString stringWithFormat:@"%@",response[@"code"]].integerValue;
			if (code == 1) {
				[self performSegueWithIdentifier:@"PKToResult" sender:nil];
			}else{
				//2秒之后
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					[self showWait];
				});
			}
			
		}
	}];
}

/**
 请求 PK 结果
 */
- (void)requestPKResult{
	[LGProgressHUD showHUDAddedTo:self.view];
	[self.request requestPKResult:self.opponentModel.uid totalId:self.pkModel.totalId completion:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			NSLog(@"%@",response);
		}
	}];
}

/**
 提交答案

 @param chooseAnswer 用户答案
 @param duration 使用时长
 */
- (void)commitAnswer:(NSString *)chooseAnswer duration:(NSInteger)duration{
	
	LGPKAnswerType type = [chooseAnswer isEqualToString:self.currentWordModel.answer] ? LGPKAnswerTrue : LGPKAnswerFalse;
	
	[self.request commitPKAnswer:type totalId:self.pkModel.totalId wordId:self.currentWordModel.wordsId answer:chooseAnswer duration:duration completion:^(id response, LGError *error) {
		
	}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.pkModel.words[self.currentWordIndex].selectArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	LGPKAnswerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LGPKAnswerCell"];
	LGPKWordModel *pkWord = self.pkModel.words[self.currentWordIndex];
    cell.answerLabel.text = pkWord.selectArray[indexPath.section];
	[cell setNormal];
	return cell;
}

#pragma mark -UITableViewDelegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 48;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
	return 0.1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//答题所用时间
	if (timer) {
		dispatch_source_cancel(timer);
	}
	NSInteger duration = countDown - self.currentTime;
	
	tableView.allowsSelection = NO;
	
	//如果选择不是正确答案时,把正确答案改成选中状态(selected),用户选择的错误答案改成错误高亮(setWrong方法)
	if (indexPath.section != self.currentWordModel.trueAnswerIndex) {
		
		NSIndexPath *trueIndexPath = [NSIndexPath indexPathForRow:0 inSection:self.currentWordModel.trueAnswerIndex];
		LGPKAnswerCell *trueCell = [tableView cellForRowAtIndexPath:trueIndexPath];
		trueCell.selected = YES;
		
		LGPKAnswerCell *userCell = [tableView cellForRowAtIndexPath:indexPath];
		[userCell setWrong];
	}
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		NSString *userAnswer = self.currentWordModel.selectArray[indexPath.section];
		[self nextQuestionWithCurrentAnswer:userAnswer duration:duration];
	});
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
