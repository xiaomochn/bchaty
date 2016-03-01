//
//  JoinViewController.m
//  ChatDemo-UI3.0
//
//  Created by xiaomo on 16/1/28.
//  Copyright © 2016年 xiaomo. All rights reserved.
//

#import "JoinViewController.h"

#import "EMSearchBar.h"
#import "SRRefreshView.h"
#import "EMSearchDisplayController.h"
#import "PublicGroupDetailViewController.h"
#import "RealtimeSearchUtil.h"
#import "EMCursorResult.h"
#import "BaseTableViewCell.h"
#import "ChatViewController.h"
@interface JoinViewController ()<UITextFieldDelegate>
@property (nonatomic, strong) NSString *cursor;
@property (weak, nonatomic) IBOutlet UITextField *groupName;
@property (strong, nonatomic) NSMutableArray *dataSource;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@end

@implementation JoinViewController
- (IBAction)onEdit:(id)sender {
    [self.groupName resignFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.groupName.delegate=self;
    UITapGestureRecognizer *gestureRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)   ];
    gestureRecognizer.cancelsTouchesInView=NO;
    [self.view addGestureRecognizer:gestureRecognizer];
}
-(void)viewTapped{
    [_groupName resignFirstResponder];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) createGroup{
      __weak JoinViewController *weakSelf = self;
    EMGroupStyleSetting *setting = [[EMGroupStyleSetting alloc] init];
    setting.groupMaxUsersCount = 2000;
     setting.groupStyle = eGroupStyle_PublicOpenJoin;
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MMdd"];
    NSString* dateStr =[dateFormat stringFromDate:self.datePicker.date];
    NSString *groupN=[NSString stringWithFormat:@"%@%@",dateStr, self.groupName.text];
    
    [[EaseMob sharedInstance].chatManager asyncCreateGroupWithSubject:groupN description:@"没描述" invitees:nil initialWelcomeMessage:@"欢迎" styleSetting:setting completion:^(EMGroup *group, EMError *error) {
        
        if (group && !error) {
            [weakSelf showHint:@"加入群组成功"];
            [weakSelf.navigationController popViewControllerAnimated:YES];
            [self jumpToGroup:group.groupId];
        }
        else{
            [weakSelf showHint:@"加入群组失败"];
        }
    } onQueue:nil];
}

- (void)jumpToGroup:(NSString *)groupId
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MMdd"];
    NSString* dateStr =[dateFormat stringFromDate:self.datePicker.date];
    NSString *groupN=[NSString stringWithFormat:@"%@%@",dateStr, self.groupName.text];
   
    ChatViewController *chatController = [[ChatViewController alloc] initWithConversationChatter:groupId
                                                                                conversationType:eConversationTypeGroupChat];
    chatController.title = groupN;
    [self.navigationController pushViewController:chatController animated:YES];
}
- (void)joinGroup:(NSString *)groupId
{
    [self showHudInView:self.view hint:NSLocalizedString(@"group.join.ongoing", @"join the group...")];
    __weak JoinViewController *weakSelf = self;
    [[EaseMob sharedInstance].chatManager asyncJoinPublicGroup:groupId completion:^(EMGroup *group, EMError *error) {
        [weakSelf hideHud];
        if(!error)
        {
            [self jumpToGroup:groupId];
        }
        else{
            [weakSelf showHint:error.description];
        }
    } onQueue:nil];
}
#define FetchPublicGroupsPageSize   500

- (void)reloadDataSource
{
    [self hideHud];
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    _cursor = nil;
    
    __weak typeof(self) weakSelf = self;
    [[EaseMob sharedInstance].chatManager asyncFetchPublicGroupsFromServerWithCursor:_cursor pageSize:FetchPublicGroupsPageSize andCompletion:^(EMCursorResult *result, EMError *error){
        if (weakSelf)
        {
            JoinViewController *strongSelf = weakSelf;
            [strongSelf hideHud];
            if (!error)
            {

                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"MMdd"];
                NSString* dateStr =[dateFormat stringFromDate:self.datePicker.date];
                NSString *groupN=[NSString stringWithFormat:@"%@%@",dateStr, self.groupName.text];

                for (EMGroup *g in result.list) {
                    if ([g.groupSubject isEqualToString:groupN]) {
                        [self joinGroup:g.groupId];
                        return ;
                    }
                }
                [self createGroup];

            }
            else
            {
            }
        }
    }];
}

- (IBAction)onJoin:(id)sender {
    if (![self isEmpty]){
    [self reloadDataSource];
    }
    
}
- (BOOL)isEmpty{
    BOOL ret = NO;
    NSString *username = self.groupName.text;
    if (username.length == 0 ) {
        ret = YES;
        [EMAlertView showAlertWithTitle:NSLocalizedString(@"prompt", @"Prompt")
                                message:@"请输入车次"
                        completionBlock:nil
                      cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                      otherButtonTitles:nil];
    }
    
    return ret;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}
@end
