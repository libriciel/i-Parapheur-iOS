/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
 * Contributors : SKROBS (2012)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#import "ADLSingletonState.h"

@implementation ADLSingletonState

@synthesize bureauCourant;
@synthesize currentPrincipalDocPath;
@synthesize currentFilter;

#pragma mark -
#pragma mark Singleton Wizardry
#pragma mark -

static ADLSingletonState *sharedSingletonState = nil;

+ (ADLSingletonState *)sharedSingletonState {
    
    static ADLSingletonState *sharedSingletonState = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingletonState = [self new];
    });
    return sharedSingletonState;
}

/*+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedSingletonState] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax; // denotes an object that cannot be released
}

- (oneway void)release {
    // do nothing
}

- (id)autorelease {
    return self;
}*/


@end
