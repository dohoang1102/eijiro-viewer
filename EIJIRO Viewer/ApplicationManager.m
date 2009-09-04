//
//  ApplicationManager.m
//  EIJIRO Viewer
//
//  Created by numata on November 11, 2004.
//  Copyright 2004 Satoshi NUMATA. All rights reserved.
//

#import "ApplicationManager.h"

#import "NMTextField.h"
#import "NMFontTransformer.h"
#import "SearchManager.h"


//
//  ApplicationManager�œ����I�Ɏg�p���郁�\�b�h
//

@interface ApplicationManager (Internal)

// �^����ꂽ�p�X�����ɁA�ݒ肳��Ă��Ȃ������f�[�^�̃p�X��⊮����
- (void)setUnsetPathsWithPath:(NSString *)path;

// �ړ��R���g���[���̃A�N�e�B�x�[�g
- (void)activateMoveControl;

@end


//
//  ���[�U�C���^�t�F�[�X���Ǘ����A���͏����̐U�蕪���Ȃǂ��s���N���X
//

@implementation ApplicationManager

// ����N�����ɃE�B���h�E�𒆉��Ɉړ������邽�߂̃t���O
static BOOL isFirstRun;

// �o�C���f�B���O�̏����l�ݒ�
+ (void)initialize {
	// �t�H���g���\���̂��߂̃g�����X�t�H�[�}�̓o�^
	[NSValueTransformer setValueTransformer:[[[NMFontTransformer alloc] init] autorelease]
									forName:@"NMFontTransformer"];
	
	// ���ݒ菉���l�̐ݒ�
    NSDictionary *initialValues =
		[NSDictionary dictionaryWithObjectsAndKeys:
			// ���r�̏����i��{�I�ɟT���������낤����ON���f�t�H���g�ɂ���j
			[NSNumber numberWithBool:YES], @"removeRubies",
			// �S�������̑Ώ�
			[NSNumber numberWithBool:YES], @"fullSearchEijiro",
			[NSNumber numberWithBool:YES], @"fullSearchRyakugoro",
			[NSNumber numberWithBool:YES], @"fullSearchWaijiro",
			[NSNumber numberWithBool:YES], @"fullSearchReijiro",
			// �f�t�H���g�t�H���g
			@"HiraKakuPro-W3,12.000000", @"font",
			nil];
    NSUserDefaultsController *defaultsController =
        [NSUserDefaultsController sharedUserDefaultsController];
    [defaultsController setInitialValues:initialValues];

	// ����N�������ǂ����𔻒肷��
	isFirstRun = ([[NSUserDefaults standardUserDefaults] boolForKey:@"NSWindow Frame EIJIRO Viewer"] == nil);
}

// ������
- (void)awakeFromNib {
	// �ǂݏグ�}�l�[�W���̏�����
	speechManager = [[NMSpeechManager alloc] initWithStopMode:kImmediate
													   target:self
										speakingStartedMethod:@selector(speakingStarted)
									 speakingPosChangedMethod:@selector(speakingPosChanged:)
										   speakingDoneMethod:@selector(speakingDone)
										   errorOccuredMethod:@selector(speakingErrorOccured:)];
	
	// ���ʕ\���p�����ƃL���b�V���t�H���g�̍쐬
	NSString *fontDesc = [[[NSUserDefaultsController sharedUserDefaultsController] defaults]
		valueForKey:@"font"];
	if (fontDesc) {
		int commaPos = [fontDesc rangeOfString:@","].location;
		if (commaPos != NSNotFound) {
			NSString *fontName = [fontDesc substringToIndex:commaPos];
			float fontSize = [[fontDesc substringFromIndex:commaPos+1] floatValue];
			if (fontSize == 0.0) {
				fontSize = 12.0;
			}
			font = [NSFont fontWithName:fontName size:fontSize];
		}
	}
	if (!font) {
		font = [NSFont fontWithName:@"HiraKakuPro-W3" size:12.0];
	}
	resultAttributes = [[NSMutableDictionary dictionary] retain];
	[resultAttributes setObject:font forKey:NSFontAttributeName];
	
	// �X�N���[���ꏊ�ۑ��p�ϐ��̏�����
	visibleRectDict = [[NSMutableDictionary dictionary] retain];

	// �q�X�g���p�ϐ��̏�����
	searchWordList = [[NSMutableArray array] retain];
	historyPos = 0;

	// �q�X�g���m��Ɋւ���t���O�̏�����
	isWordJustFixed = NO;
	wasFullSearch = NO;
	
	// �ړ��R���g���[���̏�����
	[[moveControl cell] setTrackingMode:NSSegmentSwitchTrackingMomentary];
	[moveControl setSegmentCount:2];
    [moveControl setImage:[NSImage imageNamed:@"back"] forSegment:0];
    [moveControl setImage:[NSImage imageNamed:@"forward"] forSegment:1];
	[moveControl setEnabled:NO forSegment:0];
	[moveControl setEnabled:NO forSegment:1];
	[moveControl setAction:@selector(moveControlPressed:)];
	[moveControl setTarget:self];

	// �c�[���o�[���Z�b�g
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"EIJIRO Viewer"];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[toolbar setDelegate:self];
	[mainWindow setToolbar:toolbar];
	
	// ����N�����̓��C���E�B���h�E�𒆉��Ɉړ����āA�c�[���o�[�̕\�����[�h���A�C�R���݂̂ɐݒ�
	if (isFirstRun) {
		[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
		[mainWindow center];
	}
	
	// ���C���E�B���h�E�̕\��
	[mainWindow makeKeyAndOrderFront:self];
	[mainWindow makeFirstResponder:searchField];
}

