//
//  DLConversationListController.m
//  Dolores
//
//  Created by Heath on 18/04/2017.
//  Copyright © 2017 Dolores. All rights reserved.
//

#import "DLConversationListController.h"
#import "DLNetStatusView.h"
#import "NSDate+DateTools.h"
#import "DLChatController.h"
#import "DLConversationModel.h"
#import "DLSearchResultController.h"
#import "DLNetworkService.h"
#import "DLNetworkService+DLAPI.h"
#import "UIColor+DLAdd.h"

@interface DLConversationListController () <DLBaseControllerProtocol, EaseConversationListViewControllerDelegate, EaseConversationListViewControllerDataSource>

@property (nonatomic, strong) DLNetStatusView *netStatusView;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation DLConversationListController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupNavigationBar];
    [self setupData];
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchConversationList];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.tableView.contentOffset = CGPointMake(0, self.searchController.searchBar.frame.size.height);
    });
}

#pragma mark - DLBaseControllerProtocol

- (void)setupView {
    self.showRefreshHeader = NO;
    self.definesPresentationContext = YES;

    self.tableView.tableHeaderView = self.searchController.searchBar;
    [self.searchController.searchBar sizeToFit];

}

- (void)setupData {
    self.delegate = self;
    self.dataSource = self;
}

- (void)setupNavigationBar {
    self.navigationItem.titleView = self.netStatusView;
    self.netStatusView.titleLabel.text = @"Dolores";
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - EaseConversationListViewControllerDataSource

- (id <IConversationModel>)conversationListViewController:(EaseConversationListViewController *)conversationListViewController modelForConversation:(EMConversation *)conversation {
    DLConversationModel *conversationModel = [[DLConversationModel alloc] initWithConversation:conversation];
    if (conversationModel.conversation.type == EMConversationTypeChat) {

        RMStaff *staff = [RMStaff objectForPrimaryKey:conversation.conversationId];
        // if staff not exist, get it from server.
        if ([staff isInvalidated] || !staff) {
            [[DLNetworkService getUserInfoWithIds:@[conversation.conversationId]] subscribeNext:^(id x) {
                if ([x isKindOfClass:[NSArray class]]) {
                    NSArray *users = x;
                    if (users.count > 0) {
                        NSDictionary *user = users[0];
                        conversationModel.title = user[@"name"];
                        NSString *avatar = user[@"labeledURI"];
                        conversationModel.avatarURLPath = [[avatar qiniuURL] qiniuURLWithSize:CGSizeMake(88, 88)];
                    }
                }
            } error:^(NSError *error) {

            }];
        } else {
            conversationModel.title = staff.realName;
            conversationModel.avatarURLPath = [staff qiniuURLWithSize:CGSizeMake(88, 88)];
        }

    } else if (conversationModel.conversation.type == EMConversationTypeGroupChat) {

        if (!conversation.ext[@"subject"]) {
            NSArray *groupArray = [[EMClient sharedClient].groupManager getJoinedGroups];
            for (EMGroup *group in groupArray) {
                if ([group.groupId isEqualToString:conversation.conversationId]) {
                    NSMutableDictionary *ext = [NSMutableDictionary dictionaryWithDictionary:conversation.ext];
                    ext[@"subject"] = group.subject;
                    ext[@"isPublic"] = @(group.isPublic);
                    conversation.ext = ext;
                    break;
                }
            }
        }
        NSDictionary *ext = conversation.ext;
        conversationModel.title = ext[@"subject"];
//        imageName = [[ext objectForKey:@"isPublic"] boolValue] ? @"groupPublicHeader" : @"groupPrivateHeader";
//        conversationModel.avatarImage = [UIImage imageNamed:imageName];
    }
    return conversationModel;
}

- (NSAttributedString *)conversationListViewController:(EaseConversationListViewController *)conversationListViewController latestMessageTitleForConversationModel:(id <IConversationModel>)conversationModel {

    NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:@""];
    EMMessage *lastMessage = [conversationModel.conversation latestMessage];

    if (lastMessage) {
        NSString *latestMessageTitle = @"";
        EMMessageBody *messageBody = lastMessage.body;
        switch (messageBody.type) {
            case EMMessageBodyTypeImage: {
                latestMessageTitle = @"[图片]";
            }
                break;
            case EMMessageBodyTypeText: {
                // 表情映射。
                NSString *didReceiveText = [EaseConvertToCommonEmoticonsHelper convertToSystemEmoticons:((EMTextMessageBody *) messageBody).text];
                latestMessageTitle = didReceiveText;
                if (lastMessage.ext[MESSAGE_ATTR_IS_BIG_EXPRESSION]) {
                    latestMessageTitle = @"[动画表情]";
                }
            }
                break;
            case EMMessageBodyTypeVoice: {
                latestMessageTitle = @"[语音]";
            }
                break;
            case EMMessageBodyTypeLocation: {
                latestMessageTitle = @"[定位]";
            }
                break;
            case EMMessageBodyTypeVideo: {
                latestMessageTitle = @"[视频]";
            }
                break;
            case EMMessageBodyTypeFile: {
                latestMessageTitle = @"[文件]";
            }
                break;
            default: {
            }
                break;
        }

        NSDictionary *ext = conversationModel.conversation.ext;
        if (ext && [ext[kHaveUnreadAtMessage] intValue] == kAtAllMessage) {
            latestMessageTitle = [NSString stringWithFormat:@"%@ %@", @"@所有人", latestMessageTitle];
            attributedStr = [[NSMutableAttributedString alloc] initWithString:latestMessageTitle];
            [attributedStr setAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:.0 blue:.0 alpha:0.5]}
                                   range:NSMakeRange(0, @"@所有人".length)];

        }
        else if (ext && [ext[kHaveUnreadAtMessage] intValue] == kAtYouMessage) {
            latestMessageTitle = [NSString stringWithFormat:@"%@ %@", @"有人@我", latestMessageTitle];
            attributedStr = [[NSMutableAttributedString alloc] initWithString:latestMessageTitle];
            [attributedStr setAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:.0 blue:.0 alpha:0.5]}
                                   range:NSMakeRange(0, @"有人@我".length)];
        }
        else {
            attributedStr = [[NSMutableAttributedString alloc] initWithString:latestMessageTitle];
        }
    }
    return attributedStr;
}

