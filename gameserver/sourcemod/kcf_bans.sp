#pragma semicolon 1
#pragma newdecls required

// core extension
#include <kMessager>

#undef REQUIRE_EXTENSIONS
#include <kxnrltools>

#include <smutils>
#include <kcf_core>
#include <kcf_bans>


public Plugin myinfo = 
{
    name        = "KCF - Bans",
    author      = "Kyle",
    description = "Banning and Admin system of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://www.kxnrl.com"
};

#define INVALID_AID -1

static bool g_pkTools;

#include "bans/adminsys.sp"
#include "bans/banning.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("KCF-Bans");

    AdmSys_CreateNative();
    BanSys_CreateNative();
    
    MarkNativeAsOptional("kTools_CSteamIDConvert");

    return APLRes_Success;
}

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");
    SMUtils_SetChatConSnd(false);

    AdmSys_Init();
    BanSys_Init();

    g_pkTools = LibraryExists("kTools");
}

public void KCF_OnServerLoaded()
{
    AdmSys_OnServerLoaded();
    BanSys_OnServerLoaded();
}

public void kMessager_OnRecv(Message_Type type)
{
    switch (type)
    {
        case Ban_LoadAdmins:        AdmSys_OnAdminsLoaded();
        case Ban_InsertIdentity:    BanSys_OnIdentityBan();
        case Ban_CheckUser:         BanSys_OnCheckUser();
    }
}

public void OnClientConnected(int client)
{
    AdmSys_OnClientConnected(client);
    BanSys_OnClientConnected(client);
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if(IsFakeClient(client) || IsClientSourceTV(client))
        return;

    char steamid[32];
    if(!GetClientAuthId(client, AuthId_SteamID64, steamid, 32, true))
    {
        KickClient(client, "INVALID SteamID");
        return;
    }

    AdmSys_OnClientAuthorized(client, auth, steamid);
    BanSys_OnClientAuthorized(client, auth, steamid);
}

public void OnClientDisconnect_Post(int client)
{
    AdmSys_OnClientDisconnected(client);
    BanSys_OnClientDisconnected(client);
}

public void OnLibraryAdded(const char[] name)
{
    if(strcmp(name, "kTools") == 0)
        g_pkTools = true;
}

public void OnLibraryRemoved(const char[] name)
{
    if(strcmp(name, "kTools") == 0)
        g_pkTools = false;
}

void ConvertToSteamId32(const char[] input, char[] output, int maxLen)
{
    if(g_pkTools) kTools_CSteamIDConvert(input, AuthId_Steam2, output, maxLen);
    else          ConvertSteam64ToSteam32(input, output, maxLen);
}