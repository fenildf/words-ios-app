//
//  LGRecitePlanController.m
//  Word
//
//  Created by Charles Cao on 2018/2/6.
//  Copyright © 2018年 Charles. All rights reserved.
//

#import "LGRecitePlanController.h"
#import "LGReciteWordModel.h"
#import "LGUserManager.h"
#import "LGIndexReviewAlertView.h"
#import "LGIndexReviewModel.h"
#import "LGWordDetailController.h"
#import "LGFinishWordTaskView.h"

@interface LGRecitePlanController () <LGIndexReviewAlertViewDelegate>

/**
 每日复习框
 */
@property (nonatomic, strong) LGIndexReviewAlertView *reviewAlertView;
@property (nonatomic, strong) LGReciteWordModel *reciteWordModel;

@end

@implementation LGRecitePlanController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
	[self configIndexData];

}

- (void)configIndexData{
	__weak typeof(self) weakSelf = self;
	[self.request requestIndexRecitePlan:^(id response, LGError *error) {
		if ([weakSelf isNormal:error showInView:self.parentViewController.view]) {
			self.reciteWordModel = [LGReciteWordModel mj_objectWithKeyValues:response];
		}
	}];
}

/**
 点击开始背单词,先检查本地是否已经提醒每日复习;
 
  // 暂时不需要判断( 在 "只记新单词模式" 和 isReview 为 yes 时,不请求服务器 )

 */
- (IBAction)beginReciteWordsAction:(id)sender {
	
    
//    if ([LGUserManager shareManager].user.isTodayReview || [LGUserManager shareManager].user.studyModel == LGStudyOnlyNew){
//        [self performSegueWithIdentifier:@"indexPlanToBeginReciteWords" sender:nil];
//        return;
//    };
	
	__weak typeof(self) weakSelf = self;
	[LGProgressHUD showHUDAddedTo:self.view];
	[self.request requestReciteWordsCompletion:^(id response, LGError *error) {
		if ([self isNormal:error]) {
			NSInteger code = [NSString stringWithFormat:@"%@",response[@"code"]].integerValue;
			
			if (code == 97) {
				[weakSelf.request requestEveryDayReviewCompletion:^(id response, LGError *error) {
					if ([self isNormal:error]) {
						LGIndexReviewModel *model = [LGIndexReviewModel mj_objectWithKeyValues:response];
						model.currentWordLibName = self.reciteWordModel.packageName;
						[self showReviewAlertWithModel:model];
					}
				}];
			}else if(code == 96){
                [LGFinishWordTaskView showFinishReciteWordToView:self.view.window continueBlock:^{
                    [LGProgressHUD showHUDAddedTo:self.view];
                    [weakSelf.request requestIsReciteWordsCompletion:^(id response, LGError *error) {
                        if ([weakSelf isNormal:error]) {
                            [weakSelf performSegueWithIdentifier:@"indexPlanToBeginReciteWords" sender:nil];
                        }
                    }];
                } cancelBlock:nil];
			}else if(code == 2){
				[LGProgressHUD showMessage:response[@"message"] toView:self.view];
			}else{
				[weakSelf performSegueWithIdentifier:@"indexPlanToBeginReciteWords" sender:nil];
			}
		}
	}];
}


- (void)showReviewAlertWithModel:(LGIndexReviewModel *)reviewModel{
	if (!self.reviewAlertView) {
		self.reviewAlertView = [[NSBundle mainBundle]loadNibNamed:@"LGIndexReviewAlertView" owner:nil options:nil].firstObject;
		self.reviewAlertView.frame = self.view.window.bounds;
		self.reviewAlertView.delegate = self;
	}
	self.reviewAlertView.reviewModel = reviewModel;
	[self.view.window addSubview:self.reviewAlertView];
}

/**
 复习
 */
- (IBAction)reviewAction:(id)sender {
	
}

/**
 通过 LGReciteWordModel 更新界面
 */
