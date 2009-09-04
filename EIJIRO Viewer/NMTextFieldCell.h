//
//  NMSearchFieldCell.h
//
//  Created by numata on July 28, 2003.
//  Copyright (c) 2003-2004 Satoshi NUMATA. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//
//  NMTextField��p�̃t�B�[���h�G�f�B�^
//

@interface NMSearchTextView : NSTextView

@end


//
//  NMTextField�����̃Z��
//

@interface NMTextFieldCell : NSTextFieldCell {
	// �ő�l�E�ŏ��l�E���ݒl
	double value;
	double maxValue;
	double minValue;

	// ��p�̃t�B�[���h�G�f�B�^
	NMSearchTextView	*fieldEditor;

	// �v���O���X�o�[�`��̂��߂̉摜
	NSImage *progLeftImage;
	NSImage *progMiddleImage;
	NSImage *progRightImage;
}

// �ő�l�E�ŏ��l�E���ݒl��Setter/Getter
- (double)doubleValue;
- (double)maxValue;
- (double)minValue;

- (void)setDoubleValue:(double)doubleValue;
- (void)setMaxValue:(double)newMaximum;
- (void)setMinValue:(double)newMinimum;

// ��p�̃t�B�[���h�G�f�B�^
- (NSText *)fieldEditor;

@end