// �N���[���A�b�v
- (void)dealloc {
	[resultAttributes release];
	[visibleRectDict release];
	[searchWordList release];
	[speechManager release];
	[super dealloc];
}

// �S�������V�[�g�̕\��
- (IBAction)fullSearch:(id)sender {
	[[[NSUserDefaultsController sharedUserDefaultsController] values]
			setValue:@"" forKey:@"fullSearchNotification"];
	// �����t�B�[���h�̕�����������Ώۂɂ���
	[fullSearchField setStringValue:[searchField stringValue]];
	// �V�[�g�̕\��
	[NSApp beginSheet:fullSearchWindow
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:@selector(fullSearchSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

// �S�������V�[�g�̏���
- (void)fullSearchSheetDidEnd:(NSWindow *)sheet
				   returnCode:(int)returnCode
				  contextInfo:(void *)contextInfo
{
	// �V�[�g���B��
	[fullSearchWindow orderOut:self];
	// �J�n���I�����ꂽ�ꍇ
	if (returnCode == 0) {
		// ���݂̕�������m��
		[self fixCurrentSearchString];
		// �q�X�g���Q�Ǝ��ɑS�������𔽉f�����Ȃ����߂Ƀt���O�𗧂ĂĂ���
		wasFullSearch = YES;
		// �S�������̊J�n
		[searchManager doFullSearchForString:[fullSearchField stringValue]];
	}
}

// �S�������V�[�g�ŊJ�n���I�����ꂽ�ꍇ
- (IBAction)startFullSearch:(id)sender {
	if ([[fullSearchField stringValue] length] == 0) {
		[[[NSUserDefaultsController sharedUserDefaultsController] values]
			setValue:NSLocalizedString(@"FullSearchNoTarget", @"") forKey:@"fullSearchNotification"];
		NSBeep();
		return;
	}
	id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
	BOOL searchEijiro = [[values valueForKey:@"fullSearchEijiro"] boolValue];
	BOOL searchRyakugoro = [[values valueForKey:@"fullSearchRyakugoro"] boolValue];
	BOOL searchWaeijiro = [[values valueForKey:@"fullSearchWaeijiro"] boolValue];
	BOOL searchReijiro = [[values valueForKey:@"fullSearchReijiro"] boolValue];
	if (!searchEijiro && !searchRyakugoro && !searchWaeijiro && !searchReijiro) {
		[[[NSUserDefaultsController sharedUserDefaultsController] values]
			setValue:NSLocalizedString(@"FullSearchNoDictionary", @"") forKey:@"fullSearchNotification"];
		NSBeep();
		return;
	}
	[NSApp endSheet:fullSearchWindow returnCode:0];
}

// �S�������V�[�g�ŃL�����Z�����I�����ꂽ�ꍇ
- (IBAction)cancelFullSearch:(id)sender {
	[NSApp endSheet:fullSearchWindow returnCode:1];
}

// ���ݒ�p�l����\��
- (IBAction)showPreferences:(id)sender {
	[preferencesWindow center];
	[preferencesWindow makeKeyAndOrderFront:self];
}

// ���ׂĂ̎����f�[�^�̃p�X���N���A
- (IBAction)clearDictionaryPaths:(id)sender {
	id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
	[values setValue:@"" forKey:@"eijiroPath"];
	[values setValue:@"" forKey:@"ryakugoroPath"];
	[values setValue:@"" forKey:@"waeijiroPath"];
	[values setValue:@"" forKey:@"reijiroPath"];
}

// �p���Y�f�[�^�̃p�X���w��
- (IBAction)referEijiroPath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	int ret = [openPanel runModalForTypes:[NSArray arrayWithObject:@"txt"]];
	if (ret == NSOKButton) {
		NSString *filePath = [openPanel filename];
		[[[NSUserDefaultsController sharedUserDefaultsController] values]
			setValue:filePath forKey:@"eijiroPath"];
		[self setUnsetPathsWithPath:filePath];
	}
}

// �Ꭻ�Y�f�[�^�̃p�X���w��
- (IBAction)referReijiroPath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	int ret = [openPanel runModalForTypes:[NSArray arrayWithObject:@"txt"]];
	if (ret == NSOKButton) {
		NSString *filePath = [openPanel filename];
		[[[NSUserDefaultsController sharedUserDefaultsController] values]
			setValue:filePath forKey:@"reijiroPath"];
		[self setUnsetPathsWithPath:filePath];
	}
}

// ����Y�f�[�^�̃p�X���w��
- (IBAction)referRyakugoroPath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	int ret = [openPanel runModalForTypes:[NSArray arrayWithObject:@"txt"]];
	if (ret == NSOKButton) {
		NSString *filePath = [openPanel filename];
		[[[NSUserDefaultsController sharedUserDefaultsController] values]
			setValue:filePath forKey:@"ryakugoroPath"];
		[self setUnsetPathsWithPath:filePath];
	}
}

