//
//  SearchManager.h
//  EIJIRO Viewer
//
//  Created by numata on November 11, 2004.
//  Copyright 2004 Satoshi NUMATA. All rights reserved.
//

#import "SearchManager.h"

//#import <OgreKit/OgreKit.h>
#import <sys/time.h>

#import "StringUtil.h"
#import "ApplicationManager.h"


//
//  SearchManager �œ����I�Ɏg�p���郁���o���\�b�h
//

@interface SearchManager (Internal)

// ���C���X���b�h��UI��ύX���邽�߂̃��\�b�h
- (void)clearResult:(NSNumber *)searchIDObj;		// ���ʂ̃N���A
- (void)addResultLine:(NSArray *)lineInfo;			// ���ʂ̍s��ǉ�	
- (void)addSeparator:(NSNumber *)searchIDObj;		// �����Ԃ̃Z�p���[�^�̒ǉ�
- (void)prepareScrolling:(NSNumber *)searchIDObj;	// �X�N���[���ʒu�����̂��߂̑҂����킹
- (void)scrollToLastRect:(NSArray *)searchInfo;		// �X�N���[���ʒu�̕���
- (void)addNotFound:(NSArray *)searchInfo;			// ������Ȃ������ꍇ�̃��b�Z�[�W�̒ǉ�
- (void)addGuessForSearchWord:(NSString *)searchWord
					 searchID:(unsigned long)searchID;	// �C�����̒ǉ�
- (void)addFullSearchNotFound:(NSNumber *)searchIDObj;	// �S�������őΏۂ�������Ȃ������ꍇ�̃��b�Z�[�W�̒ǉ�
- (void)addFullSearchCanceledSeparator;					// �S�������̃L�����Z�����������b�Z�[�W�̒ǉ�

// ����ID�̐���
- (unsigned long)createSearchID;

// �ʏ팟���̂��߂̃o�C�i���T�[�`
- (int)searchForCString:(unsigned char *)cSearchStr
	   cSearchStrLength:(unsigned int)cSearchStrLength
				 inData:(NSData *)data
		   removeRubies:(BOOL)removeRubies
			searchIDObj:(NSNumber *)searchIDObj;

// �S������
- (void)fullSearchForString:(NSString *)searchStr
					 inData:(NSData *)data
			   removeRubies:(BOOL)removeRubies
			  currentLength:(unsigned int)currentLength
				totalLength:(unsigned int)totalLength
				   searchID:(unsigned long)searchID
				   titleStr:(NSString *)titleStr;

// ���K�\�����g�����S������
/*- (void)fullSearchForStringWithRegularExpression:(NSString *)searchStr
										  inData:(NSData *)data
									removeRubies:(BOOL)removeRubies
								   currentLength:(unsigned int)currentLength
									 totalLength:(unsigned int)totalLength
										searchID:(unsigned long)searchID
										titleStr:(NSString *)titleStr;*/

@end


//
//  �p���Y�����̌������s���N���X�B
//
//  �{���͑S�������ƒʏ팟���Ƃ𕪂������̂����AID�Ȃǂ̋��L��������Ƃ�₱�����̂ŁA
//  �����ɂ܂Ƃ߂Ēu���Ă���B
//

@implementation SearchManager

// ������
- (id)init {
	self = [super init];
	if (self) {
	}
	return self;
}

// �N���[���A�b�v
- (void)dealloc {
	[firstGuess release];
	[secondGuess release];
	[super dealloc];
}

// �V��������ID�̐���
- (unsigned long)createSearchID {
	struct timeval timeVal;
	gettimeofday(&timeVal, NULL);
	return timeVal.tv_usec + timeVal.tv_sec * 1000000;
}

// �^����ꂽ������ɑ΂��đS�����������s����
- (void)doFullSearchForString:(NSString *)searchStr {
	// �����Ώۂ�����
	if (!searchStr || [searchStr length] == 0) {
		NSBeep();
		return;
	}
	// �����t�B�[���h�������Ώۂ̕�����Œu������
	[searchField setStringValue:searchStr];
	// ���ʕ\���r���[�Ƀt�H�[�J�X���ړ�
	[mainWindow makeFirstResponder:resultView];
	// �V��������ID���쐬
	currentSearchID = [self createSearchID];
	// �S�������X���b�h���쐬
	NSArray *threadInfo = [[NSArray alloc] initWithObjects:searchStr,
		[NSNumber numberWithUnsignedLong:currentSearchID], nil];
	[NSThread detachNewThreadSelector:@selector(fullSearchProc:)
							 toTarget:self
						   withObject:threadInfo];
	[threadInfo release];
}

