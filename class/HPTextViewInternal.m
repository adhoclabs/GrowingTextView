//
//  HPTextViewInternal.m
//
//  Created by Hans Pinckaers on 29-06-10.
//
//	MIT License
//
//	Copyright (c) 2011 Hans Pinckaers
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

#import "HPTextViewInternal.h"

NSString * const HPTextViewPastedItemContentType =                 @"HPTextViewPastedItemContentType";
NSString * const HPTextViewPastedItemMediaType =                   @"HPTextViewPastedItemMediaType";
NSString * const HPTextViewPastedItemData =                        @"HPTextViewPastedItemData";

NSString * const HPTextViewDidPasteItemNotification =              @"HPTextViewDidPasteItemNotification";

@implementation HPTextViewInternal

HPPastableMediaType HPPastableMediaTypeFromNSString(NSString *string)
{
    if ([string isEqualToString:NSStringFromHPPastableMediaType(HPPastableMediaTypePNG)]) {
        return HPPastableMediaTypePNG;
    }
    if ([string isEqualToString:NSStringFromHPPastableMediaType(HPPastableMediaTypeJPEG)]) {
        return HPPastableMediaTypeJPEG;
    }
    if ([string isEqualToString:NSStringFromHPPastableMediaType(HPPastableMediaTypeTIFF)]) {
        return HPPastableMediaTypeTIFF;
    }
    if ([string isEqualToString:NSStringFromHPPastableMediaType(HPPastableMediaTypeGIF)]) {
        return HPPastableMediaTypeGIF;
    }
    if ([string isEqualToString:NSStringFromHPPastableMediaType(HPPastableMediaTypeMOV)]) {
        return HPPastableMediaTypeMOV;
    }
    if ([string isEqualToString:NSStringFromHPPastableMediaType(HPPastableMediaTypePassbook)]) {
        return HPPastableMediaTypePassbook;
    }
    if ([string isEqualToString:NSStringFromHPPastableMediaType(HPPastableMediaTypeImages)]) {
        return HPPastableMediaTypeImages;
    }
    return HPPastableMediaTypeNone;
}

NSString *NSStringFromHPPastableMediaType(HPPastableMediaType type)
{
    if (type == HPPastableMediaTypePNG) {
        return @"public.png";
    }
    if (type == HPPastableMediaTypeJPEG) {
        return @"public.jpeg";
    }
    if (type == HPPastableMediaTypeTIFF) {
        return @"public.tiff";
    }
    if (type == HPPastableMediaTypeGIF) {
        return @"com.compuserve.gif";
    }
    if (type == HPPastableMediaTypeMOV) {
        return @"com.apple.quicktime";
    }
    if (type == HPPastableMediaTypePassbook) {
        return @"com.apple.pkpass";
    }
    if (type == HPPastableMediaTypeImages) {
        return @"com.apple.uikit.image";
    }
    
    return nil;
}

-(void)setText:(NSString *)text
{
    BOOL originalValue = self.scrollEnabled;
    //If one of GrowingTextView's superviews is a scrollView, and self.scrollEnabled == NO,
    //setting the text programatically will cause UIKit to search upwards until it finds a scrollView with scrollEnabled==yes
    //then scroll it erratically. Setting scrollEnabled temporarily to YES prevents this.
    [self setScrollEnabled:YES];
    [super setText:text];
    [self setScrollEnabled:originalValue];
    
    self.pastableMediaTypes = HPPastableMediaTypePNG | HPPastableMediaTypeTIFF | HPPastableMediaTypeJPEG;
}

- (void)setScrollable:(BOOL)isScrollable
{
    [super setScrollEnabled:isScrollable];
}

-(void)setContentOffset:(CGPoint)s
{
    if(self.tracking || self.decelerating){
        //initiated by user...
        
        UIEdgeInsets insets = self.contentInset;
        insets.bottom = 0;
        insets.top = 0;
        self.contentInset = insets;
        
    } else {
        
        float bottomOffset = (self.contentSize.height - self.frame.size.height + self.contentInset.bottom);
        if(s.y < bottomOffset && self.scrollEnabled){
            UIEdgeInsets insets = self.contentInset;
            insets.bottom = 8;
            insets.top = 0;
            self.contentInset = insets;
        }
    }
    
    // Fix "overscrolling" bug
    if (s.y > self.contentSize.height - self.frame.size.height && !self.decelerating && !self.tracking && !self.dragging)
        s = CGPointMake(s.x, self.contentSize.height - self.frame.size.height);
    
    [super setContentOffset:s];
}

-(void)setContentInset:(UIEdgeInsets)s
{
    UIEdgeInsets insets = s;
    
    if(s.bottom>8) insets.bottom = 0;
    insets.top = 0;
    
    [super setContentInset:insets];
}

-(void)setContentSize:(CGSize)contentSize
{
    // is this an iOS5 bug? Need testing!
    if(self.contentSize.height > contentSize.height)
    {
        UIEdgeInsets insets = self.contentInset;
        insets.bottom = 0;
        insets.top = 0;
        self.contentInset = insets;
    }
    
    [super setContentSize:contentSize];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (self.displayPlaceHolder && self.placeholder && self.placeholderColor)
    {
        if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)])
        {
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.alignment = self.textAlignment;
            [self.placeholder drawInRect:CGRectMake(5, 8 + self.contentInset.top, self.frame.size.width-self.contentInset.left, self.frame.size.height- self.contentInset.top) withAttributes:@{NSFontAttributeName:self.font, NSForegroundColorAttributeName:self.placeholderColor, NSParagraphStyleAttributeName:paragraphStyle}];
        }
        else {
            [self.placeholderColor set];
            [self.placeholder drawInRect:CGRectMake(8.0f, 8.0f, self.frame.size.width - 16.0f, self.frame.size.height - 16.0f) withFont:self.font];
        }
    }
}

