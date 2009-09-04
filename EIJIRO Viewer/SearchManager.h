//
//  SearchManager.h
//  EIJIRO Viewer
//
//  Created by numata on November 11, 2004.
//  Copyright 2004 Satoshi NUMATA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NMTextField.h"


@class ApplicationManager;


//
//  �p���Y�����̌������s���N���X�B
//

@interface SearchManager : NSObject {
	
	// �A�E�g���b�g
    IBOutlet NSWindow		*mainWindow;	// ���C���E�B���h�E
    IBOutlet NMTextField	*searchField;	// �����t�B�[���h
    IBOutlet NSTextView		*resultView;	// ���ʕ\���r���[
	IBOutlet ApplicationManager	*applicationManager;	// UI�}�l�[�W��
	
	// �J�����g�̌���ID
	volatile unsigned long currentSearchID;
	
	// �C�����
	NSString *firstGuess;
	NSString *secondGuess;
}

// �ʏ팟���̊J�n
- (void)searchString:(NSString *)searchStr;

// �S�������̊J�n
- (void)doFullSearchForString:(NSString *)searchStr;

// �����̒��f
- (void)stopSearching;

// �C�����
- (NSString *)firstGuess;
- (NSString *)secondGuess;

@end


