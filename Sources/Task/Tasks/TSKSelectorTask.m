//
//  TSKSelectorTask.m
//  Task
//
//  Created by Prachi Gauriar on 10/14/2014.
//  Copyright (c) 2015 Prachi Gauriar. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Task/TSKSelectorTask.h>


@interface TSKSelectorTask ()

@property (nonatomic, copy, readonly) NSSet<id<NSCopying>> *requiredPrerequisiteKeys;

@end


@implementation TSKSelectorTask

@synthesize requiredPrerequisiteKeys = _requiredPrerequisiteKeys;

- (instancetype)initWithTarget:(id)target selector:(SEL)selector
{
    return [self initWithName:nil target:target selector:selector requiredPrerequisiteKeys:[NSSet set]];
}


- (instancetype)initWithName:(NSString *)name target:(id)target selector:(SEL)selector
{
    return [self initWithName:name target:target selector:selector requiredPrerequisiteKeys:[NSSet set]];
}


- (instancetype)initWithName:(NSString *)name target:(id)target selector:(SEL)selector requiredPrerequisiteKeys:(NSSet *)requiredPrerequisiteKeys
{
    NSParameterAssert(target);
    NSParameterAssert(selector);

    self = [super initWithName:name];
    if (self) {
        _target = target;
        _selector = selector;
        _requiredPrerequisiteKeys = requiredPrerequisiteKeys ? [requiredPrerequisiteKeys copy] : [NSSet set];
    }

    return self;
}


- (void)main
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.selector withObject:self];
#pragma clang diagnostic pop
}

@end