// �S�������X���b�h�p�̃��\�b�h
- (void)fullSearchProc:(NSArray *)threadInfo {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[NSThread setThreadPriority:0.1];

	NSString *searchStr = [threadInfo objectAtIndex:0];
	unsigned long searchID = [[threadInfo objectAtIndex:1] unsignedLongValue];
	NSNumber *searchIDObj = [NSNumber numberWithUnsignedLong:searchID];
	
	id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
	BOOL searchEijiro = [[values valueForKey:@"fullSearchEijiro"] boolValue];
	BOOL searchRyakugoro = [[values valueForKey:@"fullSearchRyakugoro"] boolValue];
	BOOL searchWaeijiro = [[values valueForKey:@"fullSearchWaeijiro"] boolValue];
	BOOL searchReijiro = [[values valueForKey:@"fullSearchReijiro"] boolValue];
	
	if (!searchEijiro && !searchRyakugoro && !searchWaeijiro && !searchReijiro) {
		NSBeep();
		return;
	}
	
	[self performSelectorOnMainThread:@selector(clearResult:)
						   withObject:searchIDObj
						waitUntilDone:YES];
	
	NSString *eijiroPath = [values valueForKey:@"eijiroPath"];
	NSString *ryakugoroPath = [values valueForKey:@"ryakugoroPath"];
	NSString *waeijiroPath = [values valueForKey:@"waeijiroPath"];
	NSString *reijiroPath = [values valueForKey:@"reijiroPath"];
	
	BOOL removeRubies = [[values valueForKey:@"removeRubies"] boolValue];
	
	NSData *eijiroData = [NSData dataWithContentsOfMappedFile:eijiroPath];
	NSData *ryakugoroData = [NSData dataWithContentsOfMappedFile:ryakugoroPath];
	NSData *waeijiroData = [NSData dataWithContentsOfMappedFile:waeijiroPath];
	NSData *reijiroData = [NSData dataWithContentsOfMappedFile:reijiroPath];

	unsigned int totalLength = 0;
	unsigned int currentLength = 0;
	if (searchEijiro) {
		totalLength += [eijiroData length];
	}
	if (searchRyakugoro) {
		totalLength += [ryakugoroData length];
	}
	if (searchWaeijiro) {
		totalLength += [waeijiroData length];
	}
	if (searchReijiro) {
		totalLength += [reijiroData length];
	}
	
	if (searchEijiro && currentSearchID == searchID) {
		NSString *titleStr = NSLocalizedString(@"FULLSEARCH_TITLE_EIJIRO", @"FULLSEARCH_TITLE_EIJIRO");
		[self fullSearchForString:searchStr
						   inData:eijiroData
					 removeRubies:removeRubies
					currentLength:currentLength
					  totalLength:totalLength
						 searchID:searchID
						 titleStr:titleStr];
		currentLength += [eijiroData length];
	}
	if (searchRyakugoro && currentSearchID == searchID) {
		NSString *titleStr = NSLocalizedString(@"FULLSEARCH_TITLE_RYAKUGORO", @"FULLSEARCH_TITLE_RYAKUGORO");
		[self fullSearchForString:searchStr
						   inData:ryakugoroData
					 removeRubies:removeRubies
					currentLength:currentLength
					  totalLength:totalLength
						 searchID:searchID
						 titleStr:titleStr];
		currentLength += [ryakugoroData length];
	}
	if (searchWaeijiro && currentSearchID == searchID) {
		NSString *titleStr = NSLocalizedString(@"FULLSEARCH_TITLE_WAEIJIRO", @"FULLSEARCH_TITLE_WAEIJIRO");
		[self fullSearchForString:searchStr
						   inData:waeijiroData
					 removeRubies:removeRubies
					currentLength:currentLength
					  totalLength:totalLength
						 searchID:searchID
						 titleStr:titleStr];
		currentLength += [waeijiroData length];
	}
	if (searchReijiro && currentSearchID == searchID) {
		NSString *titleStr = NSLocalizedString(@"FULLSEARCH_TITLE_REIJIRO", @"FULLSEARCH_TITLE_REIJIRO");
		[self fullSearchForString:searchStr
						   inData:reijiroData
					 removeRubies:removeRubies
					currentLength:currentLength
					  totalLength:totalLength
						 searchID:searchID
						 titleStr:titleStr];
	}
	
	NSArray *progInfo = [[NSArray alloc] initWithObjects:[NSNumber numberWithUnsignedLong:currentSearchID],
		[NSNumber numberWithDouble:0], nil];
	[self performSelectorOnMainThread:@selector(setProgress:)
						   withObject:progInfo
						waitUntilDone:YES];
	[progInfo release];

	[pool release];
}

