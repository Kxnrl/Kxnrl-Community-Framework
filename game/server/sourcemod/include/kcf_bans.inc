#if defined _KCF_Bans_Include_
    #endinput
#endif

#define _KCF_Bans_Include_

native bool KCF_Bans_BanClient(int admin, int target, int ban_type, int ban_length, const char[] ban_reason);
native bool KCF_Bans_BanIdentity(int admin, const char[] ban_identity_steamid64, int ban_type, int ban_length, const char[] ban_reason);

public SharedPlugin __pl_KCF_Bans =
{
	name = "KCF-Bans",
	file = "kcf_bans.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};