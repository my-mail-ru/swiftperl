#include <stdbool.h>

#ifndef PERL_STATIC_INLINE
#   define PERL_STATIC_INLINE static inline
#endif

#define SWIFT_NAME(X) __attribute__((swift_name(#X)))

typedef void (*XSUBADDR_t) (_Nonnull pTHX_ _Nonnull CV *);

// Interpreter

SWIFT_NAME(PERL_SYS_INIT3(_:_:_:))
PERL_STATIC_INLINE void sPerl_sys_init3(_Nonnull int* argc, char ** _Nonnull *argv, char ***env) {
	PERL_SYS_INIT3(argc, argv, env);
}

SWIFT_NAME(PERL_SYS_TERM())
PERL_STATIC_INLINE void sPerl_sys_term(void) {
	PERL_SYS_TERM();
}

SWIFT_NAME(PerlInterpreter.alloc())
PERL_STATIC_INLINE PerlInterpreter *sPerl_alloc(void) {
	return perl_alloc();
}

SWIFT_NAME(PerlInterpreter.construct(self:))
PERL_STATIC_INLINE void sPerl_construct(_Nonnull PerlInterpreter *my_perl) {
	perl_construct(my_perl);
}

SWIFT_NAME(PerlInterpreter.destruct(self:))
PERL_STATIC_INLINE int sPerl_destruct(_Nonnull PerlInterpreter *my_perl) {
	return perl_destruct(my_perl);
}

SWIFT_NAME(PerlInterpreter.free(self:))
PERL_STATIC_INLINE void sPerl_free(_Nonnull PerlInterpreter *my_perl) {
	perl_free(my_perl);
}

SWIFT_NAME(PerlInterpreter.parse(self:_:_:_:_:))
PERL_STATIC_INLINE int sPerl_parse(_Nonnull PerlInterpreter *my_perl, XSINIT_t xsinit, int argc, char** argv, char** env) {
	return perl_parse(my_perl, xsinit, argc, argv, env);
}

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

SWIFT_NAME(PerlInterpreter.boolSV(self:_:))
PERL_STATIC_INLINE _Nonnull SV *sPerl_boolSV(pTHX_ bool b) {
	return boolSV(b);
}

// Stack Manipulation Macros

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

// Callback Functions

SWIFT_NAME(PerlInterpreter.SAVETMPS(self:))
PERL_STATIC_INLINE void sPerl_SAVETMPS(pTHX) {
	SAVETMPS;
}

SWIFT_NAME(PerlInterpreter.FREETMPS(self:))
PERL_STATIC_INLINE void sPerl_FREETMPS(pTHX) {
	FREETMPS;
}

SWIFT_NAME(PerlInterpreter.ENTER(self:))
PERL_STATIC_INLINE void sPerl_ENTER(pTHX) {
	ENTER;
}

SWIFT_NAME(PerlInterpreter.LEAVE(self:))
PERL_STATIC_INLINE void sPerl_LEAVE(pTHX) {
	LEAVE;
}

SWIFT_NAME(PerlInterpreter.call_sv(self:_:_:))
PERL_STATIC_INLINE I32 sPerl_call_sv(pTHX_ _Nonnull SV* sv, VOL I32 flags) {
	return call_sv(sv, flags);
}

SWIFT_NAME(PerlInterpreter.eval_sv(self:_:_:))
PERL_STATIC_INLINE I32 sPerl_eval_sv(pTHX_ _Nonnull SV* sv, I32 flags) {
	return eval_sv(sv, flags);
}

// SV Reference Counting

