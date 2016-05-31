#define _REENTRANT
#define _GNU_SOURCE
#define DEBIAN
#define _LARGEFILE_SOURCE
#define _FILE_OFFSET_BITS 64
#define VERSION "0.01"
#define XS_VERSION "0.01"

#include "/usr/lib/x86_64-linux-gnu/perl/5.20/CORE/EXTERN.h"
#include "/usr/lib/x86_64-linux-gnu/perl/5.20/CORE/perl.h"
#include "/usr/lib/x86_64-linux-gnu/perl/5.20/CORE/XSUB.h"

/////////////////////////////////////////////////////////////////////////////

#define INTERPRETER_MACRO(_) \
	_(SV **, PL_stack_base) \
	_(SV **, PL_stack_sp)

#define INTERPRETER_MACRO_DEF(t, n) \
	t swp_##n(void) __attribute__((swift_name("getter:"#n"()"))); \
	void swp_##n##_set(t) __attribute__((swift_name("setter:"#n"(_:)")));
INTERPRETER_MACRO(INTERPRETER_MACRO_DEF)

#define SV_VOID_MACRO(_) \
	_(SvREFCNT_inc) \
	_(SvREFCNT_dec) \
	_(sv_2mortal)

#define SV_VOID_MACRO_DEF(n) void (n)(SV *sv);
SV_VOID_MACRO(SV_VOID_MACRO_DEF)

#define SV_SIMPLE_MACRO(_) \
	_(svtype, SvTYPE) \
	_(bool, SvOK) \
	_(bool, SvIOK) \
	_(bool, SvIOK_UV) \
	_(bool, SvROK) \
	_(bool, SvPOK) \
	_(bool, SvTRUE) \
	_(IV, SvIV) \
	_(UV, SvUV) \
	_(SV *, SvRV) \
	_(U32, SvREFCNT)

#define SV_SIMPLE_MACRO_DEF(t, n) t (n)(SV *sv);
SV_SIMPLE_MACRO(SV_SIMPLE_MACRO_DEF)

__attribute__((swift_name("getter:ERRSV()"))) SV *swp_ERRSV(void) { return ERRSV; }

__attribute__((swift_name("PUSHMARK(_:)"))) void swp_PUSHMARK(SV **sp) { PUSHMARK(sp); }
__attribute__((swift_name("POPMARK()"))) I32 swp_POPMARK(void) { return POPMARK; }
__attribute__((swift_name("getter:TOPMARK()"))) I32 swp_TOPMARK(void) { return TOPMARK; }

__attribute__((swift_name("EXTEND(_:_:)"))) void swp_EXTEND(SV **sp, SSize_t nitems) { EXTEND(sp, nitems); }

SV *(newSV)(const STRLEN len);
SV *(newSVbv)(const bool bv);
SV *(newSViv)(const IV iv);
SV *(newSVuv)(const UV uv);
SV *(newSVpvn_utf8)(const char *s, STRLEN len, bool utf8);

void (sv_setpvn)(SV *const sv, const char *const ptr, const STRLEN len);
SV *(sv_setref_iv)(SV *const rv, const char *const classname, const IV iv);

bool (sv_isobject)(SV *sv);
const char *(sv_reftype)(const SV *const sv, const bool ob);

char *(SvPV)(SV *sv, STRLEN *len);

SV *(newRV_inc)(SV *sv);

AV *(newAV)(void);
SSize_t (av_top_index)(AV *av);
void (av_extend)(AV *av, SSize_t key);
void (av_push)(AV *av, SV *val);
SV *(av_shift)(AV *av);
SV **(av_store)(AV *av, SSize_t key, SV *val);
SV **(av_fetch)(AV *av, SSize_t key, I32 lval);

HV *(newHV)(void);
I32 (HvUSEDKEYS)(HV *hv);

SV **(hv_store)(HV *hv, const char *key, U32 keylen, SV *val, U32 hash);
SV **(hv_fetch)(HV *hv, const char *key, U32 keylen, I32 lval);
SV **(hv_delete)(HV *hv, const char *key, U32 keylen, I32 flags);

I32 (hv_iterinit)(HV *hv);
HE *(hv_iternext)(HV *hv);

char *(HePV)(HE *he, STRLEN *len);
SV *(HeVAL)(HE *he);

void swp_ENTER(void) __attribute__((swift_name("ENTER()")));
void swp_LEAVE(void) __attribute__((swift_name("LEAVE()")));

void swp_SAVETMPS(void) __attribute__((swift_name("SAVETMPS()")));
void swp_FREETMPS(void) __attribute__((swift_name("FREETMPS()")));

void (load_module_noargs)(U32 flags, SV* name, SV* ver) { return load_module(flags, name, ver, NULL); }
CV *(newXS_flags)(const char *name, XSUBADDR_t subaddr, const char *const filename, const char *const proto, U32 flags);

I32 (call_pv)(const char *sub_name, I32 flags);
I32 (call_method)(const char *methname, I32 flags);

void (croak_sv)(SV *baseex);