// �^����ꂽ�f�[�^�ɑ΂��đS���������s��
- (void)fullSearchForString:(NSString *)searchStr
					 inData:(NSData *)data
			   removeRubies:(BOOL)removeRubies
			  currentLength:(unsigned int)currentLength
				totalLength:(unsigned int)totalLength
				   searchID:(unsigned long)searchID
				   titleStr:(NSString *)titleStr
{
	NSNumber *searchIDObj = [NSNumber numberWithUnsignedLong:searchID];
	const unsigned char *bytes = [data bytes];
	unsigned int length = [data length];
	unsigned int pos = 0;
	unsigned int lineStartPos;
	unsigned int lineEndPos;
	int lineCount = 0;
	int matchedCount = 0;
	NSData *searchStrData = [searchStr dataUsingEncoding:NSShiftJISStringEncoding];
	NSArray *titleInfo = [[NSArray alloc] initWithObjects:searchIDObj, titleStr, nil];
	[self performSelectorOnMainThread:@selector(addResultLine:)
						   withObject:titleInfo
						waitUntilDone:NO];
	[titleInfo release];
	while (pos < length) {
		lineStartPos = pos;
		pos++;
		lineEndPos = -1;
		while (pos < length) {
			unsigned char c = bytes[pos];
			pos++;
			if (isFirst2BytesCharacter(c)) {
				if (pos < length) {
					pos++;
				}
			} else if (c == 0x0a || c == 0x0d) {
				lineEndPos = pos - 1;
				break;
			}
		}
		if (lineEndPos < 0) {
			lineEndPos = length - 1;
		}
		unsigned char c = bytes[pos];
		if (c == 0x0a || c == 0x0d) {
			pos++;
		}
		unsigned int lineLength = lineEndPos - lineStartPos + 1;
		if (strContainsStr(bytes + lineStartPos, lineLength,
						   [searchStrData bytes], [searchStrData length]))
		{
			NSData *lineData = [data subdataWithRange:NSMakeRange(lineStartPos, lineLength)];
			NSString *lineStr = [[NSString alloc] initWithData:lineData encoding:NSShiftJISStringEncoding];
			NSString *ver80FixStr;
			if (removeRubies) {
				lineStr = [lineStr stringByRemovingRubies];
			}
			lineStr = [lineStr pronunciationSymbolFixedString];
			lineStr = [lineStr ver80FixedString];
			[self performSelectorOnMainThread:@selector(addResultLine:)
								   withObject:[NSArray arrayWithObjects:searchIDObj, lineStr, nil]
								waitUntilDone:NO];
			matchedCount++;
		}
		lineCount++;
		if (currentSearchID != searchID) {
			return;
		}
		if (lineCount % 10000 == 0) {
			NSArray *progInfo = [[NSArray alloc] initWithObjects:searchIDObj,
				[NSNumber numberWithDouble:(((double) (currentLength + pos) / totalLength) * 100.0)], nil];
			[self performSelectorOnMainThread:@selector(setProgress:)
								   withObject:progInfo
								waitUntilDone:NO];
			[progInfo release];
		}
	}
	if (matchedCount == 0) {
		[self performSelectorOnMainThread:@selector(addFullSearchNotFound:)
							   withObject:searchIDObj
							waitUntilDone:NO];
	}
	[self performSelectorOnMainThread:@selector(addSeparator:)
						   withObject:searchIDObj
						waitUntilDone:NO];
}

