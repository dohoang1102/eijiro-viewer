//
//  StringUtil.m
//  EIJIRO Viewer
//
//  Created by numata on October 21, 2002.
//  Copyright 2002-2004 Satoshi NUMATA. All rights reserved.
//

#import "StringUtil.h"


// Shift-JIS �ɂ�����2�o�C�g�����̐擪�����ł��邩�ǂ����𔻒肷��B
inline BOOL isFirst2BytesCharacter(unsigned char c) {
	return (c >= 0x80 && c <= 0x9f || c >= 0xe0 && c <= 0xfc);
}

// 2�o�C�g�������܂ޕ����񂩂ǂ����𔻒肷��B
inline BOOL isEnglishWordC(const unsigned char *str, unsigned int length) {
	for (unsigned int i = 0; i < length; i++) {
		if (isFirst2BytesCharacter(str[i])) {
			return NO;
		}
	}
	return YES;
}

// �啶���ō\������镶���񂩂ǂ����𔻒肷��B
inline BOOL isCapitalWordC(const unsigned char *str, unsigned int length) {
	for (unsigned int i = 0; i < length; i++) {
		if (islower(str[i])) {
			return NO;
		}
	}
	return YES;
}

// �^����ꂽ�T�C�Y�ŁA�啶���������𖳎����ĕ�����̔�r���s���B
int mystrncmp(const unsigned char *str1, const unsigned char *str2, unsigned int size, BOOL hasEijiroPrefix) {
	// �p���Y�̃f�[�^�ɂ͈ꕔ�s���������Ă�����̂�����̂ŁA���̑Ώ�
	// �i���ۂɂ́AStuffIt Expander�ŏ��Дł̃f�[�^���𓀂���Ƃ��̖�肪�N����j�B
	// �u���v��1�o�C�g�ڂ�K���ǂݔ�΂��Ĕ�r���s���悤�ɂ���B
	if (hasEijiroPrefix) {
		if (*str1 == 0x81) {
			str1++;
		}
		if (*str2 == 0x81) {
			str2++;
		}
		size -= 1;
	}
	
	// ��r�̃��C��
	for (unsigned int i = 0; i < size; i++) {
		unsigned char c1 = str1[i];
		unsigned char c2 = str2[i];
		// '{' �� ',' �͒P��̋�؂�ƊŘ􂷁B
		// "1,234" �Ȃǂ����܂������ł��Ȃ����A�Ƃ肠���������Ă������B
		if (c1 == '{' || c1 == ',') {
			return -1;
		}
		// �����R�[�h���ɕ���ł��Ȃ������̑Ώ��B
		// '[', '\', '_' �̏��� 'z' �������Ɍ����B
		// ����� '{', '|', '}' �Ƃ��Ĉ������ƂŁA�Ƃ肠������������ł��邾�낤�B
		if (c1 == '[') {
			c1 = '{';
		} else if (c1 == '\\') {
			c1 = '|';
		} else if (c1 == '_') {
			c1 = '}';
		}
		if (c2 == '[') {
			c2 = '{';
		} else if (c2 == '\\') {
			c2 = '|';
		} else if (c2 == '_') {
			c2 = '}';
		}
		// A�`Z �̕����� a�`z �ɕϊ����Ă���
		if (c1 >= 'A' && c1 <= 'Z') {
			c1 = tolower(c1);
		}
		if (c2 >= 'A' && c2 <= 'Z') {
			c2 = tolower(c2);
		}
		// ��r����
		if (c1 != c2) {
			return c1 - c2;
		}
		// 2�o�C�g�����̐擪�����ł���΂���1����ϊ��Ȃ��ɔ�r����
		if (i < size && isFirst2BytesCharacter(c1)) {
			i++;
			c1 = str1[i];
			c2 = str2[i];
			if (c1 != c2) {
				return c1 - c2;
			}
		}
	}
	return 0;
}

