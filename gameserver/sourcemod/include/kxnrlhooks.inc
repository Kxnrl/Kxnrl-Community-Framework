#if defined _kHooks_included
    #endinput
#endif
#define _kHooks_included

native bool kHooks_IsClientSpeaking(int client);

forward void kHooks_OnStartSpeaking(int client);
forward void kHooks_OnEndSpeaking(int client);

public Extension __ext_kHooks = 
{
    name = "kHooks",
    file = "kxnrl.hooks.ext",
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
public void __ext_kHooks_SetNTVOptional()
{
    MarkNativeAsOptional("kHooks_IsClientSpeaking");
}
#endif