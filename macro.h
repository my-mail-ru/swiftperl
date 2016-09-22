#include <stdbool.h>

#ifndef PERL_STATIC_INLINE
#   define PERL_STATIC_INLINE static inline
#endif

#define SWIFT_NAME(X) __attribute__((swift_name(#X)))

// Interpreter

SWIFT_NAME(getter:PerlInterpreter.current())
PERL_STATIC_INLINE _Nonnull PerlInterpreter *sPerl_PERL_GET_THX(void) {
	return PERL_GET_THX;
}

SWIFT_NAME(setter:PerlInterpreter.current(_:))
PERL_STATIC_INLINE void sPerl_PERL_SET_THX(_Nonnull PerlInterpreter *p) {
	PERL_SET_THX(p);
}

SWIFT_NAME(getter:PerlInterpreter.ERRSV(self:))
PERL_STATIC_INLINE _Nonnull SV *sPerl_ERRSV(pTHX) {
	return ERRSV;
}

SWIFT_NAME(PerlInterpreter.EXTEND(self:_:_:))
PERL_STATIC_INLINE SV **sPerl_EXTEND(pTHX_ SV **sp, SSize_t nitems) {
	EXTEND(sp, nitems);
	return sp;
}

SWIFT_NAME(PerlInterpreter.PUSHMARK(self:_:))
PERL_STATIC_INLINE void sPerl_PUSHMARK(pTHX_ SV **sp) {
	PUSHMARK(sp);
}

SWIFT_NAME(PerlInterpreter.POPMARK(self:))
PERL_STATIC_INLINE I32 sPerl_POPMARK(pTHX) {
	return POPMARK;
}

SWIFT_NAME(getter:PerlInterpreter.TOPMARK(self:))
PERL_STATIC_INLINE I32 sPerl_TOPMARK(pTHX) {
	return TOPMARK;
}

SWIFT_NAME(PerlInterpreter.SAVETMPS(self:))
PERL_STATIC_INLINE void sPerl_SAVETMPS(pTHX) {
	SAVETMPS;
}

SWIFT_NAME(PerlInterpreter.FREETMPS(self:))
PERL_STATIC_INLINE void sPerl_FREETMPS(pTHX) {
	FREETMPS;
}

// SvREFCNT

SWIFT_NAME(SvREFCNT(_:))
PERL_STATIC_INLINE U32 sPerl_SvREFCNT(SV *sv) {
	return SvREFCNT(sv);
}

SWIFT_NAME(SvREFCNT_inc(_:))
PERL_STATIC_INLINE SV *sPerl_SvREFCNT_inc(SV *sv) {
	return SvREFCNT_inc(sv);
}

SWIFT_NAME(SvREFCNT_dec(_:_:))
PERL_STATIC_INLINE void sPerl_SvREFCNT_dec(pTHX_ SV *sv) {
	return SvREFCNT_dec(sv);
}

// SV

SWIFT_NAME(SvTYPE(_:))
PERL_STATIC_INLINE svtype sPerl_SvTYPE(SV *sv) {
	return SvTYPE(sv);
}

SWIFT_NAME(SvOK(_:))
PERL_STATIC_INLINE bool sPerl_SvOK(SV *sv) {
	return SvOK(sv);
}

SWIFT_NAME(SvIOK(_:))
PERL_STATIC_INLINE bool sPerl_SvIOK(SV *sv) {
	return SvIOK(sv);
}

SWIFT_NAME(SvIOK_UV(_:))
PERL_STATIC_INLINE bool sPerl_SvIOK_UV(SV *sv) {
	return SvIOK_UV(sv);
}

SWIFT_NAME(SvROK(_:))
PERL_STATIC_INLINE bool sPerl_SvROK(SV *sv) {
	return SvROK(sv);
}

SWIFT_NAME(SvPOK(_:))
PERL_STATIC_INLINE bool sPerl_SvPOK(SV *sv) {
	return SvPOK(sv);
}

SWIFT_NAME(SvRV(_:))
PERL_STATIC_INLINE SV *sPerl_SvRV(SV *sv) {
	return SvRV(sv);
}

SWIFT_NAME(PerlInterpreter.SvTRUE(self:_:))
PERL_STATIC_INLINE bool sPerl_SvTRUE(pTHX_ SV *sv) {
	return SvTRUE(sv);
}

SWIFT_NAME(PerlInterpreter.SvIV(self:_:))
PERL_STATIC_INLINE IV sPerl_SvIV(pTHX_ SV *sv) {
	return SvIV(sv);
}

