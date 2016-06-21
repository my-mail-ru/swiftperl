#ifndef WITH_IMPL
#	define SWIFT_NAME(X) __attribute__((swift_name(#X)))
#	define NN _Nonnull
#	define NL _Nullable
#	define IMPL(X) ;
#else
#	define SWIFT_NAME(X)
#	define NN
#	define NL
#	define IMPL(X) X
#endif

SWIFT_NAME(getter:PerlInterpreter.current()) NN PerlInterpreter *swp_PERL_GET_THX(void) IMPL({ return PERL_GET_THX; })
SWIFT_NAME(setter:PerlInterpreter.current(_:)) void swp_PERL_SET_THX(NN PerlInterpreter *p) IMPL({ PERL_SET_THX(p); })

SWIFT_NAME(SvTYPE(_:)) svtype sPerl_SvTYPE(SV *sv) IMPL({ return SvTYPE(sv); })
SWIFT_NAME(SvOK(_:)) bool sPerl_SvOK(SV *sv) IMPL({ return SvOK(sv); })
SWIFT_NAME(SvIOK(_:)) bool sPerl_SvIOK(SV *sv) IMPL({ return SvIOK(sv); })
SWIFT_NAME(SvIOK_UV(_:)) bool sPerl_SvIOK_UV(SV *sv) IMPL({ return SvIOK_UV(sv); })
SWIFT_NAME(SvROK(_:)) bool sPerl_SvROK(SV *sv) IMPL({ return SvROK(sv); })
SWIFT_NAME(SvPOK(_:)) bool sPerl_SvPOK(SV *sv) IMPL({ return SvPOK(sv); })
SWIFT_NAME(PerlInterpreter.SvTRUE(self:_:)) bool sPerl_SvTRUE(pTHX_ SV *sv) IMPL({ return SvTRUE(sv); })
SWIFT_NAME(PerlInterpreter.SvIV(self:_:)) IV sPerl_SvIV(pTHX_ SV *sv) IMPL({ return SvIV(sv); })
SWIFT_NAME(PerlInterpreter.SvUV(self:_:)) UV sPerl_SvUV(pTHX_ SV *sv) IMPL({ return SvUV(sv); })
SWIFT_NAME(SvRV(_:)) SV *sPerl_SvRV(SV *sv) IMPL({ return SvRV(sv); })
SWIFT_NAME(SvREFCNT(_:)) U32 sPerl_SvREFCNT(SV *sv) IMPL({ return SvREFCNT(sv); })

SWIFT_NAME(getter:PerlInterpreter.ERRSV(self:)) NN SV *sPerl_ERRSV(pTHX) IMPL({ return ERRSV; })

SWIFT_NAME(PerlInterpreter.PUSHMARK(self:_:)) void sPerl_PUSHMARK(pTHX_ NN SV **sp) IMPL({ PUSHMARK(sp); })
SWIFT_NAME(PerlInterpreter.POPMARK(self:)) I32 sPerl_POPMARK(pTHX) IMPL({ return POPMARK; })
SWIFT_NAME(getter:PerlInterpreter.TOPMARK(self:)) I32 sPerl_TOPMARK(pTHX) IMPL({ return TOPMARK; })

SWIFT_NAME(PerlInterpreter.SAVETMPS(self:)) void sPerl_SAVETMPS(pTHX) IMPL({ SAVETMPS; })
SWIFT_NAME(PerlInterpreter.FREETMPS(self:)) void sPerl_FREETMPS(pTHX) IMPL({ FREETMPS; })

SWIFT_NAME(PerlInterpreter.EXTEND(self:_:_:)) SV **sPerl_EXTEND(pTHX_ NN SV **sp, SSize_t nitems) IMPL({ EXTEND(sp, nitems); return sp; })

SWIFT_NAME(PerlInterpreter.SvPV(self:_:_:)) char *sPerl_SvPV(pTHX_ SV *sv, STRLEN *len) IMPL({ return SvPV(sv, *len); })

SWIFT_NAME(PerlInterpreter.hv_store(self:_:_:_:_:_:)) SV **sPerl_hv_store(pTHX_ HV *hv, const char *key, U32 keylen, SV *val, U32 hash) IMPL({ return hv_store(hv, key, keylen, val, hash); })
SWIFT_NAME(PerlInterpreter.hv_fetch(self:_:_:_:_:)) SV **sPerl_hv_fetch(pTHX_ HV *hv, const char *key, U32 keylen, I32 lval) IMPL({ return hv_fetch(hv, key, keylen, lval); })
SWIFT_NAME(PerlInterpreter.hv_delete(self:_:_:_:_:)) SV *sPerl_hv_delete(pTHX_ HV *hv, const char *key, U32 keylen, I32 flags) IMPL({ return hv_delete(hv, key, keylen, flags); })

SWIFT_NAME(PerlInterpreter.HePV(self:_:_:)) char *sPerl_HePV(pTHX_ HE *he, STRLEN *len) IMPL({ return HePV(he, *len); })
SWIFT_NAME(HeVAL(_:)) SV *sPerl_HeVAL(HE *he) IMPL({ return HeVAL(he); })

SWIFT_NAME(CvXSUBANY(_:)) ANY *sPerl_CvXSUBANY(CV *cv) IMPL({ return &CvXSUBANY(cv); })

SWIFT_NAME(PerlInterpreter.load_module_noargs(self:_:_:_:)) void sPerl_load_module_noargs(pTHX_ U32 flags, SV* name, SV* ver) IMPL({ return load_module(flags, name, ver, NULL); })

EXTERN_C XS(boot_DynaLoader);
EXTERN_C void xs_init(NL pTHX) IMPL({ newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, __FILE__); })
