//
//  LGWordPlanController.h
//  Word
//
//  Created by Charles Cao on 2018/1/30.
//  Copyright © 2018年 Charles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LGPlanTableView.h"

@interface LGWordPlanController : UIViewController

//之前为了下拉刷新
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

//编辑按钮
@property (weak, nonatomic) IBOutlet UIButton *editButton;

//词包列表
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

//选择天数
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;

// 选择个数
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;

//选择天数 table
@property (weak, nonatomic) IBOutlet LGPlanTableView *dayTable;

//选择个数 table
@property (weak, nonatomic) IBOutlet LGPlanTableView *numberTable;

@end


