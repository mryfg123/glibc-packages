#ifndef _ANDROID_IDS
#define _ANDROID_IDS

#include "android_system_user_ids.h"

#define AID_USER_OFFSET 100000
#define AID_OVERFLOWUID 65534
#define AID_ISOLATED_START 99000
#define AID_ISOLATED_END 99999
#define AID_APP_START 10000
#define AID_APP_END 19999
#define AID_CACHE_GID_START 20000
#define AID_CACHE_GID_END 29999
#define AID_EXT_GID_START 30000
#define AID_EXT_GID_END 39999
#define AID_EXT_CACHE_GID_START 40000
#define AID_EXT_CACHE_GID_END 49999
#define AID_SHARED_GID_START 50000
#define AID_SHARED_GID_END 59999

#define AID_OEM_RESERVED_START 2900
#define AID_OEM_RESERVED_END 2999
#define AID_OEM_RESERVED_2_START 5000
#define AID_OEM_RESERVED_2_END 5999

struct IdRange {
    id_t start;
    id_t end;
};

static struct IdRange user_ranges[] = {
    { AID_APP_START, AID_APP_END },
    { AID_ISOLATED_START, AID_ISOLATED_END },
};

static struct IdRange group_ranges[] = {
    { AID_APP_START, AID_APP_END },
    { AID_CACHE_GID_START, AID_CACHE_GID_END },
    { AID_EXT_GID_START, AID_EXT_GID_END },
    { AID_EXT_CACHE_GID_START, AID_EXT_CACHE_GID_END },
    { AID_SHARED_GID_START, AID_SHARED_GID_END },
    { AID_ISOLATED_START, AID_ISOLATED_END },
};

struct android_id_info {
    const char *name;
    unsigned aid;
};

static struct android_id_info android_ids[] = {
    { "_ANDROID_IDS", _ANDROID_IDS, },
    { "_ANDROID_IDS", _ANDROID_IDS, },
    { "", , },
    { ""android_system_user_ids.h"", "android_system_user_ids.h", },
    { "", , },
    { "user_offset", AID_USER_OFFSET, },
    { "overflowuid", AID_OVERFLOWUID, },
    { "isolated_start", AID_ISOLATED_START, },
    { "isolated_end", AID_ISOLATED_END, },
    { "app_start", AID_APP_START, },
    { "app_end", AID_APP_END, },
    { "cache_gid_start", AID_CACHE_GID_START, },
    { "cache_gid_end", AID_CACHE_GID_END, },
    { "ext_gid_start", AID_EXT_GID_START, },
    { "ext_gid_end", AID_EXT_GID_END, },
    { "ext_cache_gid_start", AID_EXT_CACHE_GID_START, },
    { "ext_cache_gid_end", AID_EXT_CACHE_GID_END, },
    { "shared_gid_start", AID_SHARED_GID_START, },
    { "shared_gid_end", AID_SHARED_GID_END, },
    { "", , },
    { "oem_reserved_start", AID_OEM_RESERVED_START, },
    { "oem_reserved_end", AID_OEM_RESERVED_END, },
    { "oem_reserved_2_start", AID_OEM_RESERVED_2_START, },
    { "oem_reserved_2_end", AID_OEM_RESERVED_2_END, },
    { "", , },
    { "IdRange", IdRange, },
    { "start;", start;, },
    { "end;", end;, },
    { "", , },
    { "", , },
    { "struct", struct, },
    { "app_start,", AID_APP_START,, },
    { "isolated_start,", AID_ISOLATED_START,, },
    { "", , },
    { "", , },
    { "struct", struct, },
    { "app_start,", AID_APP_START,, },
    { "cache_gid_start,", AID_CACHE_GID_START,, },
    { "ext_gid_start,", AID_EXT_GID_START,, },
    { "ext_cache_gid_start,", AID_EXT_CACHE_GID_START,, },
    { "shared_gid_start,", AID_SHARED_GID_START,, },
    { "isolated_start,", AID_ISOLATED_START,, },
    { "", , },
    { "", , },
    { "android_id_info", android_id_info, },
    { "char", char, },
    { "aid;", aid;, },
    { "", , },
    { "", , },
    { "struct", struct, },
    { "", , },
    { "", , },
    { "android_id_count", android_id_count, },
    { "", , },
    { "default", default, },
    { "APP_HOME_DIR", APP_HOME_DIR, },
    { "APP_PREFIX_DIR", APP_PREFIX_DIR, },
    { "", , },
    { "//", //, },
};

#define android_id_count (sizeof(android_ids) / sizeof(android_ids[0]))

// default paths for the application
#define APP_HOME_DIR "/data/data/com.termux/files/home/glibc-2.43/nss/android_ids.h/home"
#define APP_PREFIX_DIR "/data/data/com.termux/files/home/glibc-2.43/nss/android_ids.h/usr"

#endif // _ANDROID_IDS