-(void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    
    [self setNeedsDisplay];
}


// Checks if any supported media found in the general pasteboard
- (BOOL)isPasteboardItemSupported
{
    if ([self pasteboardContentType].length > 0) {
        return YES;
    }
    return NO;
}

- (NSString *)pasteboardContentType
{
    NSArray *pasteboardTypes = [[UIPasteboard generalPasteboard] pasteboardTypes];
    NSMutableArray *subpredicates = [NSMutableArray new];
    
    for (NSString *type in [self supportedMediaTypes]) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"SELF == %@", type]];
    }
    
    return [[pasteboardTypes filteredArrayUsingPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:subpredicates]] firstObject];
}

- (NSArray *)supportedMediaTypes
{
    if (self.pastableMediaTypes == HPPastableMediaTypeNone) {
        return nil;
    }
    
    NSMutableArray *types = [NSMutableArray new];
    
    if (self.pastableMediaTypes & HPPastableMediaTypePNG) {
        [types addObject:NSStringFromHPPastableMediaType(HPPastableMediaTypePNG)];
    }
    if (self.pastableMediaTypes & HPPastableMediaTypeJPEG) {
        [types addObject:NSStringFromHPPastableMediaType(HPPastableMediaTypeJPEG)];
    }
    if (self.pastableMediaTypes & HPPastableMediaTypeTIFF) {
        [types addObject:NSStringFromHPPastableMediaType(HPPastableMediaTypeTIFF)];
    }
    if (self.pastableMediaTypes & HPPastableMediaTypeGIF) {
        [types addObject:NSStringFromHPPastableMediaType(HPPastableMediaTypeGIF)];
    }
    if (self.pastableMediaTypes & HPPastableMediaTypeMOV) {
        [types addObject:NSStringFromHPPastableMediaType(HPPastableMediaTypeMOV)];
    }
    if (self.pastableMediaTypes & HPPastableMediaTypePassbook) {
        [types addObject:NSStringFromHPPastableMediaType(HPPastableMediaTypePassbook)];
    }
    if (self.pastableMediaTypes & HPPastableMediaTypeImages) {
        [types addObject:NSStringFromHPPastableMediaType(HPPastableMediaTypeImages)];
    }
    
    return types;
}

- (id)pastedItem
{
    NSString *contentType = [self pasteboardContentType];
    NSData *data = [[UIPasteboard generalPasteboard] dataForPasteboardType:contentType];
    
    if (data && [data isKindOfClass:[NSData class]])
    {
        HPPastableMediaType mediaType = HPPastableMediaTypeFromNSString(contentType);
        
        NSDictionary *userInfo = @{HPTextViewPastedItemContentType: contentType,
                                   HPTextViewPastedItemMediaType: @(mediaType),
                                   HPTextViewPastedItemData: data};
        return userInfo;
    }
    if ([[UIPasteboard generalPasteboard] URL]) {
        return [[[UIPasteboard generalPasteboard] URL] absoluteString];
    }
    if ([[UIPasteboard generalPasteboard] string]) {
        return [[UIPasteboard generalPasteboard] string];
    }
    
    return nil;
}

- (void)insertTextAtCaretRange:(NSString *)text
{
    NSRange range = [self insertText:text inRange:self.selectedRange];
    self.selectedRange = NSMakeRange(range.location, 0);
}

- (NSRange)insertText:(NSString *)text inRange:(NSRange)range
{
    // Skip if the text is empty
    if (text.length == 0) {
        return NSMakeRange(0, 0);
    }
    
    // Append the new string at the caret position
    if (range.length == 0)
    {
        NSString *leftString = [self.text substringToIndex:range.location];
        NSString *rightString = [self.text substringFromIndex: range.location];
        
        self.text = [NSString stringWithFormat:@"%@%@%@", leftString, text, rightString];
        
        range.location += text.length;
        
        return range;
    }
    // Some text is selected, so we replace it with the new text
    else if (range.location != NSNotFound && range.length > 0)
    {
        self.text = [self.text stringByReplacingCharactersInRange:range withString:text];
        
        range.location += text.length;
        
        return range;
    }
    
    // No text has been inserted, but still return the caret range
    return self.selectedRange;
}

#pragma mark - Menu actions

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:) && [self isPasteboardItemSupported]) {
        return YES;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void)paste:(id)sender
{
    id pastedItem = [self pastedItem];
    
    if ([pastedItem isKindOfClass:[NSDictionary class]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HPTextViewDidPasteItemNotification object:nil userInfo:pastedItem];
    }
    else if ([pastedItem isKindOfClass:[NSString class]]) {
        self.placeholder = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:HPTextViewDidPasteItemNotification object:nil userInfo:pastedItem];
        
        // Inserting the text fixes a UITextView bug whitch automatically scrolls to the bottom
        // and beyond scroll content size sometimes when the text is too long
        [self insertTextAtCaretRange:pastedItem];
    }
}

@end