// �a�p���Y�f�[�^�̃p�X���w��
- (IBAction)referWaeijiroPath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	int ret = [openPanel runModalForTypes:[NSArray arrayWithObject:@"txt"]];
	if (ret == NSOKButton) {
		NSString *filePath = [openPanel filename];
		[[[NSUserDefaultsController sharedUserDefaultsController] values]
			setValue:filePath forKey:@"waeijiroPath"];
		[self setUnsetPathsWithPath:filePath];
	}
}

// �^����ꂽ�p�X�����ɁA�ݒ肳��Ă��Ȃ������f�[�^�̃p�X��⊮����
- (void)setUnsetPathsWithPath:(NSString *)aPath {
	id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
	NSString *eijiroPath = [values valueForKey:@"eijiroPath"];
	NSString *ryakugoroPath = [values valueForKey:@"ryakugoroPath"];
	NSString *waeijiroPath = [values valueForKey:@"waeijiroPath"];
	NSString *reijiroPath = [values valueForKey:@"reijiroPath"];
	
	NSString *basePath = [aPath stringByDeletingLastPathComponent];
	NSString *versionStr =
		[[aPath stringByDeletingPathExtension] substringFromIndex:[aPath length]-6];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (!eijiroPath || [eijiroPath length] == 0) {
		eijiroPath = [basePath stringByAppendingPathComponent:
			[NSString stringWithFormat:@"EIJIRO%@.TXT", versionStr]];
		if ([fileManager fileExistsAtPath:eijiroPath]) {
			[values setValue:eijiroPath forKey:@"waeijiroPath"];
		}
	}
	if (!ryakugoroPath || [ryakugoroPath length] == 0) {
		ryakugoroPath = [basePath stringByAppendingPathComponent:
			[NSString stringWithFormat:@"RYAKU%@.TXT", versionStr]];
		if ([fileManager fileExistsAtPath:ryakugoroPath]) {
			[values setValue:ryakugoroPath forKey:@"ryakugoroPath"];
		}
	}
	if (!waeijiroPath || [waeijiroPath length] == 0) {
		waeijiroPath = [basePath stringByAppendingPathComponent:
			[NSString stringWithFormat:@"WAEIJI%@.TXT", versionStr]];
		if ([fileManager fileExistsAtPath:waeijiroPath]) {
			[values setValue:waeijiroPath forKey:@"waeijiroPath"];
		}
	}
	if (!reijiroPath || [reijiroPath length] == 0) {
		reijiroPath = [basePath stringByAppendingPathComponent:
			[NSString stringWithFormat:@"REIJI%@.TXT", versionStr]];
		if ([fileManager fileExistsAtPath:reijiroPath]) {
			[values setValue:reijiroPath forKey:@"reijiroPath"];
		}
	}
}

// �t�H���g�I���p�l����\������
- (IBAction)selectFont:(id)sender {
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:font isMultiple:NO];
	[fontManager setDelegate:self];
	[fontManager orderFrontFontPanel:self];
}