SWIFT_NAME(PerlInterpreter.SvUV(self:_:))
PERL_STATIC_INLINE UV sPerl_SvUV(pTHX_ SV *sv) {
	return SvUV(sv);
}

SWIFT_NAME(PerlInterpreter.SvPV(self:_:_:))
PERL_STATIC_INLINE char *sPerl_SvPV(pTHX_ SV *sv, STRLEN *len) {
	return SvPV(sv, *len);
}

// AV

SWIFT_NAME(PerlInterpreter.av_top_index(self:_:))
PERL_STATIC_INLINE SSize_t sPerl_av_top_index(pTHX_ AV *av) {
#if PERL_SUBVERSION > 16
    return av_top_index(av);
#else
    return av_len(av);
#endif
}

SWIFT_NAME(PerlInterpreter.av_store(self:_:_:_:))
PERL_STATIC_INLINE SV **sPerl_av_store(pTHX_ AV *av, SSize_t key, SV *val) {
    return av_store(av, key, val);
}

SWIFT_NAME(PerlInterpreter.av_fetch(self:_:_:_:))
PERL_STATIC_INLINE SV **sPerl_av_fetch(pTHX_ AV *av, SSize_t key, I32 lval) {
    return av_fetch(av, key, lval);
}

SWIFT_NAME(PerlInterpreter.av_extend(self:_:_:))
PERL_STATIC_INLINE void sPerl_av_extend(pTHX_ AV *av, SSize_t key) {
    return av_extend(av, key);
}

// HV

SWIFT_NAME(PerlInterpreter.hv_store(self:_:_:_:_:_:))
PERL_STATIC_INLINE SV **sPerl_hv_store(pTHX_ HV *hv, const char *key, U32 keylen, SV *val, U32 hash) {
	return hv_store(hv, key, keylen, val, hash);
}

SWIFT_NAME(PerlInterpreter.hv_fetch(self:_:_:_:_:))
PERL_STATIC_INLINE SV **sPerl_hv_fetch(pTHX_ HV *hv, const char *key, U32 keylen, I32 lval) {
	return hv_fetch(hv, key, keylen, lval);
}

SWIFT_NAME(PerlInterpreter.hv_delete(self:_:_:_:_:))
PERL_STATIC_INLINE SV *sPerl_hv_delete(pTHX_ HV *hv, const char *key, U32 keylen, I32 flags) {
	return hv_delete(hv, key, keylen, flags);
}

SWIFT_NAME(PerlInterpreter.HePV(self:_:_:))
PERL_STATIC_INLINE char *sPerl_HePV(pTHX_ HE *he, STRLEN *len) {
	return HePV(he, *len);
}

SWIFT_NAME(HeVAL(_:))
PERL_STATIC_INLINE SV *sPerl_HeVAL(HE *he) {
	return HeVAL(he);
}

// CV

SWIFT_NAME(CvXSUBANY(_:))
PERL_STATIC_INLINE ANY *sPerl_CvXSUBANY(CV *cv) {
	return &CvXSUBANY(cv);
}

// Misc

SWIFT_NAME(PerlInterpreter.load_module_noargs(self:_:_:_:))
PERL_STATIC_INLINE void sPerl_load_module_noargs(pTHX_ U32 flags, SV* name, SV* ver) {
	return load_module(flags, name, ver, NULL);
}

SWIFT_NAME(PerlInterpreter.croak_sv(self:_:))
PERL_STATIC_INLINE void sPerl_croak_sv(pTHX_ SV *baseex) {
#if PERL_SUBVERSION > 12
	croak_sv(baseex);
#else
	sv_setsv(ERRSV, baseex);
	croak(NULL);
#endif
}

SWIFT_NAME(PerlInterpreter.mg_findext(self:_:_:_:))
PERL_STATIC_INLINE MAGIC *sPerl_mg_findext(pTHX_ SV *sv, int type, const MGVTBL *vtbl) {
#if PERL_SUBVERSION > 12
	mg_findext(sv, type, vtbl)
#else
	if (sv) {
		MAGIC *mg;
#ifdef AvPAD_NAMELIST
		assert(!(SvTYPE(sv) == SVt_PVAV && AvPAD_NAMELIST(sv)));
#endif
		for (mg = SvMAGIC (sv); mg; mg = mg->mg_moremagic) {
			if (mg->mg_type == type && mg->mg_virtual == vtbl)
				return mg;
		}
	}
	return NULL;
#endif
}

// DynaLoader

EXTERN_C XS(boot_DynaLoader);

EXTERN_C void xs_init(_Nullable pTHX) {
	newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, __FILE__);
}
