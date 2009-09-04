//
//  NMTextField.m
//
//  Created by numata on April 6, 2004.
//  Copyright 2003-2004 Satoshi NUMATA. All rights reserved.
//

#import "NMTextField.h"
#import "NMTextFieldCell.h"


//
//  �v���O���X�o�[�@�\���������e�L�X�g�t�B�[���h
//

@implementation NMTextField

// ������
- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		// ��p�̓����Z���̍쐬
		searchCell = [[[NMTextFieldCell alloc] init] autorelease];
		// ���̃Z������v���p�e�B���R�s�[
		NSCell *oldCell = [self cell];
		[searchCell setContinuous:[oldCell isContinuous]];
		[searchCell setSendsActionOnEndEditing:[oldCell sendsActionOnEndEditing]];
		[searchCell setEditable:[oldCell isEditable]];
		[searchCell setFont:[oldCell font]];
		[searchCell setFocusRingType:[oldCell focusRingType]];
		[searchCell setBordered:[oldCell isBordered]];
		[searchCell setBezeled:[oldCell isBezeled]];
		[searchCell setTarget:[oldCell target]];
		[searchCell setAction:[oldCell action]];
		// �����Z���̓��ꊷ��
		[self setCell:searchCell];
	}
	return self;
}

// �v���O���X�o�[�̍ő�l�����^�[������
- (double)maxValue {
	return [(NMTextFieldCell *) searchCell maxValue];
}

// �v���O���X�o�[�̍ŏ��l�����^�[������
- (double)minValue {
	return [(NMTextFieldCell *) searchCell minValue];
}

// �v���O���X�o�[�̍ő�l���Z�b�g����
- (void)setMaxValue:(double)newMaximum {
	[(NMTextFieldCell *) searchCell setMaxValue:newMaximum];
}

// �v���O���X�o�[�̍ŏ��l���Z�b�g����
- (void)setMinValue:(double)newMinimum {
	[(NMTextFieldCell *) searchCell setMinValue:newMinimum];
}

// �v���O���X�o�[�̌��ݒl�����^�[������
- (double)doubleValue {
	return [(NMTextFieldCell *) searchCell doubleValue];
}

// �v���O���X�o�[�̌��ݒl���Z�b�g����
- (void)setDoubleValue:(double)doubleValue {
	[(NMTextFieldCell *) searchCell setDoubleValue:doubleValue];
	[self setNeedsDisplay:YES];
}

// ��p�̃t�B�[���h�G�f�B�^�����^�[������
- (NSText *)fieldEditor {
	return [searchCell fieldEditor];
}

@end
