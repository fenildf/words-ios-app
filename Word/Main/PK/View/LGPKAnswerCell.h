//
//  LGPKAnswerCell.h
//  Word
//
//  Created by Charles Cao on 2018/3/22.
//  Copyright © 2018年 Charles. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LGPKAnswerCellType) {
	LGPKAnswerCellNormal,
	LGPKAnswerCellRight,
	LGPKAnswerCellWrong,
};

@interface LGPKAnswerCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *answerLabel;

@property (nonatomic, assign) LGPKAnswerCellType type;

@property (nonatomic, assign) BOOL wrong;


@end
