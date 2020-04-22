/*
 *
 *	  Copyright (c) 2017 Apple Computer, Inc.
 *	  All rights reserved.
 *
 *	  This document is the property of Apple Computer, Inc. It is
 *	  considered confidential and proprietary information.
 *
 *	  This document may not be reproduced or transmitted in any form,
 *	  in whole or in part, without the express written permission of
 *	  Apple Computer, Inc.
 */

#import <Foundation/Foundation.h>

#define FOREACH_DOMAIN(DOMAIN) \
	DOMAIN(PlatformDomain_Unknown)  \
	DOMAIN(PlatformDomain_macOS)    \
	DOMAIN(PlatformDomain_iOS)      \
	DOMAIN(PlatformDomain_tvOS)     \
	DOMAIN(PlatformDomain_watchOS)  \
	DOMAIN(PlatformDomain_bridgeOS) \

#define GENERATE_ENUM(ENUM) ENUM,


#if __cplusplus
extern "C" {
#endif


typedef NS_ENUM(int, PlatformDomain_t) {
    FOREACH_DOMAIN(GENERATE_ENUM)
};


PlatformDomain_t self_domain();
const char * domain_type_to_string(PlatformDomain_t type);
PlatformDomain_t domain_string_to_type(const char *domain);
    
    
#if __cplusplus
}
#endif