// �t�H���g���ύX���ꂽ�Ƃ��ɌĂяo����郁�\�b�h
- (void)changeFont:(id)sender {
	font = [sender convertFont:font];
	[resultAttributes setObject:font forKey:NSFontAttributeName];
	NSTextStorage *resultStorage = [resultView textStorage];
	[resultStorage setAttributes:resultAttributes range:NSMakeRange(0, [resultStorage length])];
	[[[NSUserDefaultsController sharedUserDefaultsController] defaults]
		setValue:[NSString stringWithFormat:@"%@,%f", [font fontName], [font pointSize]]
		  forKey:@"font"];
}

// �c�[���o�[���ڂ��擾���邽�߂ɃR�[������郁�\�b�h
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	 itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	
	[item setLabel:NSLocalizedString(itemIdentifier, itemIdentifier)];
	[item setPaletteLabel:NSLocalizedString(itemIdentifier, itemIdentifier)];
	
	// �ړ��R���g���[��
	if ([itemIdentifier isEqualToString:@"TBI Move"]) {
		[item setView:moveView];
		NSSize viewSize = [moveView bounds].size;
		[item setMinSize:viewSize];
		[item setMaxSize:viewSize];
	}
	// �����{�^��
	else if ([itemIdentifier isEqualToString:@"TBI Pronounce"]) {
		[item setView:pronounceView];
		NSSize viewSize = [pronounceView bounds].size;
		[item setMinSize:viewSize];
		[item setMaxSize:viewSize];
	}
	// �S�������{�^��
	else if ([itemIdentifier isEqualToString:@"TBI FullSearch"]) {
		[item setView:fullSearchView];
		NSSize viewSize = [fullSearchView bounds].size;
		[item setMinSize:viewSize];
		[item setMaxSize:viewSize];
	}
	// �����t�B�[���h
	else if ([itemIdentifier isEqualToString:@"TBI Search"]) {
		[item setView:searchView];
		float viewHeight = [searchView bounds].size.height;
		[item setMinSize:NSMakeSize(40, viewHeight)];
		[item setMaxSize:NSMakeSize(400, viewHeight)];
	}
	return item;
}

// �g�p�\�ȃc�[���o�[����
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
		@"TBI Move",
		@"TBI Pronounce",
		@"TBI Search",
		@"TBI FullSearch",
		NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier,
		NSToolbarPrintItemIdentifier,
		nil];
}

// �f�t�H���g�̃c�[���o�[����
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:
		@"TBI Move",
		NSToolbarSeparatorItemIdentifier,
		@"TBI Pronounce",
		@"TBI Search",
		nil];
}

// �����t�B�[���h�̐�p�G�f�B�^�����^�[������
- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
	if (anObject == searchField) {
		return [(NMTextField *) searchField fieldEditor];
	}
	return nil;
}

// �A�v���P�[�V�������A�N�e�B�u�ɂȂ����Ƃ��Ɍ����t�B�[���h�Ƀt�H�[�J�X�����킹��
- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
	[mainWindow makeFirstResponder:searchField];
}

// �A�v���P�[�V��������A�N�e�B�u�ɂȂ�Ƃ��ɕ�������m�肷��
- (void)applicationDidResignActive:(NSNotification *)aNotification {
	[self fixCurrentSearchString];
}

// ApplicationManager �� SearchManager �����C���X���b�h�̎����ɓo�^���āA
// �O������Q�Ƃł���悤�ɂ���B
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// ���C���X���b�h�̎�����ApplicationManager��SearchManager��o�^���āA
	// �O������Q�Ƃł���悤�ɂ���
	NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
	[threadDict setValue:self forKey:@"ApplicationManager"];
	[threadDict setValue:searchManager forKey:@"SearchManager"];

	// ���̃I�u�W�F�N�g���T�[�r�X�@�\�̃v���o�C�_�Ƃ��ēo�^����
	[NSApp setServicesProvider:self];
	
	// �����f�[�^�̃p�X���ݒ肳��Ă��Ȃ���Ί��ݒ�p�l����\��
 	id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
	NSString *eijiroPath = [values valueForKey:@"eijiroPath"];
	NSString *ryakugoroPath = [values valueForKey:@"ryakugoroPath"];
	NSString *waeijiroPath = [values valueForKey:@"waeijiroPath"];
	NSString *reijiroPath = [values valueForKey:@"reijiroPath"];
	if (!eijiroPath && !ryakugoroPath && !waeijiroPath && !reijiroPath) {
		[self showPreferences:self];
	}
}

// �Ō�̃E�B���h�E������ꂽ��I������
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

