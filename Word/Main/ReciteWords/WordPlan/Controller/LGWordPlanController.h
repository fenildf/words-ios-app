//
//  LGWordPlanController.h
//  Word
//
//  Created by Charles Cao on 2018/1/30.
//  Copyright © 2018年 Charles. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LGPlanTableView;
@interface LGWordPlanController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

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

@interface LGPlanTableView : UITableView

//中间高亮view
@property (nonatomic, strong) UIView *selectedCellBackgroundView;

@end


