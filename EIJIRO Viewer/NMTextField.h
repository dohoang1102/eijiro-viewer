//
//  NMTextField.h
//
//  Created by numata on April 6, 2004.
//  Copyright 2003-2004 Satoshi NUMATA. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class NMTextFieldCell;


//
//  �v���O���X�o�[�@�\���������e�L�X�g�t�B�[���h
//

@interface NMTextField : NSTextField {
	
	// �A�E�g���b�g
	NMTextFieldCell	*searchCell;	// �����̃Z��
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