// ���C���E�B���h�E������ꂽ��I������
- (void)windowWillClose:(NSNotification *)aNotification {
	// ���ݒ�E�B���h�E��delegate�͎w�肵�Ă��Ȃ��̂ŁA
	// ���̃��\�b�h�̓��C���E�B���h�E����̂݌Ăяo�����B
	[NSApp terminate:self];
}

// �������ʕ\���̂��߂̑������w�肵�����������^�[������
- (NSDictionary *)resultAttributes {
	return resultAttributes;
}

// �ǂݏグ�J�n���ɃR�[���o�b�N�����
- (void)speakingStarted {
	[pronounceButton setState:NSOnState];
}

// �ǂݏグ�ʒu�̕ω����ɃR�[���o�b�N�����
- (void)speakingPosChanged:(id)sender {
	// �ǂݏグ�Ώۂ̒P���I������
	NSRange currentRange = NSMakeRange([speechManager currentPos] + speechStartPos,
									   [speechManager currentLength]);
	[speakingView scrollRangeToVisible:currentRange];
	[speakingView setSelectedRange:currentRange];
	[speakingView display];
}

// �ǂݏグ�I�����ɃR�[���o�b�N�����
- (void)speakingDone {
	// �ǂݏグ�{�^����OFF�ɂ���
	[pronounceButton setState:NSOffState];
	// �ǂݏグ�Ώۂ̃r���[�̑I��͈͂����ɖ߂�
	[speakingView setSelectedRange:selectionRange];
}

// �ǂݏグ���ɃG���[���N�����Ƃ��ɃR�[���o�b�N�����
- (void)speakingErrorOccured:(id)sender {
	NSRunAlertPanel(@"Speech Error",
					[NSString stringWithFormat:@"Error %d occurred.", [speechManager lastError]],
					@"OK", nil, nil);
}

// ���ʕ\���r���[�̓���L�[�̉����
- (BOOL)textView:(NSTextView *)aTextView
                    doCommandBySelector:(SEL)aSelector
{
	// ESC�L�[�Ō����i�S�������̂݁j�𒆒f
	if (aSelector == @selector(cancel:)) {
		[searchManager stopSearching];
		return YES;
	}
	// �^�u�L�[�Ō����t�B�[���h�Ƀt�H�[�J�X���ړ�������
	else if (aSelector == @selector(insertTab:)) {
		[mainWindow makeFirstResponder:searchField];
		return YES;
	}
	// ���^�[���L�[�Ō����t�B�[���h�Ƀt�H�[�J�X���ړ�������
	else if (aSelector == @selector(insertNewline:)) {
		[mainWindow makeFirstResponder:searchField];
		return YES;
	}
	// Cmd+���őO�Ɉړ�
	else if (aSelector == @selector(moveToBeginningOfLine:)) {
		[self searchPrevious:self];
		return YES;
	}
	// Cmd+�E�Ŏ��Ɉړ�
	else if (aSelector == @selector(moveToEndOfLine:)) {
		[self searchNext:self];
		return YES;
	}
	return NO;
}

// ���������t�B�[���h�̓���L�[�̉����
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
	// ESC�L�[�Ō����i�S�������̂݁j�𒆒f
	if (command == @selector(cancel:)) {
		[searchManager stopSearching];
		return YES;
	}
	// �^�u�L�[�Ńt�H�[�J�X�����ʕ\���r���[�Ɉړ�����
	else if (command == @selector(insertTab:)) {
		// �q�X�g���ǉ����m��
		[self fixCurrentSearchString];
		// �t�H�[�J�X�����ʕ\���r���[�Ɉړ�
		[mainWindow makeFirstResponder:resultView];
		return YES;
	}
	// �X�N���[���z�[�������ʕ\���r���[�ɓ`����
	else if (command == @selector(scrollToBeginningOfDocument:)) {
		[resultView doCommandBySelector:@selector(scrollToBeginningOfDocument:)];
		return YES;
	}
	// �X�N���[���G���h�����ʕ\���r���[�ɓ`����
	else if (command == @selector(scrollToEndOfDocument:)) {
		[resultView doCommandBySelector:@selector(scrollToEndOfDocument:)];
		return YES;
	}
	// �X�N���[���_�E�������ʕ\���r���[�ɓ`����
	else if (command == @selector(scrollPageDown:)) {
		[resultView doCommandBySelector:@selector(scrollPageDown:)];
		return YES;
	}
	// �X�N���[���A�b�v�����ʕ\���r���[�ɓ`����
	else if (command == @selector(scrollPageUp:)) {
		[resultView doCommandBySelector:@selector(scrollPageUp:)];
		return YES;
	}
	// Cmd+���Ŏ��Ɉړ�
	else if (command == @selector(moveToBeginningOfLine:)) {
		[self searchPrevious:self];
		return YES;
	}
	// Cmd+�E�Ŏ��Ɉړ�
	else if (command == @selector(moveToEndOfLine:)) {
		[self searchNext:self];
		return YES;
	}
	return NO;
}

