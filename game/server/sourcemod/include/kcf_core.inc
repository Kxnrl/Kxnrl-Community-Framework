#if defined _KCF_Core_Include_
    #endinput
#endif

#define _KCF_Core_Include_

#define PI_VERSION "1.0.6"

enum Client_t
{
    iUniqueId,
    iFirstJoin,
    iLastSeen,
    iConnections,
    iOnlineTime,
    iSignTimes,
    iSignDate
}

native Database KCF_Core_GetMySQL();
native int KCF_Core_GetServerId();
native int KCF_Core_GetSrvModId();

native int  KCF_Core_GetClientUId(int client);
native bool KCF_Core_GetClientData(int client, int[] data); // Client_t

forward void KCF_OnServerLoaded(int sid, int mod);
forward void KCF_OnClientLoaded(int client, int uid);
forward void KCF_OnClientSigned(int client, int signtimes);

public SharedPlugin __pl_KCF_Core =
{
	name = "KCF-Core",
	file = "kcf_core.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};