// �^����ꂽ�f�[�^�ɑ΂��đS���������s��
/*- (void)fullSearchForStringWithRegularExpression:(NSString *)searchStr
										  inData:(NSData *)data
									removeRubies:(BOOL)removeRubies
								   currentLength:(unsigned int)currentLength
									 totalLength:(unsigned int)totalLength
										searchID:(unsigned long)searchID
										titleStr:(NSString *)titleStr
{
	NSNumber *searchIDObj = [NSNumber numberWithUnsignedLong:searchID];
	const unsigned char *bytes = [data bytes];
	unsigned int length = [data length];
	unsigned int pos = 0;
	unsigned int lineStartPos;
	unsigned int lineEndPos;
	int lineCount = 0;
	int matchedCount = 0;
	NSData *searchStrData = [searchStr dataUsingEncoding:NSShiftJISStringEncoding];
	NSArray *titleInfo = [[NSArray alloc] initWithObjects:searchIDObj, titleStr, nil];
	[self performSelectorOnMainThread:@selector(addResultLine:)
						   withObject:titleInfo
						waitUntilDone:NO];
	[titleInfo release];
	while (pos < length) {
		lineStartPos = pos;
		pos++;
		lineEndPos = -1;
		while (pos < length) {
			unsigned char c = bytes[pos];
			pos++;
			if (isFirst2BytesCharacter(c)) {
				if (pos < length) {
					pos++;
				}
			} else if (c == 0x0a || c == 0x0d) {
				lineEndPos = pos - 1;
				break;
			}
		}
		if (lineEndPos < 0) {
			lineEndPos = length - 1;
		}
		unsigned char c = bytes[pos];
		if (c == 0x0a || c == 0x0d) {
			pos++;
		}
		unsigned int lineLength = lineEndPos - lineStartPos + 1;
		NSData *lineData = [data subdataWithRange:NSMakeRange(lineStartPos, lineLength)];
		NSString *lineStr = [[[NSString alloc] initWithData:lineData encoding:NSShiftJISStringEncoding] autorelease];
		NSRange matchingRange = [lineStr rangeOfRegularExpressionString:searchStr];
		if (matchingRange.location != NSNotFound) {
			if (removeRubies) {
				lineStr = [lineStr stringByRemovingRubies];
			}
			lineStr = [lineStr pronunciationSymbolFixedString];
			lineStr = [lineStr ver80FixedString];
			if (matchedCount == 0) {
				[self performSelectorOnMainThread:@selector(addResultLine:)
									   withObject:[NSArray arrayWithObjects:searchIDObj, titleStr, nil]
									waitUntilDone:NO];
			}
			[self performSelectorOnMainThread:@selector(addResultLine:)
								   withObject:[NSArray arrayWithObjects:searchIDObj, lineStr, nil]
								waitUntilDone:NO];
			matchedCount++;
		}
		lineCount++;
		if (currentSearchID != searchID) {
			return;
		}
		if (lineCount % 10000 == 0) {
			NSArray *progInfo = [[NSArray alloc] initWithObjects:searchIDObj,
				[NSNumber numberWithDouble:(((double) (currentLength + pos) / totalLength) * 100.0)], nil];
			[self performSelectorOnMainThread:@selector(setProgress:)
								   withObject:progInfo
								waitUntilDone:NO];
			[progInfo release];
		}
	}
	if (matchedCount == 0) {
		[self performSelectorOnMainThread:@selector(addFullSearchNotFound:)
							   withObject:searchIDObj
							waitUntilDone:NO];
	}
	[self performSelectorOnMainThread:@selector(addSeparator:)
						   withObject:searchIDObj
						waitUntilDone:NO];
}*/

// ���ʕ\���r���[�̃N���A
- (void)clearResult:(NSNumber *)searchIDObj {
	if ([searchIDObj unsignedLongValue] == currentSearchID) {
		[resultView setString:@""];
	}
}

// ���ʂ�ǉ�
- (void)addResultLine:(NSArray *)lineInfo {
	unsigned long searchID = [[lineInfo objectAtIndex:0] unsignedLongValue];
	if (currentSearchID == searchID) {
		NSString *line = [lineInfo objectAtIndex:1];
		unichar linkingChars[] = { 0x3c, 0x2192 };
		NSString *linkingPrefix = [NSString stringWithCharacters:linkingChars length:2];
		unichar endCharacter = 0x3e;
		NSString *linkingSuffix = [NSString stringWithCharacters:&endCharacter length:1];
		NSTextStorage *resultStorage = [resultView textStorage];
		while (YES) {
			// ����������
			NSRange linkingRange = [line rangeOfString:linkingPrefix];
			if (linkingRange.location == NSNotFound) {
				NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:line attributes:[applicationManager resultAttributes]];
				[resultStorage appendAttributedString:attrStr];
				[attrStr release];
				attrStr = [[NSAttributedString alloc] initWithString:@"\n" attributes:[applicationManager resultAttributes]];
				[resultStorage appendAttributedString:attrStr];
				[attrStr release];
				break;
			} else {
				NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:[line substringToIndex:linkingRange.location+2] attributes:[applicationManager resultAttributes]];
				[resultStorage appendAttributedString:attrStr];
				[attrStr release];
				NSString *rest = [line substringFromIndex:linkingRange.location+2];
				NSRange endRange = [rest rangeOfString:linkingSuffix];
				if (endRange.location == NSNotFound) {
					NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:rest attributes:[applicationManager resultAttributes]];
					[resultStorage appendAttributedString:attrStr];
					[attrStr release];
					attrStr = [[NSAttributedString alloc] initWithString:@"\n" attributes:[applicationManager resultAttributes]];
					[resultStorage appendAttributedString:attrStr];
					[attrStr release];
					break;
				} else {
					NSString *linkingWord = [rest substringToIndex:endRange.location];
					NSMutableDictionary *linkAttrDict =
						[NSMutableDictionary dictionaryWithDictionary:[applicationManager resultAttributes]];
					[linkAttrDict setObject:linkingWord forKey:NSLinkAttributeName];
					[linkAttrDict setObject:[NSCursor pointingHandCursor] forKey:NSCursorAttributeName];
					NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:linkingWord attributes:linkAttrDict];
					[resultStorage appendAttributedString:attrStr];
					[attrStr release];
					[[resultView window] resetCursorRects];
					line = [rest substringFromIndex:endRange.location];
				}
			}
		}
	}
}