// ��ʓI�Ȍ�����̓��͂͂����ɓn�����B
// ���^�[���L�[���͎��ɂ�fixSearchString:�A�N�V�������R�[�������B
- (void)controlTextDidChange:(NSNotification *)aNotification {
	wasFullSearch = NO;
	// �q�X�g�����Q�Ƃ��Ă���ꍇ�ɂ́A���݈ʒu�ȍ~���폜����
	if (historyPos > 0) {
		[searchWordList removeObjectsInRange:NSMakeRange([searchWordList count]-historyPos, historyPos)];
		historyPos = 0;
	}
	// �q�X�g���ǉ��m�蒼��ł���Β��O�̒P��̃X�N���[���ʒu��ۑ�
	if (isWordJustFixed) {
		if ([searchWordList count] > 0) {
			NSString *lastSearchWord = [searchWordList lastObject];
			[visibleRectDict setValue:NSStringFromRect([resultView visibleRect]) forKey:lastSearchWord];
		}
		isWordJustFixed = NO;
	}
	// �ړ��R���g���[���̃A�N�e�B�x�[�g
	[self activateMoveControl];
	// �ǂݏグ���ł���Β��f
	if ([speechManager isSpeaking]) {
		[speechManager stopSpeaking];
		selectionRange = NSMakeRange(0, 0);
		[resultView setSelectedRange:selectionRange];
	}
	// �ǂݏグ�{�^���̃A�N�e�B�x�[�g
	[self activatePronounceButton];
	// �J�����g�̌������[�h�̃X�N���[���ʒu�����N���A
	NSString *searchStr = [searchField stringValue];
	[visibleRectDict removeObjectForKey:searchStr];
	// ����
	[searchManager searchString:searchStr];
}

// ���������̃q�X�g���ǉ����m�肵�āA�����t�B�[���h��S�I������
- (IBAction)fixSearchString:(id)sender {
	[self fixCurrentSearchString];
	[mainWindow makeFirstResponder:searchField];
}

// ����������̃q�X�g���ǉ����m�肷��
- (void)fixCurrentSearchString {
	// �q�X�g���Q�ƒ��ł���Ή������Ȃ�
	if (historyPos > 0) {
		return;
	}
	// �q�X�g���̍Ō�ƈ�v���Ȃ��ꍇ�ɂ̓q�X�g����ǉ�
	NSString *searchString = [searchField stringValue];
	if (searchString && [searchString length] > 0 &&
		[searchString compare:[searchWordList lastObject]] != NSOrderedSame)
	{
		[searchWordList addObject:searchString];
	}
	// �X�N���[���ʒu�ۑ��p�Ƀq�X�g�����m�肵���t���O�𗧂Ă�
	isWordJustFixed = YES;
	// �ړ��R���g���[���̃A�N�e�B�x�[�g
	[self activateMoveControl];
}

// �ړ��R���g���[���̃A�N�e�B�x�[�g
- (void)activateMoveControl {
	NSString *searchString = [searchField stringValue];
	unsigned int historyCount = [searchWordList count];
	if (historyPos == 0 && [searchString length] > 0 &&
		![searchString isEqualToString:[searchWordList lastObject]])
	{
		historyCount++;
	}
	[moveControl setEnabled:(historyCount > 1 && historyPos < historyCount-1) forSegment:0];
	[moveControl setEnabled:(historyPos > 0) forSegment:1];
}

// �ړ��R���g���[���������ꂽ�Ƃ��ɃR�[�������
- (IBAction)moveControlPressed:(id)sender {
	if ([moveControl selectedSegment] == 0) {
		[self searchPrevious:self];
	} else {
		[self searchNext:self];
	}
}

