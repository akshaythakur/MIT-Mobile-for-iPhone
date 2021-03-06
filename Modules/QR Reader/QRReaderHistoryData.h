#import <Foundation/Foundation.h>

@class QRReaderResult;

@interface QRReaderHistoryData : NSObject {
	NSMutableArray *_results;
}

@property (nonatomic, retain) NSArray *results;
+ (QRReaderHistoryData*)sharedHistory;

- (void)eraseAll;

- (QRReaderResult*)scanWithUID:(NSString *)uid;
- (QRReaderResult*)insertScanResult:(NSString*)scanResult withDate:(NSDate*)date;
- (QRReaderResult*)insertScanResult:(NSString*)scanResult withDate:(NSDate*)date withImage:(UIImage*)image;
- (void)deleteScanResult:(QRReaderResult*)result;

@end
