//
//  AppDelegate.m
//  sample

#import "AppDelegate.h"

static NSString *const kLogFileName = @"sample.log"; // 出力ログ名

// ログ表示の調節用
static NSString *const kWhiteSpaceAdjustment = @"                              ";
static NSString *const kSeparateLine         = @"---------------------------------------";

// ログのレベル
// コンソール・ファイルの両方に出力
static NSString *const kLogLevel_Fatal = @"[FATAL]"; // プログラムの異常終了を伴うようなもの。
static NSString *const kLogLevel_Error = @"[ERROR]"; // 予期しないその他の実行時エラー
static NSString *const kLogLevel_Warn  = @"[WARN] "; // 廃要素となったAPIの使用、APIの不適切な使用、エラーに近い事象など。異常とは言い切れないが正常ではない予期しない問題
static NSString *const kLogLevel_Info  = @"[INFO] "; // 実行時の何らかの注目すべき事象（開始や終了など）。メッセージ内容は簡潔に止めるべき
// コンソールのみに出力
static NSString *const kLogLevel_Debug = @"[DEBUG]"; // システムの動作状況に関する詳細な情報
static NSString *const kLogLevel_Trace = @"[TRACE]"; // デバッグ情報よりも、更に詳細な情報

@interface AppDelegate ()
@property (unsafe_unretained) IBOutlet NSTextView *logTextView; // ログのTextView
@property (weak)              IBOutlet NSWindow   *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self appendLogMessage:kSeparateLine logLevel:kLogLevel_Info];
    [self appendLogMessage:@"*** アプリケーションが起動しました ***" logLevel:kLogLevel_Info];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [self appendLogMessage:@"*** アプリケーションを終了します… ***" logLevel:kLogLevel_Info];
}

/**
 @brief 左上のクローズボタン押下でアプリを終了する
 */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

// MARK:- Log Methods

/**
 @brief コメントをログビューに追加する（その際にログファイルの更新も併せて行う）
 @param message ログに表示する内容
 @param level   ログのレベル
 */
- (void)appendLogMessage:(NSString *)message logLevel:(NSString *)level {
    // ログ記録時刻
    NSDate          *logDate          = [NSDate date];
    NSDateFormatter *logDateFormatter = [[NSDateFormatter alloc] init];
    logDateFormatter.dateStyle        = NSDateFormatterMediumStyle;
    logDateFormatter.timeStyle        = NSDateFormatterMediumStyle;
    NSString        *logDateStr       = [logDateFormatter stringFromDate:logDate];
    NSMutableString *logMessage       = [NSMutableString stringWithFormat:@"%@ %@ %@\r\n", level, logDateStr, message];
    
    // アプリ画面のログ表示（ログレベルがDEBUG, TRACEならばUI上のログには表示しない）
    if ([level isEqualToString:kLogLevel_Fatal] ||
        [level isEqualToString:kLogLevel_Error] ||
        [level isEqualToString:kLogLevel_Warn]  ||
        [level isEqualToString:kLogLevel_Info] ) {
        [_logTextView setEditable:YES];
        [_logTextView setSelectedRange: NSMakeRange(-1, 0)]; // 文末を選択
        [_logTextView insertText:logMessage replacementRange:NSMakeRange(-1, 0)];    // 末尾にログを追加
        [_logTextView setEditable:NO];
    }
    
    // ログファイルの更新
    if (![self updateLogFileWithMessage:logMessage]) {
        NSString *message = @"ログの出力時にエラーが発生しました。";
        NSMutableString *logMessage = [NSMutableString stringWithFormat:@"%@ %@ %@\r\n", kLogLevel_Error, logDateStr, message];
        [_logTextView setEditable:YES];
        [_logTextView setSelectedRange: NSMakeRange(-1, 0)]; // 文末を選択
        [_logTextView insertText:logMessage replacementRange:NSMakeRange(-1, 0)];    // 末尾にログを追加
        [_logTextView setEditable:NO];
    }
}

/**
 @brief ログファイルの更新を行う
 @param addedMessage ログに追加する文字列
 */
- (BOOL)updateLogFileWithMessage:(NSString *)addedMessage {
    // appと同じ場所にログファイルを書き出す
    NSURL   *bundleURL  = [NSURL fileURLWithPath:[NSBundle.mainBundle.bundlePath stringByDeletingLastPathComponent]];
    NSURL   *logFileURL = [bundleURL URLByAppendingPathComponent:kLogFileName];
    NSError *error      = nil;
    
    NSString *newLogMessage = [NSString string];   // 更新後のログメッセージ
    
    // 既存のログファイル読み込み
    NSString *oldLogMessage = [[NSString alloc] initWithContentsOfURL:logFileURL
                                                             encoding:NSUTF8StringEncoding
                                                                error:&error];
    if (oldLogMessage.length == 0) {
        newLogMessage = [NSString stringWithString:addedMessage];
    } else {
        newLogMessage = [oldLogMessage stringByAppendingString:addedMessage];
    }
    // 外部ログファイルに出力
    if (![newLogMessage writeToURL:logFileURL
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:&error]) {
        NSLog(@"%@", error.localizedDescription);
        return NO;
    }
    return YES;
}

// MARK:- Actions

/**
 @brief UI上のログ表示をクリアする
 */
- (IBAction)clearButtonPush:(id)sender {
    [_logTextView setEditable:YES];
    [_logTextView setString:@""];
    [_logTextView setEditable:NO];
}

/**
 @brief 終了ボタン
 */
- (IBAction)closeButtonPush:(id)sender {
    [NSApp terminate:self];
}

// 画面右側にあるOperationボタンが押下された場合
- (IBAction)operationButtonPush:(NSMatrix *)sender {
    int selectedRow = (int)sender.selectedRow;
    NSString *logLevel;
    switch (selectedRow) {
        case 0:
            logLevel = [NSString stringWithString:kLogLevel_Fatal];
            break;
        case 1:
            logLevel = [NSString stringWithString:kLogLevel_Error];
            break;
        case 2:
            logLevel = [NSString stringWithString:kLogLevel_Warn];
            break;
        case 3:
            logLevel = [NSString stringWithString:kLogLevel_Info];
            break;
        case 4:
            logLevel = [NSString stringWithString:kLogLevel_Debug];
            break;
        case 5:
            logLevel = [NSString stringWithString:kLogLevel_Trace];
            break;
        default:
            break;
    }
    
    // ログメッセージが長い場合の例
    if (selectedRow == 6) {
        logLevel = [NSString stringWithString:kLogLevel_Error];
        NSString *logMessage = [NSString stringWithFormat:
                                @"Operationを実行します。\r\n"
                                "%@長いログが出力されています…\r\n"
                                "%@長いログが出力されています…\r\n"
                                "%@長いログが出力されています…\r\n"
                                "%@Operationが終了しました。",
                                kWhiteSpaceAdjustment, kWhiteSpaceAdjustment, kWhiteSpaceAdjustment, kWhiteSpaceAdjustment];
        [self appendLogMessage:logMessage logLevel:kLogLevel_Error];
        return;
    }
    [self appendLogMessage:@"Operationが実行されました。" logLevel:logLevel];
}

@end