// �O������
- (IBAction)searchPrevious:(id)sender {
	// �ړ��ł��邱�Ƃ��m�F
	unsigned int historyCount = [searchWordList count];
	NSString *searchString = [searchField stringValue];
	if (historyPos == 0 && [searchString length] > 0 &&
		![searchString isEqualToString:[searchWordList lastObject]])
	{
		historyCount++;
	}
	if (historyCount <= 1 || historyPos >= historyCount-1) {
		NSBeep();
		return;
	}
	// ���݂̃X�N���[���ʒu��ۑ�
	[visibleRectDict setValue:NSStringFromRect([resultView visibleRect]) forKey:[searchField stringValue]];
	// �J�����g�̌�����������m��
	if (historyPos == 0) {
		if (wasFullSearch) {
			[searchField setStringValue:[searchWordList lastObject]];
			[mainWindow makeFirstResponder:searchField];
			[searchManager searchString:[searchField stringValue]];
			wasFullSearch = NO;
			return;
		} else {
			[self fixCurrentSearchString];
		}
	}
	// �ړ�����
	wasFullSearch = NO;
	historyPos++;
	[searchField setStringValue:[searchWordList objectAtIndex:[searchWordList count]-1-historyPos]];
	[mainWindow makeFirstResponder:searchField];
	// �ړ��R���g���[���̃A�N�e�B�x�[�g
	[self activateMoveControl];
	// ����
	[searchManager searchString:[searchField stringValue]];
}

// ��������
- (IBAction)searchNext:(id)sender {
	// �ړ��ł��邱�Ƃ��m�F
	if (historyPos == 0) {
		NSBeep();
		return;
	}
	// ���݂̃X�N���[���ʒu��ۑ�
	[visibleRectDict setValue:NSStringFromRect([resultView visibleRect]) forKey:[searchField stringValue]];
	// �ړ�����
	wasFullSearch = NO;
	historyPos--;
	[searchField setStringValue:[searchWordList objectAtIndex:[searchWordList count]-1-historyPos]];
	[mainWindow makeFirstResponder:searchField];
	// �ړ��R���g���[���̃A�N�e�B�x�[�g
	[self activateMoveControl];
	// ����
	[searchManager searchString:[searchField stringValue]];
}

// �����N���N���b�N���ꂽ�Ƃ��ɌĂяo����郁�\�b�h
- (BOOL)textView:(NSTextView *)textView
   clickedOnLink:(id)link
		 atIndex:(unsigned)charIndex
{
	// ���݂̃X�N���[���ʒu��ۑ�
	[visibleRectDict setValue:NSStringFromRect([resultView visibleRect]) forKey:[searchField stringValue]];
	// �q�X�g�����Q�Ƃ��Ă���ꍇ�ɂ́A���݈ʒu�ȍ~���폜����
	[self clearSubsequentHistory];
	// ���݂̕�����i�C���ΏۂɂȂ��Ă�����́j���m��
	[self fixCurrentSearchString];
	// �C��������Ō����t�B�[���h��u������
	[searchField setStringValue:link];
	// �C��������������m��
	[self fixCurrentSearchString];
	[mainWindow makeFirstResponder:searchField];
	// ����
	[searchManager searchString:[searchField stringValue]];
	return YES;
}

// �^����ꂽ��������Ō�ɎQ�Ƃ����Ƃ��̃X�N���[���ʒu�ɖ߂�
- (void)scrollToLastRectForString:(NSString *)searchWord {
	if (!searchWord) {
		return;
	}
	NSString *rectStr = [visibleRectDict valueForKey:searchWord];
	if (!rectStr) {
		return;
	}
	[resultView scrollRectToVisible:NSRectFromString(rectStr)];
}

// �ǂݏグ���J�n/��~����
- (IBAction)pronounce:(id)sender {
	if ([speechManager isSpeaking]) {
		[self stopSpeaking:self];
	} else {
		[self startSpeaking:self];
	}
}

// �ǂݏグ���J�n����
- (IBAction)startSpeaking:(id)sender {
	// �ǂݏグ���ł���Έ�U���~����
	if ([speechManager isSpeaking]) {
		[self stopSpeaking:self];
	}
	// �����t�B�[���h�Ƀt�H�[�J�X������Ό����t�B�[���h���A�����łȂ���Ό��ʃr���[��ǂݏグ�Ώۂɂ���
	BOOL searchWordFieldFocused = [[searchField window] firstResponder] == [searchField currentEditor];
	speakingView = searchWordFieldFocused?
		((NSTextView *) [searchField currentEditor]): resultView;
	if (!speakingView) {
		return;
	}
	// ���݂̑I��͈͂��L�����Ă���
	selectionRange = [speakingView selectedRange];
	NSString *targetText;
	if (selectionRange.length == 0) {
		targetText = [speakingView string];
		speechStartPos = 0;
	} else {
		targetText = [[speakingView string] substringWithRange:selectionRange];
		speechStartPos = selectionRange.location;
	}
	// �ǂݏグ�Ώۂ̒������`�F�b�N
	if ([targetText length] == 0) {
		return;
	}
	// �J�n
	[speechManager speakText:targetText];
}

