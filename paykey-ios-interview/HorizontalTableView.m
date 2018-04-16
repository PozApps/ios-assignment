//
//  HorizontalScrollView.m
//  paykey-ios-interview
//
//  Created by Ishay Weinstock on 12/16/14.
//  Copyright (c) 2014 Ishay Weinstock. All rights reserved.
//

#import "HorizontalTableView.h"

#define SEPARATOR_WIDTH 0
#define DEFAULT_CELL_WIDTH 100

@interface HorizontalTableView () <UIScrollViewDelegate>
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) NSMutableDictionary *visibleCells;
@property (nonatomic) NSMutableSet *reusePool;
@property (nonatomic, assign) NSInteger numOfCells;

@end

@implementation HorizontalTableView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        // Initialize the cell width
        self.cellWidth = DEFAULT_CELL_WIDTH;
        
        // Initialize the scroll view
        self.scrollView = [[UIScrollView alloc] init];
        [self.scrollView setDelegate:self];
        [self addSubview:self.scrollView];
        
        self.visibleCells = [NSMutableDictionary new];
        self.reusePool = [NSMutableSet new];
    }
    
    return self;
}

- (void)layoutSubviews {
    // Setting the scrollView size
    [self.scrollView setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    self.numOfCells = [[self dataSource] horizontalTableViewNumberOfCells:self];
    CGFloat scrollViewWidth = (self.cellWidth * self.numOfCells) + (SEPARATOR_WIDTH * (self.numOfCells - 1));
    [self.scrollView setContentSize:CGSizeMake(scrollViewWidth, self.scrollView.frame.size.height)];
    
    // Call layoutTableCells for creating the first visible cells
    [self layoutTableCells];
}

- (void)layoutTableCells {
    // Calculate the indexes of the visible cells
    CGFloat offsetStartX = [self.scrollView contentOffset].x;
    CGFloat offsetEndX = offsetStartX + [self.scrollView frame].size.width;
    NSInteger startingIndex = offsetStartX / (self.cellWidth + SEPARATOR_WIDTH);
    startingIndex = startingIndex < 0 ? 0 : startingIndex;
    NSInteger endingIndex = offsetEndX / (self.cellWidth + SEPARATOR_WIDTH);
    endingIndex = endingIndex >= self.numOfCells ?  self.numOfCells - 1 : endingIndex;
    
    // Preparing helper dictionary for repopulate the visibleCell dictionary
    NSMutableDictionary *originalCells = [self.visibleCells mutableCopy];
    [[self visibleCells] removeAllObjects];

    // For each of the indexes check if there is already a cell, otherwise create one
    for (NSInteger cellIndex = startingIndex; cellIndex <= endingIndex; cellIndex++) {
        NSNumber *cellIndexNum = @(cellIndex);
        // Get the cell view if it exists in the original visible cells
        UIView *cell = [originalCells objectForKey:cellIndexNum];
        if (!cell) {
            // If the cell does not exists, create a new one using the data source method, which will create a new view, or reuse an older one using the dequeuCell method
            cell = [[self dataSource] horizontalTableView:self cellForIndex:cellIndex];
            [self.visibleCells setObject:cell forKey:cellIndexNum];
            [cell setFrame:CGRectMake(cellIndex * (self.cellWidth + SEPARATOR_WIDTH), 0, self.cellWidth, self.scrollView.frame.size.height)];
            [self.scrollView addSubview:cell];
        } else {
            // If the cell exists put it back on the visibleCells dictionary
            [originalCells removeObjectForKey:cellIndexNum];
            [self.visibleCells setObject:cell forKey:cellIndexNum];
        }
    }
    
    // For each cell that is no longer visible, put it in the reuse pool for later use and remove it from the scrollView
    [originalCells enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self.reusePool addObject:obj];
        [obj removeFromSuperview];
    }];
    
    // Clear the helper dictionary
    [originalCells removeAllObjects];
}

// dequeueCell returns unsused cell in case it exists in the reusePool
- (UIView*)dequeueCell{
    UIView *poolCell = nil;
    
    for (UIView *tableViewCell in [self reusePool]) {
        poolCell = tableViewCell;
        break;
    }
    
    if (poolCell) {
        [[self reusePool] removeObject:poolCell];
    }
    
    return poolCell;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // For each scroll redraw the table view
    [self layoutTableCells];
}

@end
