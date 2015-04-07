//
//  DCDayEventsController.m
//  DrupalCon
//
//  Created by Olexandr on 3/10/15.
//  Copyright (c) 2015 Lemberg Solution. All rights reserved.
//

#import "DCDayEventsController.h"
#import "DCEventCell.h"
#import "DCDayEventsDataSource.h"
#import "DCTimeRange+DC.h"
#import "DCTime+DC.h"
#import "DCType+DC.h"
#import "DCSpeaker+DC.h"
#import "DCLevel+DC.h"
#import "DCEventDetailViewController.h"
#import "DCLimitedNavigationController.h"
#import "DCAppFacade.h"
#import "DCTrack+DC.h"
#import "DCInfoEventCell.h"
#import "DCFavoriteEventsDataSource.h"
@interface DCDayEventsController ()<DCEventCellProtocol>

@property (nonatomic) IBOutlet UILabel *noItemsLabel;

@property (nonatomic, strong) NSString* stubMessage;
@property (nonatomic) DCEventDataSource *eventsDataSource;

@property (nonatomic, strong) DCEventCell* cellPrototype;

@end

@implementation DCDayEventsController


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.stubMessage)
    {
        [self registerCells];
        [self initDataSource];
        
        self.cellPrototype = [self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([DCEventCell class])];
    }
    else
    {
        self.tableView.dataSource = nil;
        self.tableView.hidden = YES;
        
        self.noItemsLabel.hidden = NO;
        self.noItemsLabel.text = self.stubMessage;
    }
}

- (void) dealloc
{
    self.stubMessage = nil;
    self.cellPrototype = nil;
}

- (void) initAsStubController:(NSString*)noEventMessage
{
    self.stubMessage = noEventMessage;
}

- (void)updateEvents
{
    [self.eventsDataSource reloadEvents];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)registerCells
{
    NSString *className = NSStringFromClass([DCEventCell class]);
    [self.tableView registerNib:[UINib nibWithNibName:className bundle:nil] forCellReuseIdentifier:className];
}

- (void)initDataSource
{
    self.eventsDataSource = [self dayEventsDataSource];//[[DCDayEventsDataSource alloc] initWithTableView:self.tableView eventStrategy:self.eventsStrategy date:self.date];
    __weak typeof (self) weakSelf = self;
    [self.eventsDataSource setPrepareBlockForTableView:^UITableViewCell* (UITableView * tableView, NSIndexPath *indexPath) {
        NSString *cellIdentifier = NSStringFromClass([DCEventCell class]);
        DCEventCell *cell = (DCEventCell*)[tableView dequeueReusableCellWithIdentifier: cellIdentifier];
        
        DCEvent *event = [weakSelf.eventsDataSource eventForIndexPath:indexPath];
        NSInteger eventsCountInSection = [weakSelf.eventsDataSource tableView:nil numberOfRowsInSection:indexPath.section];
        cell.isLastCellInSection = (indexPath.row == eventsCountInSection - 1)? YES : NO;
        cell.isFirstCellInSection = !indexPath.row;

        [cell initData:event delegate:weakSelf];
        // Some conditions for favorite events
        NSString *titleForNextSection = [weakSelf.eventsDataSource titleForSectionAtIdexPath:indexPath.section + 1];
        cell.separatorCellView.hidden = ( titleForNextSection && cell.isLastCellInSection)? YES : NO;
        if ([weakSelf.eventsStrategy leftSectionContainerColor]) {
            cell.leftSectionContainerView.backgroundColor = [weakSelf.eventsStrategy leftSectionContainerColor];
        }
        
        return cell;
    }];
}

- (DCEventDataSource *)dayEventsDataSource
{
    if (self.eventsStrategy.strategy == EDCEeventStrategyFavorites) {
        return [[DCFavoriteEventsDataSource alloc] initWithTableView:self.tableView eventStrategy:self.eventsStrategy date:self.date];

    }
    return [[DCDayEventsDataSource alloc] initWithTableView:self.tableView eventStrategy:self.eventsStrategy date:self.date];
}

- (void)didSelectCell:(DCEventCell *)eventCell {
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:eventCell];
    DCEvent *selectedEvent = [self.eventsDataSource eventForIndexPath:cellIndexPath];
    [self.parentProgramController openDetailScreenForEvent:selectedEvent];
}


#pragma mark - UITableView delegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DCEvent *event = [self.eventsDataSource eventForIndexPath:indexPath];
    self.cellPrototype.isFirstCellInSection = !indexPath.row;
    [self.cellPrototype initData:event delegate:self];
    
    return [self.cellPrototype getHeightForEvent:event isFirstInSection:!indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self.eventsDataSource titleForSectionAtIdexPath:section]? 30 : 0.;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    DCInfoEventCell *headerViewCell = (DCInfoEventCell*)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([DCInfoEventCell class])];

    NSString *title = [self.eventsDataSource titleForSectionAtIdexPath:section];
    if(title) {
        headerViewCell.titleLabel.text = title;
        return [headerViewCell contentView];
    }
    
    UIView *v = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 0.0)];
    v.backgroundColor = [UIColor whiteColor];
    return v;
}

@end