// ������Ȃ������ꍇ�̃��b�Z�[�W�̒ǉ�
- (void)addNotFound:(NSArray *)searchInfo {
	NSNumber *searchIDObj = [searchInfo objectAtIndex:0];
	unsigned long searchID = [searchIDObj unsignedLongValue];
	if (currentSearchID == searchID) {
		NSString *searchStr = [searchInfo objectAtIndex:1];
		NSString *notFoundString = [NSString stringWithFormat:
			NSLocalizedString(@"SEARCH_NOTFOUND", @""), searchStr];
		NSTextStorage *resultStorage = [resultView textStorage];
		NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:notFoundString
																	  attributes:[applicationManager resultAttributes]];
		[resultStorage appendAttributedString:attrStr];
		[attrStr release];
		[self addGuessForSearchWord:searchStr searchID:searchID];
	}
}

// �C�����̒ǉ�
- (void)addGuessForSearchWord:(NSString *)searchStr searchID:(unsigned long)searchID {
	if (![searchStr isEnglishWord]) {
		return;
	}
	NSTextStorage *resultStorage = [resultView textStorage];
	NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];
	NSArray *guesses = [spellChecker guessesForWord:searchStr];
	unsigned int count = [guesses count];
	if (count > 0) {
		if (currentSearchID != searchID) {
			return;
		}
		NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:
							   NSLocalizedString(@"GUESS_TITLE", @"") attributes:[applicationManager resultAttributes]];
		[resultStorage appendAttributedString:attrStr];
		[attrStr release];
		for (int i = 0; i < count; i++) {
			if (currentSearchID != searchID) {
				return;
			}
			NSString *guess = [guesses objectAtIndex:i];
			attrStr = [[NSAttributedString alloc] initWithString:
				[NSString stringWithFormat:@"\t%d. ", i+1]
													  attributes:[applicationManager resultAttributes]];
			[resultStorage appendAttributedString:attrStr];
			[attrStr release];
			NSMutableDictionary *linkAttrDict =
				[NSMutableDictionary dictionaryWithDictionary:[applicationManager resultAttributes]];
			[linkAttrDict setObject:guess forKey:NSLinkAttributeName];
			attrStr = [[NSAttributedString alloc] initWithString:guess
													  attributes:linkAttrDict];
			[resultStorage appendAttributedString:attrStr];
			[attrStr release];
			attrStr = [[NSAttributedString alloc] initWithString:@"\n"
													  attributes:[applicationManager resultAttributes]];
			[resultStorage appendAttributedString:attrStr];
			[attrStr release];
		}
		[firstGuess release];
		firstGuess = nil;
		[secondGuess release];
		secondGuess = nil;
		firstGuess = [[guesses objectAtIndex:0] retain];
		if (count > 1) {
			secondGuess = [[guesses objectAtIndex:1] retain];
		}
		[[resultView window] resetCursorRects];
	} else {
		NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:
							NSLocalizedString(@"GUESS_NOTFOUND", @"") attributes:[applicationManager resultAttributes]];
		[resultStorage appendAttributedString:attrStr];
		[attrStr release];
	}
}