// �ǂݏグ�̒��~
- (IBAction)stopSpeaking:(id)sender {
	if ([speechManager isSpeaking]) {
		[speechManager stopSpeaking];
		[resultView setSelectedRange:selectionRange];
	}
	[pronounceButton setState:NSOffState];
}

// ��1�C������I������
- (IBAction)searchFirstGuess:(id)sender {
	wasFullSearch = NO;
	// �q�X�g�����Q�Ƃ��Ă���ꍇ�ɂ́A���݈ʒu�ȍ~���폜����
	[self clearSubsequentHistory];
	// ���݂̓��͕�������m��
	[self fixCurrentSearchString];
	// �C�����𔽉f������
	NSString *firstGuess = [searchManager firstGuess];
	[searchField setStringValue:firstGuess];
	// �C��������������m��
	[self fixCurrentSearchString];
	// �����t�B�[���h��S�I��
	[mainWindow makeFirstResponder:searchField];
	// ����
	[searchManager searchString:firstGuess];
}

// ��2�C������I������
- (IBAction)searchSecondGuess:(id)sender {
	wasFullSearch = NO;
	// �q�X�g�����Q�Ƃ��Ă���ꍇ�ɂ́A���݈ʒu�ȍ~���폜����
	[self clearSubsequentHistory];
	// ���݂̓��͕�������m��
	[self fixCurrentSearchString];
	// �C�����𔽉f������
	NSString *secondGuess = [searchManager secondGuess];
	[searchField setStringValue:secondGuess];
	// �C��������������m��
	[self fixCurrentSearchString];
	// �����t�B�[���h��S�I��
	[mainWindow makeFirstResponder:searchField];
	// ����
	[searchManager searchString:secondGuess];
}

// ���݂̈ʒu�ȍ~�̃q�X�g�����폜����
- (void)clearSubsequentHistory {
	if (historyPos > 0) {
		[searchWordList removeObjectsInRange:NSMakeRange([searchWordList count]-historyPos, historyPos)];
		historyPos = 0;
	}
}

// ���j���[���ڂ̃A�N�e�B�x�[�g
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	switch ([menuItem tag]) {
		// �u�O�ɖ߂�v
		case 50: {
			unsigned int historyCount = [searchWordList count];
			NSString *searchString = [searchField stringValue];
			if (historyPos == 0 && [searchString length] > 0 &&
					![searchString isEqualToString:[searchWordList lastObject]])
			{
				historyCount++;
			}
			return (historyCount > 1 && historyPos < historyCount-1);
		}
		// �u���ɐi�ށv
		case 51:
			return (historyPos > 0);
		// �u�ŏ��̏C�����v
		case 52:
			return ([searchManager firstGuess] != nil);
		// �u���̏C�����v
		case 53:
			return ([searchManager secondGuess] != nil);
	}
	return YES;
}

// ������̌������s��
- (IBAction)performFindPanelAction:(id)sender {
	[mainWindow makeFirstResponder:resultView];
	[resultView performFindPanelAction:sender];
}

// �I��͈͂ɃW�����v
- (IBAction)centerSelectionInVisibleArea:(id)sender {
	[mainWindow makeFirstResponder:resultView];
	[resultView centerSelectionInVisibleArea:sender];
}

// �T�[�r�X�@�\����̌���
- (void)searchStringForService:(NSPasteboard *)pboard
					  userData:(NSString *)userData
						 error:(NSString **)error
{
	// �y�[�X�g�{�[�h���當���񂪎擾�ł��邱�Ƃ��m�F����
	if (![[pboard types] containsObject:NSStringPboardType]) {
		*error = @"Error: couldn't get text.";
		return;
	}

	// ������������擾
	NSString *pboardString = [pboard stringForType:NSStringPboardType];
	if (!pboardString) {
		*error = @"Error: couldn't get text.";
		return;
	}
	
	// �����t�B�[���h�Ɍ�����������Z�b�g
	[searchField setStringValue:pboardString];
	
	// �A�v���P�[�V�������A�N�e�B�u�ɂ���
	[NSApp activateIgnoringOtherApps:YES];
	
	// ������������m��
	[self fixSearchString:self];
	
	// �ǂݏグ�{�^���̃A�N�e�B�x�[�g
	[self activatePronounceButton];
	
	// ����
	[searchManager searchString:pboardString];
}

// �ǂݏグ�{�^���̃A�N�e�B�x�[�g
- (void)activatePronounceButton {
	if ([[searchField stringValue] length] == 0) {
		[pronounceButton setEnabled:NO];
	} else {
		[pronounceButton setEnabled:YES];
	}
}

@end
