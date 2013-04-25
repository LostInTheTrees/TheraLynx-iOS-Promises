//
//  definesOpen.h
//  PT1
//
//  Created by Bob Carlson on 4/24/13.
//  Copyright (c) 2013 TheraLynx LLC. All rights reserved.
//

#ifndef PT1_definesOpen_h
#define PT1_defines_Open_h

#define __CLASS NSStringFromClass([self class])
#define __SELECTOR NSStringFromSelector(_cmd)

#define QLOG(fmt) [QLog log] logWithFormat:[@"%@ -%@ " stringByAppendingString: fmt], __CLASS, __SELECTOR
#define QLOGENTRY [QLOG(@"")]
#define QLOGAPPEND(fmt) [QLog log] logAppendWithFormat: fmt

#ifdef UNITTEST
    #define QNSLOG(fmt, ...) NSLog([@"%@ -%@ " stringByAppendingString: fmt], __CLASS, __SELECTOR, ##__VA_ARGS__)
#else
    #define QNSLOG(fmt, ...) [[QLog log] logWithFormat:[@"%@ -%@ " stringByAppendingString: fmt], __CLASS, __SELECTOR, ##__VA_ARGS__]
#endif

#endif