// ������̒��ɕ����񂪊܂܂�Ă��邩�ǂ����𒲂ׂ�
BOOL strContainsStr(const unsigned char *strTarget, unsigned int targetSize,
	const unsigned char *strSearch, unsigned int searchSize)
{
	unsigned char firstChar = strSearch[0];
	if (targetSize < searchSize) {
		return NO;
	}
	if (firstChar >= 'A' && firstChar <= 'Z') {
		firstChar = tolower(firstChar);
	}
	for (unsigned int i = 0; i < targetSize - searchSize + 1; i++) {
		unsigned char c = strTarget[i];
		if (c >= 'A' && c <= 'Z') {
			c = tolower(c);
		}
		if (c == firstChar) {
			if (mystrncmp(strTarget + i, strSearch, searchSize, NO) == 0) {
				return YES;
			}
		}
		if (isFirst2BytesCharacter(strTarget[i])) {
			i++;
		}
	}
	return NO;
}


//
//  �p���Y�֌W�̕����񏈗����T�|�[�g���邽�߂̃J�e�S��
//

@implementation NSString (EijiroSupport)

static NSString *pronunciationPrefix;

// ������
+ (void)initialize {
	unichar c[3] = { 0x3010, 0x767a, 0x97f3 };
	pronunciationPrefix = [[NSString alloc] initWithCharacters:c length:3];
}

// 2�o�C�g�������܂ޕ����񂩂ǂ����𔻒肷��B
- (BOOL)isEnglishWord {
	NSData *data = [self dataUsingEncoding:NSShiftJISStringEncoding];
	unsigned char *p = (unsigned char *) [data bytes];
	unsigned int length = [data length];
	for (unsigned int i = 0; i < length; i++) {
		if (isFirst2BytesCharacter(p[i])) {
			return NO;
		}
	}
	return YES;
}

// ���r��������������������^�[������
- (NSString *)stringByRemovingRubies {
	unsigned int length = [self length];
	unichar *buffer = malloc(sizeof(unichar) * length);
	BOOL ignoring = NO;
	unsigned int pos = 0;
	for (unsigned int i = 0; i < length; i++) {
		unichar c = [self characterAtIndex:i];
		if (c == 0xff5b) {	// �S�p�́u�o�v
			ignoring = YES;
		}
		if (!ignoring) {
			buffer[pos++] = c;
		}
		if (c == 0xff5d) {	// �S�p�́u�p�v
			ignoring = NO;
		}
	}
	
	NSString *result = [NSString stringWithCharacters:buffer length:pos];
	free(buffer);
	return result;
}

// �p���Y�̃f�[�^Ver.80�ŕύX���ꂽ�p��\�L��ϊ���������������^�[������
- (NSString *)ver80FixedString {
	NSMutableString *ret = nil;
	NSString *prefixStr = NSLocalizedString(@"VER80_EXAMPLE_PREFIX", @"VER80_EXAMPLE_PREFIX");
	BOOL isFirst = YES;
	unsigned int length = [self length];
	NSRange searchingRange = NSMakeRange(0, length);
	while (YES) {
		NSRange prefixRange = [self rangeOfString:prefixStr options:0 range:searchingRange];
		if (prefixRange.location == NSNotFound) {
			if (searchingRange.location == 0) {
				return self;
			} else {
				[ret appendString:[self substringWithRange:searchingRange]];
			}
			break;
		}
		if (!ret) {
			ret = [NSMutableString stringWithString:[self substringWithRange:
				NSMakeRange(searchingRange.location, prefixRange.location-searchingRange.location)]];
		} else {
			[ret appendString:[self substringWithRange:
				NSMakeRange(searchingRange.location, prefixRange.location-searchingRange.location)]];
		}
		if (isFirst) {
			[ret appendString:NSLocalizedString(@"EXAMPLE_FIRST_PREFIX", @"EXAMPLE_FIRST_PREFIX")];
			isFirst = NO;
		} else {
			[ret appendString:@" / "];
		}
		searchingRange.location = prefixRange.location + 2;
		searchingRange.length = length - prefixRange.location - 2;
	}
	return ret;
}