SWIFT_NAME(SvREFCNT(_:))
PERL_STATIC_INLINE U32 sPerl_SvREFCNT(_Nonnull SV *sv) {
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

SWIFT_NAME(PerlInterpreter.sv_2mortal(self:_:))
PERL_STATIC_INLINE SV *sPerl_sv_2mortal(pTHX_ _Nonnull SV *const sv) {
	return sv_2mortal(sv);
}

// SV

SWIFT_NAME(PerlInterpreter.get_sv(self:_:_:))
PERL_STATIC_INLINE _Nullable SV *sPerl_get_sv(pTHX_ _Nonnull const char *name, I32 flags) {
	return get_sv(name, flags);
}

SWIFT_NAME(PerlInterpreter.newSV(self:))
PERL_STATIC_INLINE SV *sPerl_newSV(pTHX) {
	return newSV(0);
}

SWIFT_NAME(PerlInterpreter.newSV(self:_:))
PERL_STATIC_INLINE SV *sPerl_newSVsv(pTHX_ SV *const old) {
	return newSVsv(old);
}

SWIFT_NAME(PerlInterpreter.newSV(self:_:))
PERL_STATIC_INLINE SV *sPerl_newSViv(pTHX_ const IV i) {
	return newSViv(i);
}

SWIFT_NAME(PerlInterpreter.newSVpvn_flags(self:_:_:_:))
PERL_STATIC_INLINE SV *sPerl_newSVpvn_flags(pTHX_ const char *const s, const STRLEN len, const U32 flags) {
	return newSVpvn_flags(s, len, flags);
}

SWIFT_NAME(PerlInterpreter.newRV(self:inc:))
PERL_STATIC_INLINE SV *sPerl_newRV_inc(pTHX_ _Nonnull SV *const sv) {
	return newRV_inc(sv);
}

SWIFT_NAME(PerlInterpreter.newRV(self:noinc:))
PERL_STATIC_INLINE SV *sPerl_newRV_noinc(pTHX_ _Nonnull SV *const sv) {
	return newRV_noinc(sv);
}

SWIFT_NAME(SvTYPE(_:))
PERL_STATIC_INLINE svtype sPerl_SvTYPE(_Nonnull SV *sv) {
	return SvTYPE(sv);
}

SWIFT_NAME(SvOK(_:))
PERL_STATIC_INLINE bool sPerl_SvOK(_Nonnull SV *sv) {
	return SvOK(sv);
}

SWIFT_NAME(SvIOK(_:))
PERL_STATIC_INLINE bool sPerl_SvIOK(_Nonnull SV *sv) {
	return SvIOK(sv);
}

SWIFT_NAME(SvIOK_UV(_:))
PERL_STATIC_INLINE bool sPerl_SvIOK_UV(_Nonnull SV *sv) {
	return SvIOK_UV(sv);
}

SWIFT_NAME(SvNIOK(_:))
PERL_STATIC_INLINE bool sPerl_SvNIOK(_Nonnull SV *sv) {
	return SvNIOK(sv);
}

SWIFT_NAME(SvROK(_:))
PERL_STATIC_INLINE bool sPerl_SvROK(_Nonnull SV *sv) {
	return SvROK(sv);
}

SWIFT_NAME(SvPOK(_:))
PERL_STATIC_INLINE bool sPerl_SvPOK(_Nonnull SV *sv) {
	return SvPOK(sv);
}

SWIFT_NAME(SvRV(_:))
PERL_STATIC_INLINE SV *sPerl_SvRV(_Nonnull SV *sv) {
	return SvRV(sv);
}

SWIFT_NAME(PerlInterpreter.SvTRUE(self:_:))
PERL_STATIC_INLINE bool sPerl_SvTRUE(pTHX_ SV *sv) {
	return SvTRUE(sv);
}

SWIFT_NAME(PerlInterpreter.SvIV(self:_:))
PERL_STATIC_INLINE IV sPerl_SvIV(pTHX_ _Nonnull SV *sv) {
	return SvIV(sv);
}

SWIFT_NAME(PerlInterpreter.SvUV(self:_:))
PERL_STATIC_INLINE UV sPerl_SvUV(pTHX_ _Nonnull SV *sv) {
	return SvUV(sv);
}

SWIFT_NAME(PerlInterpreter.SvPV(self:_:_:))
PERL_STATIC_INLINE char *sPerl_SvPV(pTHX_ _Nonnull SV *sv, STRLEN *len) {
	return SvPV(sv, *len);
}

SWIFT_NAME(PerlInterpreter.sv_reftype(self:_:_:))
PERL_STATIC_INLINE const char *sPerl_sv_reftype(pTHX_ _Nonnull const SV *const sv, const bool ob) {
	return sv_reftype(sv, ob);
}

SWIFT_NAME(PerlInterpreter.sv_isobject(self:_:))
PERL_STATIC_INLINE bool sPerl_sv_isobject(pTHX_ SV* sv) {
	return sv_isobject(sv);
}

SWIFT_NAME(PerlInterpreter.sv_setref_iv(self:_:_:_:))
PERL_STATIC_INLINE _Nonnull SV *sPerl_sv_setref_iv(pTHX_ _Nonnull SV *const rv, const char *const classname, const IV iv) {
	return sv_setref_iv(rv, classname, iv);
}

SWIFT_NAME(PerlInterpreter.sv_derived_from(self:_:_:))
PERL_STATIC_INLINE bool sPerl_sv_derived_from(pTHX_ _Nonnull SV* sv, _Nonnull const char *const name) {
	return sv_derived_from(sv, name);
}

SWIFT_NAME(PerlInterpreter.looks_like_number(self:_:))
PERL_STATIC_INLINE bool sPerl_looks_like_number(pTHX_ SV *const sv) {
	return looks_like_number(sv);
}

// AV

SWIFT_NAME(PerlInterpreter.newAV(self:))
PERL_STATIC_INLINE AV *sPerl_newAV(pTHX) {
	return newAV();
}

SWIFT_NAME(PerlInterpreter.av_top_index(self:_:))
PERL_STATIC_INLINE SSize_t sPerl_av_top_index(pTHX_ _Nonnull AV *av) {
#if PERL_SUBVERSION > 16
    return av_top_index(av);
#else
    return av_len(av);
#endif
}

SWIFT_NAME(PerlInterpreter.av_store(self:_:_:_:))
PERL_STATIC_INLINE SV **sPerl_av_store(pTHX_ _Nonnull AV *av, SSize_t key, SV *val) {
    return av_store(av, key, val);
}

SWIFT_NAME(PerlInterpreter.av_fetch(self:_:_:_:))
PERL_STATIC_INLINE SV **sPerl_av_fetch(pTHX_ _Nonnull AV *av, SSize_t key, I32 lval) {
    return av_fetch(av, key, lval);
}

SWIFT_NAME(PerlInterpreter.av_extend(self:_:_:))
PERL_STATIC_INLINE void sPerl_av_extend(pTHX_ _Nonnull AV *av, SSize_t key) {
    return av_extend(av, key);
}

SWIFT_NAME(PerlInterpreter.av_push(self:_:_:))
PERL_STATIC_INLINE void sPerl_av_push(pTHX_ _Nonnull AV *av, _Nonnull SV *val) {
	return av_push(av, val);
}

SWIFT_NAME(PerlInterpreter.av_shift(self:_:))
PERL_STATIC_INLINE SV *sPerl_av_shift(pTHX_ _Nonnull AV *av) {
	return av_shift(av);
}

// HV

SWIFT_NAME(PerlInterpreter.newHV(self:))
PERL_STATIC_INLINE HV *sPerl_newHV(pTHX) {
	return newHV();
}

SWIFT_NAME(PerlInterpreter.hv_store(self:_:_:_:_:_:))
PERL_STATIC_INLINE SV **sPerl_hv_store(pTHX_ _Nonnull HV *hv, _Nonnull const char *key, U32 keylen, SV *val, U32 hash) {
	return hv_store(hv, key, keylen, val, hash);
}

SWIFT_NAME(PerlInterpreter.hv_fetch(self:_:_:_:_:))
PERL_STATIC_INLINE SV **sPerl_hv_fetch(pTHX_ _Nonnull HV *hv, _Nonnull const char *key, U32 keylen, I32 lval) {
	return hv_fetch(hv, key, keylen, lval);
}

SWIFT_NAME(PerlInterpreter.hv_delete(self:_:_:_:_:))
PERL_STATIC_INLINE SV *sPerl_hv_delete(pTHX_ _Nonnull HV *hv, _Nonnull const char *key, U32 keylen, I32 flags) {
	return hv_delete(hv, key, keylen, flags);
}

SWIFT_NAME(PerlInterpreter.hv_iterinit(self:_:))
PERL_STATIC_INLINE I32 sPerl_hv_iterinit(pTHX_ _Nonnull HV *hv) {
	return hv_iterinit(hv);
}

SWIFT_NAME(PerlInterpreter.hv_iternext(self:_:))
PERL_STATIC_INLINE HE *sPerl_hv_iternext(pTHX_ _Nonnull HV *hv) {
	return hv_iternext(hv);
}

SWIFT_NAME(PerlInterpreter.HePV(self:_:_:))
PERL_STATIC_INLINE char *sPerl_HePV(pTHX_ _Nonnull HE *he, STRLEN *len) {
	return HePV(he, *len);
}

SWIFT_NAME(HeVAL(_:))
PERL_STATIC_INLINE SV *sPerl_HeVAL(_Nonnull HE *he) {
	return HeVAL(he);
}

// CV

SWIFT_NAME(CvXSUBANY(_:))
PERL_STATIC_INLINE ANY *sPerl_CvXSUBANY(_Nonnull CV *cv) {
	return &CvXSUBANY(cv);
}

SWIFT_NAME(CvFILE(_:))
PERL_STATIC_INLINE char *sPerl_CvFILE(_Nonnull CV *cv) {
	return CvFILE(cv);
}

SWIFT_NAME(PerlInterpreter.newXS_flags(self:_:_:_:_:_:))
PERL_STATIC_INLINE CV *sPerl_newXS_flags(pTHX_ const char *name, _Nonnull XSUBADDR_t subaddr, _Nonnull const char *const filename, const char *const proto, U32 flags) {
	return newXS_flags(name, subaddr, filename, proto, flags);
}

// Misc

SWIFT_NAME(PerlInterpreter.load_module_noargs(self:_:_:_:))
PERL_STATIC_INLINE void sPerl_load_module_noargs(pTHX_ U32 flags, _Nonnull SV* name, SV* ver) {
	return load_module(flags, name, ver, NULL);
}

SWIFT_NAME(PerlInterpreter.croak_sv(self:_:))
PERL_STATIC_INLINE void sPerl_croak_sv(pTHX_ _Nonnull SV *baseex) {
#if PERL_SUBVERSION > 12
	croak_sv(baseex);
#else
	sv_setsv(ERRSV, baseex);
	croak(NULL);
#endif
}

SWIFT_NAME(PerlInterpreter.sv_magicext(self:_:_:_:_:_:_:))
PERL_STATIC_INLINE MAGIC *sPerl_sv_magicext(pTHX_ _Nonnull SV *const sv, SV *const obj, const int how, const MGVTBL *const vtbl, const char *const name, const I32 namlen) {
	return sv_magicext(sv, obj, how, vtbl, name, namlen);
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
