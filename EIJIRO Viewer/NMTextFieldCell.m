//
//  NMSearchFieldCell.m
//
//  Created by numata on July 28, 2003.
//  Copyright 2003-2004 Satoshi NUMATA. All rights reserved.
//

#import "NMTextFieldCell.h"
#import "NMTextField.h"
#import "ApplicationManager.h"
#import "SearchManager.h"
#import "StringUtil.h"


//
//  NMTextField��p�̃t�B�[���h�G�f�B�^
//

@implementation NMSearchTextView

// ������
- (id)init {
	self = [super init];
	if (self) {
		[self registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
	}
	return self;
}

// �h���b�O�I�����̏���
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	NSPasteboard *draggingPasteboard = [sender draggingPasteboard];
	NSString *pasteStr = [draggingPasteboard stringForType:NSStringPboardType];
	pasteStr = [pasteStr stringByTrimmingFirstInvalidCharacters];
	pasteStr = [pasteStr stringByTrimmingLastInvalidCharacters];
	[self setString:pasteStr];
	[NSApp activateIgnoringOtherApps:YES];
	ApplicationManager *applicationManager =
		[[[NSThread currentThread] threadDictionary] valueForKey:@"ApplicationManager"];
	SearchManager *searchManager =
		[[[NSThread currentThread] threadDictionary] valueForKey:@"SearchManager"];
	[applicationManager activatePronounceButton];
	[applicationManager clearSubsequentHistory];
	[applicationManager fixSearchString:self];
	[searchManager searchString:pasteStr];
}

// �c�Ȃ񂾂����H
// �R�����g�ǉ��O�ɍ�����̂Ŋo���ĂȂ��B�B�B
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type {
	if ([type isEqualToString:NSStringPboardType]) {
		NSString *pasteStr = [pboard stringForType:NSStringPboardType];
		pasteStr = [pasteStr stringByTrimmingFirstInvalidCharacters];
		pasteStr = [pasteStr stringByTrimmingLastInvalidCharacters];
		[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
		[pboard setString:pasteStr forType:NSStringPboardType];
	}
	return [super readSelectionFromPasteboard:pboard type:type];
}

@end


//
//  NMTextField�����̃Z��
//

@implementation NMTextFieldCell

// ������
- (id)init {
	self = [super initTextCell:@""];
	if (self) {
		// ��p�̃t�B�[���h�G�f�B�^
		fieldEditor = [[NMSearchTextView alloc] init];
		[fieldEditor setFieldEditor:YES];

		// �ő�l�E�ŏ��l�E���ݒl
		minValue = 0;
		maxValue = 100;
		value = 0;

		// �v���O���X�o�[�`��̂��߂̉摜
		progLeftImage = [NSImage imageNamed:@"Location_Left_Progress"];
		progMiddleImage = [NSImage imageNamed:@"Location_Middle_Progress"];
		progRightImage = [NSImage imageNamed:@"Location_Right_Progress"];
		[progLeftImage setFlipped:YES];
		[progMiddleImage setFlipped:YES];
		[progRightImage setFlipped:YES];
	}
	return self;
}

// �N���[���A�b�v
- (void)dealloc {
	[fieldEditor release];
	[super dealloc];
}

// �t�H�[�J�X�����O�͕\��
- (BOOL)showsFirstResponder {
    return YES;
}

// �w�i�̕`���OFF�ɂ��Ď����ŕ`��
- (BOOL)drawsBackground {
    return NO;
}

// �܂�Ԃ�����
- (BOOL)wraps {
    return NO;
}

// �X�N���[������
- (BOOL)isScrollable {
    return YES;
}

// �t�B�[���h�G�f�B�^�̃Z�b�g�A�b�v
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj {
	[super setUpFieldEditorAttributes:fieldEditor];
	return fieldEditor;
}

// �`��̃I�[�o�[���C�h
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	// �v���O���X�o�[�̕`��
	double progress = (value - minValue) / (maxValue - minValue);
	double indicatorWidth = cellFrame.size.width * progress;
	double leftSize = (indicatorWidth > 18)? 18: indicatorWidth;
	[progLeftImage drawInRect:NSMakeRect(1, 2, leftSize-1, 19)
					 fromRect:NSMakeRect(0, 0, leftSize-1, 19)
					operation:NSCompositeSourceOver
					 fraction:1.0];
	if (indicatorWidth > 18) {
		double midSize = (indicatorWidth-18 > cellFrame.size.width-18-3)?
			cellFrame.size.width-18-3: indicatorWidth-18;
		[progMiddleImage drawInRect:NSMakeRect(18, 2, midSize, 19)
						   fromRect:NSMakeRect(0, 0, 32, 19)
						  operation:NSCompositeSourceOver
						   fraction:1.0];
		if (indicatorWidth-18-midSize > 0) {
			double rightSize = indicatorWidth-18-midSize;
			[progRightImage drawInRect:NSMakeRect(cellFrame.size.width-3, 2, rightSize, 19)
							  fromRect:NSMakeRect(0, 0, rightSize, 19)
							 operation:NSCompositeSourceOver
							  fraction:1.0];
		}
	}
	
	// �c��̕����̕`��
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

// ���ݒl�����^�[������
- (double)doubleValue {
	return value;
}

// �ő�l�����^�[������
- (double)maxValue {
	return maxValue;
}

// �ŏ��l�����^�[������
- (double)minValue {
	return minValue;
}

// ���ݒl���Z�b�g����
- (void)setDoubleValue:(double)doubleValue {
	value = doubleValue;
}

// �ő�l���Z�b�g����
- (void)setMaxValue:(double)newMaximum {
	maxValue = newMaximum;
}

// �ŏ��l���Z�b�g����
- (void)setMinValue:(double)newMinimum {
	minValue = newMinimum;
}

// ��p�̃t�B�[���h�G�f�B�^�����^�[������
- (NSText *)fieldEditor {
	return fieldEditor;
}

@end


