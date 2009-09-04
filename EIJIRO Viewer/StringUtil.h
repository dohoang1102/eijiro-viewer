//
//  StringUtil.h
//  EIJIRO Viewer
//
//  Created by numata on October 21, 2002.
//  Copyright 2002-2004 Satoshi NUMATA. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// Shift-JIS �ɂ�����2�o�C�g�����̐擪�����ł��邩�ǂ����𔻒肷��B
inline BOOL isFirst2BytesCharacter(unsigned char c);

// 2�o�C�g�������܂ޕ����񂩂ǂ����𔻒肷��B
BOOL isEnglishWordC(const unsigned char *str, unsigned int length);
BOOL isCapitalWordC(const unsigned char *str, unsigned int length);

// �^����ꂽ�T�C�Y�ŁA�啶���������𖳎����ĕ�����̔�r���s���B
int mystrncmp(const unsigned char *str1, const unsigned char *str2, unsigned int size, BOOL hasEijiroPrefix);

// ������̒��ɕ����񂪊܂܂�Ă��邩�ǂ����𒲂ׂ�
BOOL strContainsStr(const unsigned char *strTarget, unsigned int targetSize,
	const unsigned char *strSearch, unsigned int searchSize);


//
//  �p���Y�֌W�̕����񏈗����T�|�[�g���邽�߂̃J�e�S��
//

@interface NSString (EijiroSupport)

// 2�o�C�g�������܂ޕ����񂩂ǂ����𔻒肷��B
- (BOOL)isEnglishWord;

// ���r��������������������^�[������B
- (NSString *)stringByRemovingRubies;

// Ver.80�`���́u���E�v����n�܂�p��̃v���t�B�N�X��ϊ���������������^�[������B
- (NSString *)ver80FixedString;

// �^�������L�����C����������������^�[������B
- (NSString *)pronunciationSymbolFixedString;

// �ŏ��ɂ��閳�Ӗ��ȕ�����������������������^�[������B
- (NSString *)stringByTrimmingFirstInvalidCharacters;

// �Ō�ɂ��閳�Ӗ��ȕ�����������������������^�[������B
- (NSString *)stringByTrimmingLastInvalidCharacters;

@end


