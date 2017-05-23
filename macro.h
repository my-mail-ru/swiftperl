#include <stdbool.h>

#ifndef PERL_STATIC_INLINE
#   define PERL_STATIC_INLINE static inline
#endif

#define SWIFT_NAME(X) __attribute__((swift_name(#X)))

#undef tTHX
#define tTHX PerlInterpreter *_Nonnull

typedef void (*XSINIT_t) (pTHX);
typedef void (*XSUBADDR_t) (pTHX_ CV *_Nonnull);

// Interpreter

SWIFT_NAME(PERL_SYS_INIT3(_:_:_:))
PERL_STATIC_INLINE void CPerlMacro_sys_init3(int *_Nonnull argc, char *_Nullable *_Nonnull *_Nonnull argv, char *_Nullable *_Nonnull *_Nonnull env) {
	PERL_SYS_INIT3(argc, argv, env);
}

SWIFT_NAME(PERL_SYS_TERM())
PERL_STATIC_INLINE void CPerlMacro_sys_term(void) {
	PERL_SYS_TERM();
}

SWIFT_NAME(PERL_GET_INTERP())
PERL_STATIC_INLINE PerlInterpreter *_Nonnull CPerlMacro_PERL_GET_INTERP(void) {
	return PERL_GET_INTERP;
}

SWIFT_NAME(PERL_SET_INTERP(_:))
PERL_STATIC_INLINE void CPerlMacro_PERL_SET_INTERP(PerlInterpreter *_Nonnull p) {
	PERL_SET_INTERP(p);
}

SWIFT_NAME(PERL_GET_THX())
PERL_STATIC_INLINE PerlInterpreter *_Nonnull CPerlMacro_PERL_GET_THX(void) {
	return PERL_GET_THX;
}

SWIFT_NAME(PERL_SET_THX(_:))
PERL_STATIC_INLINE void CPerlMacro_PERL_SET_THX(PerlInterpreter *_Nonnull p) {
	PERL_SET_THX(p);
}

SWIFT_NAME(getter:PerlInterpreter.ERRSV(self:))
PERL_STATIC_INLINE SV *_Nonnull CPerlMacro_ERRSV(pTHX) {
	return ERRSV;
}

SWIFT_NAME(PerlInterpreter.boolSV(self:_:))
PERL_STATIC_INLINE SV *_Nonnull CPerlMacro_boolSV(pTHX_ bool b) {
	return boolSV(b);
}

// Stack Manipulation Macros

SWIFT_NAME(getter:PerlInterpreter.PL_stack_base(self:))
PERL_STATIC_INLINE SV *_Nonnull *_Nonnull CPerlMacro_PL_stack_base(pTHX) {
	return PL_stack_base;
}

SWIFT_NAME(getter:PerlInterpreter.PL_stack_sp(self:))
PERL_STATIC_INLINE SV *_Nonnull *_Nonnull CPerlMacro_PL_stack_sp(pTHX) {
	return PL_stack_sp;
}

SWIFT_NAME(setter:PerlInterpreter.PL_stack_sp(self:_:))
PERL_STATIC_INLINE void CPerlMacro_PL_stack_sp_set(pTHX_ SV *_Nonnull *_Nonnull sp) {
	PL_stack_sp = sp;
}

SWIFT_NAME(PerlInterpreter.EXTEND(self:_:_:))
PERL_STATIC_INLINE SV *_Nonnull *_Nonnull CPerlMacro_EXTEND(pTHX_ SV *_Nonnull *_Nonnull sp, SSize_t nitems) {
	EXTEND(sp, nitems);
	return sp;
}

SWIFT_NAME(PerlInterpreter.PUSHMARK(self:_:))
PERL_STATIC_INLINE void CPerlMacro_PUSHMARK(pTHX_ SV *_Nonnull *_Nonnull sp) {
	PUSHMARK(sp);
}

SWIFT_NAME(PerlInterpreter.POPMARK(self:))
PERL_STATIC_INLINE I32 CPerlMacro_POPMARK(pTHX) {
	return POPMARK;
}

SWIFT_NAME(getter:PerlInterpreter.TOPMARK(self:))
PERL_STATIC_INLINE I32 CPerlMacro_TOPMARK(pTHX) {
	return TOPMARK;
}

// Callback Functions

