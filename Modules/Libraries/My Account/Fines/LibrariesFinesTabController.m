#import "LibrariesFinesTabController.h"
#import "MITLoadingActivityView.h"
#import "MobileRequestOperation.h"
#import "LibrariesFinesTableViewCell.h"
#import "LibrariesDetailViewController.h"

@interface LibrariesFinesTabController ()
@property (nonatomic,retain) MITLoadingActivityView *loadingView;
@property (nonatomic,retain) NSDictionary *loanData;
@property (nonatomic,retain) MobileRequestOperation *operation;
@property (nonatomic,retain) NSDate *lastUpdate;

- (void)setupTableView;
- (void)updateLoanData;
@end

@implementation LibrariesFinesTabController
@synthesize parentController = _parentController,
            tableView = _tableView;

@synthesize loadingView = _loadingView,
            loanData = _loanData,
            operation = _operation,
            lastUpdate = _lastUpdate,
            headerView = _headerView;

- (id)initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
        self.tableView = tableView;
        
        if (tableView) {
            [self setupTableView];
            [self updateLoanData];
        }
    }
    
    return self;
}

- (void)dealloc {
    self.parentController = nil;
    self.tableView = nil;
    self.headerView = nil;
    self.loadingView = nil;
    self.loanData = nil;
    self.operation = nil;
    self.lastUpdate = nil;

    [super dealloc];
}

- (void)setupTableView
{
    {
        CGRect loadingFrame = self.tableView.bounds;
        MITLoadingActivityView *loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                        UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor whiteColor];
        self.loadingView = loadingView;
    }
    
    {
        LibrariesFinesSummaryView *headerView = [[[LibrariesFinesSummaryView alloc] initWithFrame:CGRectZero] autorelease];
        headerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth);
        self.headerView = headerView;
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing == NO)
    {
        NSArray *book = [self.loanData objectForKey:@"items"];
        LibrariesDetailViewController *viewControler = [[[LibrariesDetailViewController alloc] initWithBookDetails:[book objectAtIndex:indexPath.row]
                                                                                                        detailType:LibrariesDetailFineType] autorelease];
        [self.parentController.navigationController pushViewController:viewControler
                                                              animated:YES];
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *items = [self.loanData objectForKey:@"items"];
    if (items) {
        return [items count];
    } else {
        return 0;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* LoanCellIdentifier = @"LibariesFinesTableViewCell";
    
    LibrariesFinesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoanCellIdentifier];
    
    if (cell == nil) {
        cell = [[[LibrariesFinesTableViewCell alloc] initWithReuseIdentifier:LoanCellIdentifier] autorelease];
    }
    
    NSArray *loans = [self.loanData objectForKey:@"items"];
    cell.itemDetails = [loans objectAtIndex:indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static LibrariesFinesTableViewCell *cell = nil;
    if (cell == nil) {
        cell = [[LibrariesFinesTableViewCell alloc] init];
    }
    
    NSArray *loans = [self.loanData objectForKey:@"items"];
    cell.itemDetails = [loans objectAtIndex:indexPath.row];
    
    return [cell heightForContentWithWidth:CGRectGetWidth(tableView.frame) - 20.0]; // 20.0 for the accessory view
}

- (void)updateLoanData
{
    if (self.loanData == nil)
    {
        self.loadingView.frame = self.tableView.frame;
        [self.tableView.superview insertSubview:self.loadingView
                                   aboveSubview:self.tableView];
    }
    
    BOOL shouldUpdate = (self.lastUpdate == nil) || ([self.lastUpdate timeIntervalSinceNow] > 15.0);
    
    if ((self.operation == nil) && shouldUpdate)
    {
        MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                                command:@"fines"
                                                                             parameters:[NSDictionary dictionaryWithObject:[[NSNumber numberWithInteger:NSIntegerMax] stringValue]
                                                                                                                    forKey:@"limit"]];
        operation.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
            if (self.loadingView.superview != nil) {
                [self.loadingView removeFromSuperview];
            }
            
            if (error) {
                if (error.code == MobileWebInvalidLoginError)
                {
                    [self.parentController.navigationController popViewControllerAnimated:YES];
                }
                else
                {
                    if ([self.parentController respondsToSelector:@selector(reportError:fromTab:)])
                    {
                        [self.parentController performSelector:@selector(reportError:fromTab:)
                                                    withObject:error
                                                    withObject:self];
                    }
                }
                
                self.loanData = [NSDictionary dictionary];
            } else {
                self.loanData = (NSDictionary*)jsonResult;
            }
            
            self.headerView.accountDetails = (NSDictionary *)self.loanData;
            [self.headerView sizeToFit];
            [self.tableView reloadData];
            
            self.operation = nil;
        };
        
        self.operation = operation;
        [operation start];
    }
}

#pragma mark - Tab Activity Notifications
- (void)tabWillBecomeActive
{
    [self updateLoanData];
}

- (void)tabDidBecomeActive
{
    
}

- (void)tabWillBecomeInactive
{
    
}

- (void)tabDidBecomeInactive
{
    
}

@end