- (void)setReciteWordModel:(LGReciteWordModel *)reciteWordModel{
	if (reciteWordModel == nil) return;
	_reciteWordModel = reciteWordModel;
	
	//坚持天数
	self.insistLabel.text = [NSString stringWithFormat:@"  已坚持%@天",reciteWordModel.insistDay];
	
	//剩余天数
	NSString *surplusDayStr = [NSString stringWithFormat:@"剩余\n%@天",reciteWordModel.surplusDay];
	NSMutableAttributedString *surplusDayAttributeStr = [[NSMutableAttributedString alloc]initWithString:surplusDayStr];
	[surplusDayAttributeStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:NSMakeRange(0, surplusDayAttributeStr.length)];
	[surplusDayAttributeStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, surplusDayAttributeStr.length)];
	[surplusDayAttributeStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:NSMakeRange(surplusDayAttributeStr.length-1-reciteWordModel.surplusDay.length, reciteWordModel.surplusDay.length)];
	[surplusDayAttributeStr addAttribute:NSForegroundColorAttributeName value:[UIColor lg_colorWithType:LGColor_Dark_Yellow] range:NSMakeRange(surplusDayAttributeStr.length-1-reciteWordModel.surplusDay.length, reciteWordModel.surplusDay.length)];
	self.surplusLabel.attributedText = surplusDayAttributeStr;
	
	//今天需背单词
	NSString *todayWordStr = [NSString stringWithFormat:@"%@个",reciteWordModel.userPackage.planWords];
	NSMutableAttributedString *todayWordAttributeStr = [[NSMutableAttributedString alloc]initWithString:todayWordStr];
	[todayWordAttributeStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, reciteWordModel.userPackage.planWords.length)];
	[todayWordAttributeStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:24] range:NSMakeRange(0, reciteWordModel.userPackage.planWords.length)];
	[todayWordAttributeStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(todayWordAttributeStr.length - 1, 1)];
	self.todayWordLabel.attributedText = todayWordAttributeStr;
	
	//累计已背单词
	NSString *totalWordStr = [NSString stringWithFormat:@"%@个",reciteWordModel.userAllWords];
	NSMutableAttributedString *totalWordAttributeStr = [[NSMutableAttributedString alloc]initWithString:totalWordStr];
	[totalWordAttributeStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, totalWordAttributeStr.length)];
	[totalWordAttributeStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:24] range:NSMakeRange(0, reciteWordModel.userAllWords.length)];
	[totalWordAttributeStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(totalWordAttributeStr.length - 1, 1)];
	self.totalWordLabel.attributedText = totalWordAttributeStr;
	
	
	
	//核心词汇名字
	[self.currentWordLibraryButton setTitle:reciteWordModel.packageName forState:UIControlStateNormal];
	[self.currentWordLibraryButton.titleLabel sizeToFit];
	CGFloat titleWidth = self.currentWordLibraryButton.titleLabel.frame.size.width;
	CGFloat imageWidth = self.currentWordLibraryButton.imageView.frame.size.width;
	self.currentWordLibraryButton.titleEdgeInsets = UIEdgeInsetsMake(0, -imageWidth, 0, imageWidth);
	self.currentWordLibraryButton.imageEdgeInsets = UIEdgeInsetsMake(0, titleWidth + 5, 0, -titleWidth - 5);
	
	//进度条
	self.progressBarView.progress = reciteWordModel.userPackageWords.floatValue / reciteWordModel.allWords.floatValue;
	
	//进度 label
	NSString *progressStr = [NSString stringWithFormat:@"进度 : %@/%@",reciteWordModel.userPackageWords,reciteWordModel.allWords];
	NSMutableAttributedString *progressAttributeStr = [[NSMutableAttributedString alloc]initWithString:progressStr];
	[progressAttributeStr addAttribute:NSForegroundColorAttributeName value:[UIColor lg_colorWithType:LGColor_Title_2_Color] range:NSMakeRange(0, progressAttributeStr.length)];
	[progressAttributeStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:NSMakeRange(0, progressAttributeStr.length)];
	[progressAttributeStr addAttribute:NSForegroundColorAttributeName value:[UIColor lg_colorWithType:LGColor_theme_Color] range:NSMakeRange(5, reciteWordModel.userPackageWords.length)];
	self.progressLabel.attributedText = progressAttributeStr;
	
	//今天需要背单词
	LGStudyType type = [LGUserManager shareManager].user.studyModel;
	NSString *todayStr = [NSString stringWithFormat:@"今天需要背单词 : %@/%@",reciteWordModel.todayWords, reciteWordModel.userPackage.planWords];
	if (type != LGStudyOnlyNew) {
		todayStr = [todayStr stringByAppendingString:[NSString stringWithFormat:@",今日需复习%@/%@",reciteWordModel.userReviewWords, reciteWordModel.userNeedReviewWords]];
	}
	self.todayPlanLabel.text = todayStr;
}


#pragma mark - LGIndexReviewAlertViewDelegate

- (void)skipReview{
	[self updateEveryDayReview];
	[self.reviewAlertView removeFromSuperview];
	self.reviewAlertView = nil;
}

- (void)reviewWithStatus:(LGReviewSubModel *)subModel{
	[self updateEveryDayReview];
	[self.reviewAlertView removeFromSuperview];
	self.reviewAlertView = nil;
	[self performSegueWithIdentifier:@"indexPlanToBeginReciteWords" sender:subModel];
}


/**
 通知服务器已经点击过复习弹框,为避免重复点击,本地先设置为 YES
 */
- (void)updateEveryDayReview{
	
	[LGUserManager shareManager].user.isTodayReview = YES;
	
	[self.request updateEveryDayReviewCompletion:^(id response, LGError *error) {
		if (![self isNormal:error]) {
			[LGUserManager shareManager].user.isTodayReview = NO;
		}
	}];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
	if ([segue.identifier isEqualToString:@"indexPlanToBeginReciteWords"]) {
		
			LGWordDetailController *controller = segue.destinationViewController;
		if ([sender isKindOfClass:[LGReviewSubModel class]]) {
			controller.controllerType  = LGWordDetailTodayReview;
			controller.total = ((LGReviewSubModel *)sender).count;
			controller.todayReviewStatus = ((LGReviewSubModel *)sender).status;
		}else{
			controller.controllerType  = LGWordDetailReciteWords;
			controller.total = self.reciteWordModel.userPackage.planWords;
			controller.todayNeedReciteNum = self.reciteWordModel.userPackage.planWords;
		}
	}
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
}

@end