SWIFT_NAME(PerlInterpreter.SAVETMPS(self:))
PERL_STATIC_INLINE void CPerlMacro_SAVETMPS(pTHX) {
	SAVETMPS;
}

SWIFT_NAME(PerlInterpreter.FREETMPS(self:))
PERL_STATIC_INLINE void CPerlMacro_FREETMPS(pTHX) {
	FREETMPS;
}

SWIFT_NAME(PerlInterpreter.ENTER(self:))
PERL_STATIC_INLINE void CPerlMacro_ENTER(pTHX) {
	ENTER;
}

SWIFT_NAME(PerlInterpreter.LEAVE(self:))
PERL_STATIC_INLINE void CPerlMacro_LEAVE(pTHX) {
	LEAVE;
}

// SV Reference Counting

SWIFT_NAME(SvREFCNT(_:))
PERL_STATIC_INLINE U32 CPerlMacro_SvREFCNT(SV *_Nonnull sv) {
	return SvREFCNT(sv);
}

SWIFT_NAME(SvREFCNT_inc(_:))
PERL_STATIC_INLINE SV *_Nonnull CPerlMacro_SvREFCNT_inc(SV *_Nullable sv) {
	return SvREFCNT_inc(sv);
}

SWIFT_NAME(SvREFCNT_dec(_:_:))
PERL_STATIC_INLINE void CPerlMacro_SvREFCNT_dec(pTHX_ SV *_Nullable sv) {
	return SvREFCNT_dec(sv);
}

// SV

SWIFT_NAME(PerlInterpreter.newRV_inc(self:_:))
PERL_STATIC_INLINE SV *_Nonnull CPerlMacro_newRV_inc(pTHX_ SV *_Nonnull const sv) {
	return newRV_inc(sv);
}

SWIFT_NAME(SvTYPE(_:))
PERL_STATIC_INLINE svtype CPerlMacro_SvTYPE(SV *_Nonnull sv) {
	return SvTYPE(sv);
}

SWIFT_NAME(SvOK(_:))
PERL_STATIC_INLINE bool CPerlMacro_SvOK(SV *_Nonnull sv) {
	return SvOK(sv);
}

SWIFT_NAME(SvIOK(_:))
PERL_STATIC_INLINE bool CPerlMacro_SvIOK(SV *_Nonnull sv) {
	return SvIOK(sv);
}

SWIFT_NAME(SvIOK_UV(_:))
PERL_STATIC_INLINE bool CPerlMacro_SvIOK_UV(SV *_Nonnull sv) {
	return SvIOK_UV(sv);
}

SWIFT_NAME(SvIOK_notUV(_:))
PERL_STATIC_INLINE bool CPerlMacro_SvIOK_notUV(SV *_Nonnull sv) {
	return SvIOK_notUV(sv);
}

SWIFT_NAME(SvIsUV(_:))
PERL_STATIC_INLINE bool CPerlMacro_SvIsUV(SV *_Nonnull sv) {
	return SvIsUV(sv);
}

SWIFT_NAME(SvNOK(_:))
PERL_STATIC_INLINE bool CPerlMacro_SvNOK(SV *_Nonnull sv) {
	return SvNOK(sv);
}

SWIFT_NAME(SvNIOK(_:))
PERL_STATIC_INLINE bool CPerlMacro_SvNIOK(SV *_Nonnull sv) {
	return SvNIOK(sv);
}

SWIFT_NAME(SvROK(_:))
PERL_STATIC_INLINE bool CPerlMacro_SvROK(SV *_Nonnull sv) {
	return SvROK(sv);
}

SWIFT_NAME(SvPOK(_:))
PERL_STATIC_INLINE bool CPerlMacro_SvPOK(SV *_Nonnull sv) {
	return SvPOK(sv);
}

SWIFT_NAME(SvUTF8(_:))
PERL_STATIC_INLINE bool CPerlMacro_SvUTF8(SV *_Nonnull sv) {
	return SvUTF8(sv);
}

SWIFT_NAME(SvUTF8_on(_:))
PERL_STATIC_INLINE void CPerlMacro_SvUTF8_on(SV *_Nonnull sv) {
	SvUTF8_on(sv);
}

SWIFT_NAME(SvUTF8_off(_:))
PERL_STATIC_INLINE void CPerlMacro_SvUTF8_off(SV *_Nonnull sv) {
	SvUTF8_off(sv);
}

