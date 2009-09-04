//
//  ApplicationManager.h
//  EIJIRO Viewer
//
//  Created by numata on November 11, 2004.
//  Copyright 2004 Satoshi NUMATA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NMSpeechManager.h"


@class SearchManager;


//
//  ���[�U�C���^�t�F�[�X���Ǘ����A���͏����̐U�蕪���Ȃǂ��s���N���X
//

@interface ApplicationManager : NSObject {

	// �A�E�g���b�g
    IBOutlet NSWindow		*mainWindow;		// ���C���E�B���h�E
	IBOutlet NSWindow		*preferencesWindow;	// ���ݒ�E�B���h�E
    IBOutlet NSWindow		*fullSearchWindow;	// �S�������E�B���h�E
	IBOutlet NSTextField	*searchField;		// �����t�B�[���h
	IBOutlet NSTextField	*fullSearchField;	// �S�������̒P��t�B�[���h
    IBOutlet NSTextView		*resultView;		// ���ʕ\���r���[
    IBOutlet NSButton		*pronounceButton;	// �����{�^��
    IBOutlet SearchManager	*searchManager;		// �����}�l�[�W��
    IBOutlet NSSegmentedControl	*moveControl;	// �ړ��R���g���[��
	
	// �c�[���o�[�p�̃A�E�g���b�g
    IBOutlet NSView			*moveView;			// �ړ��R���g���[���̃r���[
    IBOutlet NSView			*searchView;		// �����t�B�[���h�̃r���[
    IBOutlet NSView			*pronounceView;		// �����{�^���̃r���[
    IBOutlet NSView			*fullSearchView;	// �����{�^���̃r���[
	
	// ���ʕ\���p�t�H���g�̃L���b�V��
	NSFont				*font;				// �t�H���g
	NSMutableDictionary	*resultAttributes;	// �t�H���g�w����܂񂾎���
	
	// �q�X�g���@�\�̃T�|�[�g
	NSMutableArray		*searchWordList;	// �q�X�g�����X�g
	unsigned int		historyPos;			// �ǂ��܂Ńq�X�g����k�������j
	NSMutableDictionary	*visibleRectDict;	// �X�N���[���ʒu�̕ۑ�

	// �q�X�g���m��Ɋւ���t���O
	BOOL isWordJustFixed;	// ���^�[���L�[�A�^�u�L�[�A��A�N�e�B�u���ɂ����
							// �q�X�g�����m�肵������ł��邱�Ƃ������t���O
	BOOL wasFullSearch;	// �q�X�g���Q�Ǝ��ɑS�������𔽉f�����Ȃ����߂̃t���O
	
	// �ǂݏグ�̃T�|�[�g
	NMSpeechManager	*speechManager;		// �Ǘ��N���X
	NSTextView		*speakingView;		// �J�����g�̓ǂݏグ�Ώۃr���[
	NSRange			selectionRange;		// �ǂݏグ�O�̑I��͈�
	unsigned int	speechStartPos;		// �ǂݏグ�J�n�_
}

// �����p�l���\���Ǘ��̂��߂̃A�N�V����
- (IBAction)performFindPanelAction:(id)sender;
- (IBAction)centerSelectionInVisibleArea:(id)sender;

// �S�������̂��߂̃A�N�V����
- (IBAction)fullSearch:(id)sender;
- (IBAction)startFullSearch:(id)sender;
- (IBAction)cancelFullSearch:(id)sender;

// �q�X�g���@�\�̂��߂̃A�N�V����
- (IBAction)searchPrevious:(id)sender;
- (IBAction)searchNext:(id)sender;

- (IBAction)fixSearchString:(id)sender;	// �J�����g�̌�����������m�肵�ăt�H�[�J�X�������t�B�[���h��

// �C�����I���̂��߂̃A�N�V����
- (IBAction)searchFirstGuess:(id)sender;
- (IBAction)searchSecondGuess:(id)sender;

// �ǂݏグ�̂��߂̃A�N�V����
- (IBAction)pronounce:(id)sender;
- (IBAction)startSpeaking:(id)sender;
- (IBAction)stopSpeaking:(id)sender;

// ���ݒ�A�N�V����
- (IBAction)showPreferences:(id)sender;

- (IBAction)referEijiroPath:(id)sender;
- (IBAction)referReijiroPath:(id)sender;
- (IBAction)referRyakugoroPath:(id)sender;
- (IBAction)referWaeijiroPath:(id)sender;
- (IBAction)clearDictionaryPaths:(id)sender;

- (IBAction)selectFont:(id)sender;

// ���ʕ\���t�H���g�̎w����܂񂾎��������^�[������
- (NSDictionary *)resultAttributes;

// �X�N���[���ʒu�𕜌�����
- (void)scrollToLastRectForString:(NSString *)searchWord;

// �ǂݏグ�{�^���̃A�N�e�B�x�[�g
- (void)activatePronounceButton;

// �q�X�g���@�\�̂��߂̃��\�b�h
- (void)clearSubsequentHistory;	// �J�����g�ȍ~�̃q�X�g�����폜
- (void)fixCurrentSearchString;	// �J�����g�̌�����������m�肷��

@end
