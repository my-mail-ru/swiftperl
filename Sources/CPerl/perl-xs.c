#include "perl-xs.h"

#define CPPWA(a, b) a##b

#define INTERPRETER_MACRO_IMPL(t, n) \
	t swp_##n(void) { return n; } \
	void swp_##n##_set(t value) { n = value; }
INTERPRETER_MACRO(INTERPRETER_MACRO_IMPL)

#define SV_VOID_MACRO_IMPL(n) void (n)(SV *sv) { n(sv); }
SV_VOID_MACRO(SV_VOID_MACRO_IMPL)

#define SV_SIMPLE_MACRO_IMPL(t, n) t (n)(SV *sv) { return n(sv); }
SV_SIMPLE_MACRO(SV_SIMPLE_MACRO_IMPL)

SV *(newSV)(const STRLEN len) { return newSV(len); }
SV *(newSVbv)(const bool bv) { return newSVsv(bv ? &PL_sv_yes : &PL_sv_no); }
SV *(newSViv)(const IV iv) { return newSViv(iv); }
SV *(newSVuv)(const UV uv) { return newSVuv(uv); }
SV *(newSVpvn_utf8)(const char *s, STRLEN len, bool utf8) { return newSVpvn_utf8(s, len, utf8); }

void (sv_setpvn)(SV *const sv, const char *const ptr, const STRLEN len) { sv_setpvn(sv, ptr, len); }
SV *(sv_setref_iv)(SV *const rv, const char *const classname, const IV iv) { return sv_setref_iv(rv, classname, iv); }

bool (sv_isobject)(SV *sv) { return sv_isobject(sv); }
const char *(sv_reftype)(const SV *const sv, const bool ob) { return sv_reftype(sv, ob); }

char *(SvPV)(SV *sv, STRLEN *len) { return SvPV(sv, *len); }

SV *(newRV_inc)(SV *sv) { return newRV_inc(sv); }

AV *(newAV)(void) { return newAV(); }
SSize_t (av_top_index)(AV *av) { return av_top_index(av); }
void (av_extend)(AV *av, SSize_t key) { return av_extend(av, key); }
void (av_push)(AV *av, SV *val) { av_push(av, val); }
SV *(av_shift)(AV *av) { return av_shift(av); }
SV **(av_store)(AV *av, SSize_t key, SV *val) { return av_store(av, key, val); }
SV **(av_fetch)(AV *av, SSize_t key, I32 lval) { return av_fetch(av, key, lval); }

HV *(newHV)(void) { return newHV(); }
I32 (HvUSEDKEYS)(HV *hv) { return HvUSEDKEYS(hv); }

SV **(hv_store)(HV *hv, const char *key, U32 keylen, SV *val, U32 hash) { return hv_store(hv, key, keylen, val, hash); }
SV **(hv_fetch)(HV *hv, const char *key, U32 keylen, I32 lval) { return hv_fetch(hv, key, keylen, lval); }
SV **(hv_delete)(HV *hv, const char *key, U32 keylen, I32 flags) { return hv_delete(hv, key, keylen, flags); }

I32 (hv_iterinit)(HV *hv) { return hv_iterinit(hv); }
HE *(hv_iternext)(HV *hv) { return hv_iternext(hv); }

char *(HePV)(HE *he, STRLEN *len) { return HePV(he, *len); }
SV *(HeVAL)(HE *he) { return HeVAL(he); }

void swp_ENTER(void) { ENTER; }
void swp_LEAVE(void) { LEAVE; }

void swp_SAVETMPS(void) { SAVETMPS; }
void swp_FREETMPS(void) { FREETMPS; }

CV *(newXS_flags)(const char *name, XSUBADDR_t subaddr, const char *const filename, const char *const proto, U32 flags) {
	return newXS_flags(name, subaddr, filename, proto, flags);
}

I32 (call_pv)(const char *sub_name, I32 flags) { return call_pv(sub_name, flags); }
I32 (call_method)(const char *methname, I32 flags) { return call_method(methname, flags); }

void (croak_sv)(SV *baseex) { croak_sv(baseex); }
