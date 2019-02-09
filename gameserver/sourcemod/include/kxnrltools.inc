#if defined _kTools_included
    #endinput
#endif
#define _kTools_included

native void kTools_CSteamIDConvert(const char[] input, AuthIdType auth, char[] output, int maxLen);

public Extension __ext_kTools = 
{
    name = "kTools",
    file = "kxnrl.tools.ext",
#if defined AUTOLOAD_EXTENSIONS
    autoload = 1,
#else
    autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_kTools_SetNTVOptional()
{
    MarkNativeAsOptional("kTools_CSteamIDConvert");
}
#endif