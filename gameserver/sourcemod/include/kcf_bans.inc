#if defined _KCF_Bans_Include_
    #endinput
#endif

#define _KCF_Bans_Include_

native bool KCF_Admin_IsAuthAdmin(const char[] auth);
native bool KCF_Admin_IsClientAdmin(int client);
native int  KCF_Admin_GetAdminId(int client);
native void KCF_Admin_GetAdminName(int client, char[] buffer, int maxLen);
native void KCF_Admin_LogAction(int admin, const char[] action, const char[] message, any ...);

native bool KCF_Ban_BanClient(int admin, int target, int ban_type, int ban_length, const char[] ban_reason);
native bool KCF_Ban_BanIdentity(int admin, const char[] identity, int ban_type, int ban_length, const char[] ban_reason);

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