- (NSString *)conversationListViewController:(EaseConversationListViewController *)conversationListViewController latestMessageTimeForConversationModel:(id <IConversationModel>)conversationModel {
    EMMessage *message = [conversationModel.conversation latestMessage];
    if (message) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:message.timestamp / 1000.0f];
        return [date timeAgoSinceNow];
    }
    return @"";
}

#pragma mark - EaseConversationListViewControllerDelegate

- (void)conversationListViewController:(EaseConversationListViewController *)conversationListViewController didSelectConversationModel:(id <IConversationModel>)conversationModel {
    DLChatController *chatController = [[DLChatController alloc] initWithConversationChatter:conversationModel.conversation.conversationId conversationType:conversationModel.conversation.type];
    [self.navigationController pushViewController:chatController animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[EaseConversationCell class]]) {
        EaseConversationCell *conversationCell = (EaseConversationCell *) cell;
        conversationCell.avatarView.imageView.backgroundColor = [UIColor clearColor];
        conversationCell.avatarView.imageCornerRadius = conversationCell.avatarView.bounds.size.width / 2;
    }
    return cell;
}

#pragma mark - overwrite

- (void)tableViewDidTriggerHeaderRefresh {
    [super tableViewDidTriggerHeaderRefresh];
    [self.netStatusView updateStatusView:ConversationStatusNone];
}

#pragma mark - private method

- (void)fetchConversationList {
    [self.netStatusView updateStatusView:ConversationStatusFetching];
    [self tableViewDidTriggerHeaderRefresh];
}

#pragma mark - Getter

- (DLNetStatusView *)netStatusView {
    if (!_netStatusView) {
        CGFloat gap = 88;
        CGFloat width = CGRectGetWidth([UIScreen mainScreen].bounds) - gap * 2;
        _netStatusView = [[DLNetStatusView alloc] initWithFrame:CGRectMake(gap, 0, width, 44)];
    }
    return _netStatusView;
}


- (UISearchController *)searchController {
    if (!_searchController) {
        DLSearchResultController *searchResultController = [DLSearchResultController new];
        _searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultController];

        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        [_searchController.view insertSubview:effectView atIndex:0];
        [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];

        _searchController.searchBar.placeholder = @"搜索";
        _searchController.searchBar.barStyle = UIBarStyleDefault;
        _searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;

        searchResultController.searchController = _searchController;
        _searchController.delegate = searchResultController;
        _searchController.searchResultsUpdater = searchResultController;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.1")) {
            _searchController.obscuresBackgroundDuringPresentation = YES;
        }
    }
    return _searchController;
}


@end