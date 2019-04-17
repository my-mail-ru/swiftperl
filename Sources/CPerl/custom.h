#include <stdbool.h>

#ifndef PERL_STATIC_INLINE
#   define PERL_STATIC_INLINE static inline
#endif

#define SWIFT_NAME(X) __attribute__((swift_name(#X)))

#undef tTHX
#define tTHX PerlInterpreter *_Nonnull

typedef void (*XSINIT_t) (pTHX);
typedef void (*XSUBADDR_t) (pTHX_ CV *_Nonnull);

// Custom

SWIFT_NAME(PerlInterpreter.SvHASH(self:_:))
PERL_STATIC_INLINE U32 CPerlCustom_SvHASH(pTHX_ SV *_Nonnull sv) {
	U32 hash;
	STRLEN len;
	char *str = SvPV(sv, len);
	PERL_HASH(hash, str, len);
	return hash;
}

// Backward compatibility

/// This is an XS interface to Perl's @c die function.
///
/// @c baseex is the error message or object.  If it is a reference, it
/// will be used as-is.  Otherwise it is used as a string, and if it does
/// not end with a newline then it will be extended with some indication of
/// the current location in the code, as described for mess_sv.
///
/// The error message or object will be used as an exception, by default
/// returning control to the nearest enclosing @c eval, but subject to
/// modification by a @c $SIG{__DIE__} handler.  In any case, the @c croak_sv
/// function never returns normally.
///
/// To die with a simple string message, the croak function may be
/// more convenient.
SWIFT_NAME(PerlInterpreter.croak_sv(self:_:))
PERL_STATIC_INLINE void CPerl_croak_sv(pTHX_ SV *_Nonnull baseex) {
#if PERL_SUBVERSION > 12
	croak_sv(baseex);
#else
	sv_setsv(ERRSV, baseex);
	croak(NULL);
#endif
}

/// Finds the magic pointer of @c type with the given @c vtbl for the @c SV.  See
/// @c sv_magicext.
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
