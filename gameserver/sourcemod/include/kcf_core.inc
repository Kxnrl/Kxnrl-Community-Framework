#if defined _KCF_Core_Include_
    #endinput
#endif

#define _KCF_Core_Include_

#define PI_VERSION "1.1.0"

native int KCF_Server_GetSrvId();
native int KCF_Server_GetModId();

native int KCF_Client_GetPId(int client);
native int KCF_Client_FindByPId(int pid);
native int KCF_Client_GetFirstJoin(int client);
native int KCF_Client_GetLastSeen(int client);
native int KCF_Client_GetConnections(int client);
native int KCF_Client_GetOnlinetimes(int client);
native int KCF_Client_GetSignInTimes(int client);
native int KCF_Client_GetSignInDate(int client);
native int KCF_Client_GetSignInKeep(int client);
native int KCF_Client_GetPlayTotal(int client);
native int KCF_Client_GetSepcTotal(int client);
native int KCF_Client_GetAliveTime(int client);

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