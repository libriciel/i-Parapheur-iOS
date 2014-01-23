//
//  NSString+Contains.m
//  iParapheur
//
//  Created by Jason MAIRE on 20/01/2014.
//
//

#import "NSString+Contains.h"

@implementation NSString (Contains)

- (BOOL) containsString:(NSString*) string {
    NSRange range = [self rangeOfString : string];
    return (range.location != NSNotFound);
}

@end