// �����Ԃ̃Z�p���[�^�̒ǉ�
- (void)addSeparator:(NSNumber *)searchIDObj {
	if ([searchIDObj unsignedLongValue] == currentSearchID) {
		NSTextStorage *resultStorage = [resultView textStorage];
		NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:@"========================\n" attributes:[applicationManager resultAttributes]];
		[resultStorage appendAttributedString:attrStr];
		[attrStr release];
	}
}

// �X�N���[���ʒu�����̂��߂̃^�C�~���O�҂����\�b�h
- (void)prepareScrolling:(NSNumber *)searchIDObj {
	// �������Ȃ�
}

// �S�������őΏۂ�������Ȃ������ꍇ�̃��b�Z�[�W��ǉ�
- (void)addFullSearchNotFound:(NSNumber *)searchIDObj {
	if ([searchIDObj unsignedLongValue] == currentSearchID) {
		NSTextStorage *resultStorage = [resultView textStorage];
		NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:
	NSLocalizedString(@"FULLSEARCH_NOTFOUND", @"FULLSEARCH_NOTFOUND") attributes:[applicationManager resultAttributes]];
		[resultStorage appendAttributedString:attrStr];
		[attrStr release];
	}
}

// �L�����Z��������̒ǉ�
- (void)addFullSearchCanceledSeparator {
	NSTextStorage *resultStorage = [resultView textStorage];
	NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:
		NSLocalizedString(@"CANCELED_SEPARATOR", @"CANCELED_SEPARATOR") attributes:[applicationManager resultAttributes]];
	[resultStorage appendAttributedString:attrStr];
	[attrStr release];
}

// �X�N���[���ʒu�̕���
- (void)scrollToLastRect:(NSArray *)searchInfo {
	NSNumber *searchIDObj = [searchInfo objectAtIndex:0];
	unsigned long searchID = [searchIDObj unsignedLongValue];
	if (currentSearchID == searchID) {
		NSString *searchStr = [searchInfo objectAtIndex:1];
		[applicationManager scrollToLastRectForString:searchStr];
	}
}

// �i�s�󋵂̃Z�b�g
- (void)setProgress:(NSArray *)progInfo {
	unsigned long searchID = [[progInfo objectAtIndex:0] unsignedLongValue];
	if (currentSearchID == searchID) {
		double progress = [[progInfo objectAtIndex:1] doubleValue];
		[searchField setDoubleValue:progress];
	}
}

// �w�肳�ꂽ�����������
- (void)searchString:(NSString *)searchStr {
	// �V��������ID���쐬
	currentSearchID = [self createSearchID];
	NSNumber *searchIDObj = [NSNumber numberWithUnsignedLong:currentSearchID];
	// �󕶎���ł���Ό������ʂ��N���A���ďI��
	if (!searchStr || [searchStr length] == 0) {
		[self clearResult:searchIDObj];
		return;
	}
	// �����X���b�h���쐬
	NSArray *threadInfo = [[NSArray alloc] initWithObjects:
		searchStr, searchIDObj, nil];
	[NSThread detachNewThreadSelector:@selector(mainSearchProc:)
							 toTarget:self
						   withObject:threadInfo];
	[threadInfo release];
}