// �����L����␳��������������^�[������
- (NSString *)pronunciationSymbolFixedString {
	// �����L���̃v���t�B�N�X��T��
	NSRange pronPrefixRange = [self rangeOfString:pronunciationPrefix];
	if (pronPrefixRange.location == NSNotFound) {
		return self;
	}
	// �v���t�B�N�X�܂ł̕�����ǉ�
	NSMutableString *ret = [NSMutableString stringWithString:
		[self substringToIndex:pronPrefixRange.location+4]];
	// �����L����ϊ�
	unsigned int length = [self length];
	unichar *buffer = malloc(sizeof(unichar) * (length - pronPrefixRange.location - 4));
	unsigned int pos = 0;
	unsigned int i;
	for (i = pronPrefixRange.location+4; i < length; i++) {
		unichar c1 = [self characterAtIndex:i];
		// �����L���̏I���i�u�A�v�j
		if (c1 == 0x3001) {
			break;
		}
		// ���̑�
		else {
			unichar c = c1;
			BOOL pass = NO;
			switch (c1) {
				case 0x0027:	// '
					c = 0x0301;
					break;
				case 0x003a:	// :
					c = 0x02d0;
					break;
				case 0x0060:	// `
					c = 0x0300;
					break;
				case 0x0061: // �P�̕t����a
							 // ae
					if (i+1 < length && [self characterAtIndex:i+1] == 0x65) {
						c = 0x00e6;
						i++;
					}
					break;
				case 0x044d:	// e�̂Ђ�����Ԃ���a
					c = 0x0259;
					break;
				case 0x039b:	// �^�[��A
					c = 0x028c;
					break;
				case 0x03b1:	// a
					c = 0x0251;
					break;
				case 0x03b4:	// th�i�����j
					c = 0x00f0;
					break;
				case 0x03b7:	// ng
					c = 0x014b;
					break;
				case 0x03b8:	// th
					c = 0x03b8;
					break;
				case 0x0437:	// zg
					c = 0x0292;
					break;
				case 0x20dd:	// sh
					c = 0x0283;
					break;
				case 0x5c0f:	// �Ԃɋ��܂��Ă��鐳�̕s���̕����i�n�C�t���H�j
					pass = YES;
					break;
				case 0xff4f:	// c���Ђ�����Ԃ���o
					c = 0x0254;
					break;
			}
			// �ϊ��������ʂ�ǉ�
			if (!pass) {
				buffer[pos++] = c;
			}
		}
	}
	if (pos > 0) {
		[ret appendString:[NSString stringWithCharacters:buffer length:pos]];
	}
	free(buffer);
	// �c��̕�����f���o��
	if (i < length) {
		[ret appendString:[self substringFromIndex:i]];
	}
	// ���^�[��
	return ret;
}

// �ŏ��ɂ��閳�Ӗ��ȕ�����������������������^�[������
- (NSString *)stringByTrimmingFirstInvalidCharacters {
	unsigned int startIndex = 0;
	while (startIndex < [self length]) {
		unichar c = [self characterAtIndex:startIndex];
		if (c != ' ' && c != '\t' && c != '\r' && c != '\n' && c != 0x3000 &&
			c != ',' && c != '.' && c != ';' && c != ':' && c != '!' && c != '?' &&
			c != '(' && c != ')' && c != '<' && c != '>' && c != '{' && c != '}' &&
			c != '\'' && c != '\"')
		{
			break;
		}
		startIndex++;
	}
	if (startIndex < [self length]) {
		return [self substringFromIndex:startIndex];
	}
	return self;
}

// �Ō�ɂ��閳�Ӗ��ȕ�����������������������^�[������
- (NSString *)stringByTrimmingLastInvalidCharacters {
	unsigned int lastIndex = [self length] - 1;
	while (lastIndex >= 0) {
		unichar c = [self characterAtIndex:lastIndex];
		if (c != ' ' && c != '\t' && c != '\r' && c != '\n' && c != 0x3000 &&
			c != ',' && c != '.' && c != ';' && c != ':' && c != '!' && c != '?' &&
			c != '(' && c != ')' && c != '<' && c != '>' && c != '{' && c != '}' &&
			c != '\'' && c != '\"')
		{
			break;
		}
		lastIndex--;
	}
	if (lastIndex >= 0) {
		return [self substringToIndex:lastIndex+1];
	}
	return self;
}

@end