SWIFT_NAME(SvRV(_:))
PERL_STATIC_INLINE SV *_Nullable CPerlMacro_SvRV(SV *_Nonnull sv) {
	return SvRV(sv);
}

SWIFT_NAME(PerlInterpreter.SvTRUE(self:_:))
PERL_STATIC_INLINE bool CPerlMacro_SvTRUE(pTHX_ SV *_Nullable sv) {
	return SvTRUE(sv);
}

SWIFT_NAME(PerlInterpreter.SvIV(self:_:))
PERL_STATIC_INLINE IV CPerlMacro_SvIV(pTHX_ SV *_Nonnull sv) {
	return SvIV(sv);
}

SWIFT_NAME(PerlInterpreter.SvUV(self:_:))
PERL_STATIC_INLINE UV CPerlMacro_SvUV(pTHX_ SV *_Nonnull sv) {
	return SvUV(sv);
}

SWIFT_NAME(PerlInterpreter.SvNV(self:_:))
PERL_STATIC_INLINE NV CPerlMacro_SvNV(pTHX_ SV *_Nonnull sv) {
	return SvNV(sv);
}

SWIFT_NAME(PerlInterpreter.SvPV(self:_:_:))
PERL_STATIC_INLINE char *_Nullable CPerlMacro_SvPV(pTHX_ SV *_Nonnull sv, STRLEN *_Nonnull len) {
	return SvPV(sv, *len);
}

SWIFT_NAME(PerlInterpreter.SvHASH(self:_:))
PERL_STATIC_INLINE U32 CPerlCustom_SvHASH(pTHX_ SV *_Nonnull sv) {
	U32 hash;
	STRLEN len;
	char *str = SvPV(sv, len);
	PERL_HASH(hash, str, len);
	return hash;
}

// AV

// HV

SWIFT_NAME(PerlInterpreter.HePV(self:_:_:))
PERL_STATIC_INLINE char *_Nonnull CPerlMacro_HePV(pTHX_ HE *_Nonnull he, STRLEN *_Nonnull len) {
	return HePV(he, *len);
}

SWIFT_NAME(HeVAL(_:))
PERL_STATIC_INLINE SV *_Nonnull CPerlMacro_HeVAL(HE *_Nonnull he) {
	return HeVAL(he);
}

SWIFT_NAME(HvNAME(_:))
PERL_STATIC_INLINE char *_Nullable CPerlMacro_HvNAME(HV *_Nonnull stash) {
	return HvNAME(stash);
}

// CV

SWIFT_NAME(CvXSUBANY(_:))
PERL_STATIC_INLINE ANY *_Nonnull CPerlMacro_CvXSUBANY(CV *_Nonnull cv) {
	return &CvXSUBANY(cv);
}

SWIFT_NAME(PerlInterpreter.CvGV(self:_:))
PERL_STATIC_INLINE GV *_Nullable CPerlMacro_CvGV(pTHX_ CV *_Nonnull cv) {
	return CvGV(cv);
}

SWIFT_NAME(CvFILE(_:))
PERL_STATIC_INLINE char *_Nullable CPerlMacro_CvFILE(CV *_Nonnull cv) {
	return CvFILE(cv);
}

// GV

SWIFT_NAME(GvSTASH(_:))
PERL_STATIC_INLINE HV *_Nullable CPerlMacro_GvSTASH(GV *_Nonnull gv) {
	return GvSTASH(gv);
}

SWIFT_NAME(GvNAME(_:))
PERL_STATIC_INLINE char *_Nonnull CPerlMacro_GvNAME(GV *_Nonnull gv) {
	return GvNAME(gv);
}

// Backward compatibility

SWIFT_NAME(PerlInterpreter.croak_sv(self:_:))
PERL_STATIC_INLINE void CPerl_croak_sv(pTHX_ SV *_Nonnull baseex) {
#if PERL_SUBVERSION > 12
	croak_sv(baseex);
#else
	sv_setsv(ERRSV, baseex);
	croak(NULL);
#endif
}

SWIFT_NAME(PerlInterpreter.mg_findext(self:_:_:_:))
PERL_STATIC_INLINE MAGIC *_Nullable CPerl_mg_findext(pTHX_ SV *_Nullable sv, int type, const MGVTBL *_Nullable vtbl) {
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

EXTERN_C void boot_DynaLoader(pTHX_ CV *_Nonnull cv);

EXTERN_C void xs_init(pTHX) {
	newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, __FILE__);
}