// �����X���b�h�p�̃��\�b�h
- (void)mainSearchProc:(NSArray *)threadInfo {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString *searchStr = [threadInfo objectAtIndex:0];
	NSNumber *searchIDObj = [threadInfo objectAtIndex:1];
	unsigned long searchID = [searchIDObj unsignedLongValue];

	// ���ʃr���[���N���A
	[self performSelectorOnMainThread:@selector(clearResult:)
						   withObject:searchIDObj
						waitUntilDone:YES];
	
	// �ʂ̌������n�܂��Ă���
	if (searchID != currentSearchID) {
		return;
	}
	
	// Shift-JIS�̔�r�p�̃f�[�^���쐬
	NSData *searchStrData = [searchStr dataUsingEncoding:NSShiftJISStringEncoding];
	unsigned int searchStrDataLength = [searchStrData length];
	unsigned int cSearchStrLength = searchStrDataLength + 2;
	unsigned char *cSearchStr = malloc(cSearchStrLength);
	[searchStrData getBytes:cSearchStr+2 length:searchStrDataLength];
	cSearchStr[0] = 0x81;
	cSearchStr[1] = 0xa1;

	// ���ݒ���擾
	id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
	BOOL removeRubies = [[values valueForKey:@"removeRubies"] boolValue];

	// �J�n
	int searchCount = 0;
	if (isEnglishWordC(cSearchStr+2, searchStrDataLength)) {
		// ����Y������
		if (isCapitalWordC(cSearchStr+2, searchStrDataLength)) {
			NSString *ryakugoroPath = [values valueForKey:@"ryakugoroPath"];
			NSData *ryakugoroData = [NSData dataWithContentsOfMappedFile:ryakugoroPath];
			searchCount += [self searchForCString:cSearchStr
								 cSearchStrLength:cSearchStrLength
										   inData:ryakugoroData
									 removeRubies:removeRubies
									  searchIDObj:searchIDObj];
			// �ʂ̌������n�܂��Ă���
			if (searchID != currentSearchID) {
				free(cSearchStr);
				return;
			}			
		}
		// �p���Y������
		NSString *eijiroPath = [values valueForKey:@"eijiroPath"];
		NSData *eijiroData = [NSData dataWithContentsOfMappedFile:eijiroPath];
		searchCount += [self searchForCString:cSearchStr
							 cSearchStrLength:cSearchStrLength
									   inData:eijiroData
								 removeRubies:removeRubies
								  searchIDObj:searchIDObj];
	} else {
		// ���{��ɂ͘a�p���Y�݂̂�����
		NSString *waeijiroPath = [values valueForKey:@"waeijiroPath"];
		NSData *waeijiroData = [NSData dataWithContentsOfMappedFile:waeijiroPath];
		searchCount += [self searchForCString:cSearchStr
							 cSearchStrLength:cSearchStrLength
									   inData:waeijiroData
								 removeRubies:removeRubies
								  searchIDObj:searchIDObj];
	}
	// �N���[���A�b�v
	free(cSearchStr);
	// ������Ȃ�����
	if (searchCount == 0) {
		[self performSelectorOnMainThread:@selector(addNotFound:)
							   withObject:[NSArray arrayWithObjects:searchIDObj, searchStr, nil]
							waitUntilDone:NO];
	}
	// ���C���X���b�h�Ō������ʂ����ׂăr���[�ɒǉ������̂�҂�
	[self performSelectorOnMainThread:@selector(prepareScrolling:)
						   withObject:searchIDObj
						waitUntilDone:YES];
	// �ȑO�̃X�N���[���ʒu�𕜌�����
	[self performSelectorOnMainThread:@selector(scrollToLastRect:)
						   withObject:[NSArray arrayWithObjects:searchIDObj, searchStr, nil]
						waitUntilDone:NO];
	
	[pool release];
}

// �o�C�i���T�[�`�̎���
- (int)searchForCString:(unsigned char *)cSearchStr
	   cSearchStrLength:(unsigned int)cSearchStrLength
				 inData:(NSData *)data
		   removeRubies:(BOOL)removeRubies
			searchIDObj:(NSNumber *)searchIDObj
{
	unsigned char *p = (unsigned char *) [data bytes];
	int dataLength = [data length];
	
	int startPos = 0;
	int endPos = dataLength - 1;
	int middlePos = 0;
	
	unsigned long searchID = [searchIDObj unsignedLongValue];

	while (startPos < endPos) {
		// ���̌������n�܂��Ă���
		if (searchID != currentSearchID) {
			return 0;
		}
		// �������v�Z����
		middlePos = startPos + (endPos - startPos) / 2;
		// ���s�������邩�J�n�_�ɒH�蒅���܂ŋt�߂�
		while (middlePos > startPos &&
			   (p[middlePos-1] != 0x0a && p[middlePos-1] != 0x0d ||
				p[middlePos] == 0x0a || p[middlePos] == 0x0d)) {
			middlePos--;
		}
		// ��r����
		int comparisonResult = mystrncmp(p+middlePos, cSearchStr, cSearchStrLength, YES);
		if (comparisonResult == 0) {
			// ���������񂪌��������B
			// middlePos���擪�̃C���f�N�X��ێ����Ă���B
			break;
		} else if (comparisonResult < 0) {
			// ���݂̃C���f�N�X�������̕����ɂ�������������͑��݂��Ȃ�
			startPos = middlePos;
			// ���̍s�̍Ō�܂ŃC���f�N�X�𑗂�
			while (startPos < endPos && p[startPos] != 0x0a && p[startPos] != 0x0d) {
				if (isFirst2BytesCharacter(p[startPos])) {
					startPos++;
				}
				startPos++;
			}
			while (p[startPos] == 0x0a || p[startPos] == 0x0d) {
				startPos++;
			}
		} else {
			// ���݂̃C���f�N�X�����O�̕����ɂ�������������͑��݂��Ȃ�
			endPos = middlePos - 1;
		}
	}
	
	// ������Ȃ�����
	if (startPos >= endPos) {
		return 0;
	}
	
	// �������x���̕������������Ɍ������AstartPos�����̃��x���̕�����
	// �ŏ��Ɍ����s�̐擪�̃C���f�N�X�l�Ƃ���B
	startPos = middlePos - 1;
	while (startPos > 0) {
		// ���̌������n�܂��Ă���
		if (searchID != currentSearchID) {
			return 0;
		}
		// ���s�������邩�f�[�^�̃[���n�_�ɒH�蒅���܂ŋt�߂�
		while (startPos > 0 &&
			   (p[startPos-1] != 0x0a && p[startPos-1] != 0x0d ||
				p[startPos] == 0x0a || p[startPos] == 0x0d))
		{
			startPos--;
		}
		// ��r����
		int comparisonResult = mystrncmp(p+startPos, cSearchStr, cSearchStrLength, YES);
		if (comparisonResult == 0) {
			middlePos = startPos;
			startPos = middlePos - 1;
		} else {
			break;
		}
	}
	startPos = middlePos;
	endPos = startPos + 1;
	
	// �f�[�^��ǉ����Ă���
	int addCount = 0;
	NSMutableString *addBuffer = [NSMutableString string];
	while (endPos < dataLength-1) {
		// ���̌������n�܂��Ă���
		if (searchID != currentSearchID) {
			return addCount;
		}
		// �s����������
		while (endPos < dataLength-1 && p[endPos] != 0x0a && p[endPos] != 0x0d) {
			endPos++;
		}
		// ���ʂ�ǉ�
		NSData *resultData = [data subdataWithRange:NSMakeRange(middlePos, endPos-middlePos+1)];
		NSString *addStr = [[[NSString alloc] initWithData:resultData encoding:NSShiftJISStringEncoding] autorelease];
		if (removeRubies) {
			addStr = [addStr stringByRemovingRubies];
		}
		addStr = [addStr pronunciationSymbolFixedString];
		addStr = [addStr ver80FixedString];
		[addBuffer appendString:addStr];
		addCount++;
		if (addCount % 6 == 0) {
			[self performSelectorOnMainThread:@selector(addResultLine:)
								   withObject:[NSArray arrayWithObjects:searchIDObj, addBuffer, nil]
								waitUntilDone:NO];
			addBuffer = [NSMutableString string];
		}
		// �ő匟�����𒴂�����I��
		if (addCount > 60) {
			break;
		}
		// ����
		while (endPos < dataLength-1 && (p[endPos] == 0x0a || p[endPos] == 0x0d)) {
			endPos++;
		}
		// ���̌������n�܂��Ă���
		if (searchID != currentSearchID) {
			return addCount;
		}
		int comparisonResult = mystrncmp(p+endPos, cSearchStr, cSearchStrLength, YES);
		if (comparisonResult != 0) {
			break;
		}
		middlePos = endPos;
		endPos++;
	}
	// ���̌������n�܂��Ă���
	if (searchID != currentSearchID) {
		return addCount;
	}
	// �Ō�̃o�b�t�@��f���o��
	if ([addBuffer length] > 0) {
		[self performSelectorOnMainThread:@selector(addResultLine:)
							   withObject:[NSArray arrayWithObjects:searchIDObj, addBuffer, nil]
							waitUntilDone:NO];
	}
	// �Z�p���[�^�̒ǉ�
	if (addCount > 0) {
		[self performSelectorOnMainThread:@selector(addSeparator:)
							   withObject:searchIDObj
							waitUntilDone:NO];
	}
	return addCount;
}	

// �����̒��f
- (void)stopSearching {
	currentSearchID = [self createSearchID];
	NSNumber *searchIDObj = [NSNumber numberWithUnsignedLong:currentSearchID];
	NSArray *progInfo = [[NSArray alloc] initWithObjects:
		searchIDObj, [NSNumber numberWithDouble:0], nil];
	[self performSelectorOnMainThread:@selector(setProgress:)
						   withObject:progInfo
						waitUntilDone:NO];
	[progInfo release];
	[self performSelectorOnMainThread:@selector(addFullSearchCanceledSeparator)
						   withObject:nil
						waitUntilDone:NO];		
}

// ��1�C���������^�[������
- (NSString *)firstGuess {
	return firstGuess;
}

// ��2�C���������^�[������
- (NSString *)secondGuess {
	return secondGuess;
}

@end
