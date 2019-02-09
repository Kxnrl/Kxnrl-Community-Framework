#pragma semicolon 1
#pragma newdecls required

// core extension
#include <kMessager>
#include <A2SFirewall>

// helper
#include <smutils>

// header
#include <kcf_core>

public Plugin myinfo = 
{
    name        = "KCF - Core",
    author      = "Kyle",
    description = "Core Api plugin of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://www.kxnrl.com"
};

enum struct client_info_t
{
    int m_PId;
    int m_TId;
    int m_FirstJoin;
    int m_LastSeen;
    int m_Connections;
    int m_Onlinetimes;
    int m_SignInTimes;
    int m_SignInDate;
    int m_SignInKeep;
    int m_PlayTotal;
    int m_SpecTotal;
    int m_AliveTime;
}

enum struct server_info_t
{
    int m_SrvId;
    int m_ModId;
    char m_Hostname[128];
}

enum struct handle_info_t
{
    Handle m_ServerLoaded;
    Handle m_ClientLoaded;
    Handle m_ClientSignIn;
    Handle m_KeyValueData;
}

enum struct timers_info_t
{
    Handle m_Load;
    Handle m_Sign;
    Handle m_Stat;
}

enum struct istats_info_t
{
    int m_ConnectTime;
    int m_PlayTotal;
    int m_SpecTotal;
    int m_AliveTime;
}

enum struct cached_info_t
{
    KeyValues m_KV;
    char m_Path[128];
}

static timers_info_t g_Timers[MAXPLAYERS+1];
static client_info_t g_Client[MAXPLAYERS+1];
static server_info_t g_Server;
static handle_info_t g_Handle;
static istats_info_t g_IStats[MAXPLAYERS+1];
static cached_info_t g_Cached;

static int g_iTimeout[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("KCF-Core");

    CreateNative("KCF_Server_GetSrvId",     Native_GetServerId);
    CreateNative("KCF_Server_GetModId",     Native_GetSrvModId);

    // Clients
    CreateNative("KCF_Client_GetPId",           Native_GetUniqueId);
    CreateNative("KCF_Client_FindByPId",        Native_FindByPId);
    CreateNative("KCF_Client_GetFirstJoin",     Native_GetFirstJoin);
    CreateNative("KCF_Client_GetLastSeen",      Native_GetLastSeen);
    CreateNative("KCF_Client_GetConnections",   Native_GetConnections);
    CreateNative("KCF_Client_GetOnlinetimes",   Native_GetOnlinetimes);
    CreateNative("KCF_Client_GetSignInTimes",   Native_GetSignInTimes);
    CreateNative("KCF_Client_GetSignInDate",    Native_GetSignInDate);
    CreateNative("KCF_Client_GetSignInKeep",    Native_GetSignInKeep);
    CreateNative("KCF_Client_GetPlayTotal",     Native_GetPlayTotal);
    CreateNative("KCF_Client_GetSepcTotal",     Native_GetSepcTotal);
    CreateNative("KCF_Client_GetAliveTime",     Native_GetAliveTime);

    return APLRes_Success;
}

public any Native_GetServerId(Handle plugin, int numParams)
{
    return g_Server.m_SrvId;
}

public any Native_GetSrvModId(Handle plugin, int numParams)
{
    return g_Server.m_ModId;
}

public any Native_GetUniqueId(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_PId;
}

public any Native_FindByPId(Handle plugin, int numParams)
{
    return FindClientByPId(GetNativeCell(1));
}

public any Native_GetFirstJoin(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_FirstJoin;
}

public any Native_GetLastSeen(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_LastSeen;
}

public any Native_GetConnections(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_Connections;
}

public any Native_GetOnlinetimes(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_Onlinetimes;
}

public any Native_GetSignInTimes(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_SignInTimes;
}

public any Native_GetSignInDate(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_SignInDate;
}

public any Native_GetSignInKeep(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_SignInKeep;
}

public any Native_GetPlayTotal(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_PlayTotal;
}

public any Native_GetSepcTotal(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_SpecTotal;
}

public any Native_GetAliveTime(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client].m_AliveTime;
}

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");
    SMUtils_SetChatConSnd(true);

    g_Handle.m_ServerLoaded = CreateGlobalForward("KCF_OnServerLoaded",  ET_Ignore, Param_Cell, Param_Cell);
    g_Handle.m_ClientLoaded = CreateGlobalForward("KCF_OnClientLoaded",  ET_Ignore, Param_Cell, Param_Cell);
    g_Handle.m_ClientSignIn = CreateGlobalForward("KCF_OnClientSigned",  ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

    RegConsoleCmd("sm_sign",    Command_Sign);
    RegConsoleCmd("sm_login",   Command_Sign);
    RegConsoleCmd("sm_qiandao", Command_Sign);

    LoadServer();
    LoadCached();

    for(int client = MinClients; client <= MaxClients; ++client)
        if(ClientIsValid(client, true))
        {
            OnClientConnected(client);
            OnClientPutInServer(client);
        }
}

static void LoadCached()
{
    BuildPath(Path_SM, g_Cached.m_Path, 128, "data/com.kxnrl.kcf.core.playerdata.kv");

    g_Cached.m_KV = new KeyValues("Kxnrl.PlayerData", "", "");

    g_Cached.m_KV.ImportFromFile(g_Cached.m_Path);

    if(!g_Cached.m_KV.GotoFirstSubKey(true))
    {
        // null data
        CreateTimer(3.0, Timer_SaveCache, _, TIMER_REPEAT);
        return;
    }
    
    do
    {
        int pid = g_Cached.m_KV.GetNum("pid", 0);
        int tid = g_Cached.m_KV.GetNum("tid", 0);
        int crt = g_Cached.m_KV.GetNum("crt", 0); // duration
        int ttl = g_Cached.m_KV.GetNum("ttl", 0); // playtotal
        int obs = g_Cached.m_KV.GetNum("obs", 0); // spectotal
        int alt = g_Cached.m_KV.GetNum("alt", 0); // alivetime
        
        if(pid <= 0 || tid <= 0 || crt > 10800) continue;

        kMessager_InitBuffer();
        kMessager_WriteInt32("pid",         pid);
        kMessager_WriteInt32("tid",         tid);
        kMessager_WriteShort("duration",    crt);
        kMessager_WriteShort("play",        ttl);
        kMessager_WriteShort("spec",        obs);
        kMessager_WriteShort("alive",       alt);
        kMessager_SendBuffer(Stats_Update);
        
        LogMessage("Re-push from cache -> %d -> %d", pid, tid);
    }
    while(g_Cached.m_KV.GotoNextKey(true));
    
    delete g_Cached.m_KV;
    
    g_Cached.m_KV = new KeyValues("Kxnrl.PlayerData", "", "");
    g_Cached.m_KV.ExportToFile(g_Cached.m_Path);

    CreateTimer(3.0, Timer_SaveCache, _, TIMER_REPEAT);
}

static void RemoveFromCache(int client)
{
    g_Cached.m_KV.Rewind();
    
    char steamid[32];
    if(!GetClientAuthId(client, AuthId_SteamID64, steamid, 32, false))
        return;

    if(!g_Cached.m_KV.JumpToKey(steamid, false))
        return;
    
    g_Cached.m_KV.DeleteThis();
    g_Cached.m_KV.Rewind();
    g_Cached.m_KV.ExportToFile(g_Cached.m_Path);
}

public Action Timer_SaveCache(Handle timer)
{
    g_Cached.m_KV.Rewind();
    
    char steamid[32], map[128];
    GetCurrentMap(map, 128);
    
    int time_t = GetTime();

    for(int client = MinClients; client <= MaxClients; ++client)
        if(g_Client[client].m_PId > 0 && g_Client[client].m_TId > 0)
            if(GetClientAuthId(client, AuthId_SteamID64, steamid, 32, false))
            {
                // Tree
                g_Cached.m_KV.JumpToKey(steamid, true);

                // Save
                g_Cached.m_KV.SetNum("pid", g_Client[client].m_PId);
                g_Cached.m_KV.SetNum("tid", g_Client[client].m_TId);
                g_Cached.m_KV.SetNum("crt", time_t - g_IStats[client].m_ConnectTime);
                g_Cached.m_KV.SetNum("ttl", g_IStats[client].m_PlayTotal);
                g_Cached.m_KV.SetNum("obs", g_IStats[client].m_SpecTotal);
                g_Cached.m_KV.SetNum("alt", g_IStats[client].m_AliveTime);

                g_Cached.m_KV.Rewind();
            }

    g_Cached.m_KV.Rewind();
    g_Cached.m_KV.ExportToFile(g_Cached.m_Path);

    return Plugin_Continue;
}

public void kMessager_OnRecv(Message_Type type)
{
    switch (type)
    {
        case Server_Load:       OnServerLoad();
        case Stats_LoadUser:    OnClientLoad();
        case Stats_Analytics:   OnClientStat();
        case Stats_DailySignIn: OnSignInLoad();
    }
}

static void LoadServer()
{
    ConVar cvar = FindConVar("sv_hibernate_when_empty");
    if(cvar != null)
        cvar.IntValue = 0;

    cvar = FindConVar("hostip");
    if(cvar == null)
        SetFailState("hostip is invalid CVar");

    char ip[24];
    FormatEx(ip, 24, "%d.%d.%d.%d", ((cvar.IntValue & 0xFF000000) >> 24) & 0xFF, ((cvar.IntValue & 0x00FF0000) >> 16) & 0xFF, ((cvar.IntValue & 0x0000FF00) >>  8) & 0xFF, ((cvar.IntValue & 0x000000FF) >>  0) & 0xFF);

    cvar = FindConVar("hostport");
    if(cvar == null)
        SetFailState("hostport is invalid CVar");

    kMessager_InitBuffer();
    kMessager_WriteChars("ip", ip);
    kMessager_WriteInt32("port", cvar.IntValue);
    kMessager_SendBuffer(Server_Load);
}

static void OnServerLoad()
{
    kMessager_ReadChars("hostname", g_Server.m_Hostname, 128);

    g_Server.m_SrvId = kMessager_ReadShort("sid");
    g_Server.m_ModId = kMessager_ReadShort("mid");

    if(g_Server.m_SrvId == -1)
        SetFailState("Wrong Server Id from Json: %d:%d:%s", g_Server.m_SrvId, g_Server.m_ModId, g_Server.m_Hostname);

    Call_StartForward(g_Handle.m_ServerLoaded);
    Call_PushCell(g_Server.m_SrvId);
    Call_PushCell(g_Server.m_ModId);
    Call_Finish();

    OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
    ConVar cvar = null;
    if(GetEngineVersion() == Engine_CSGO)
    {
        cvar = FindConVar("host_name_store");
        if(cvar != null)
            cvar.SetInt(1, false, false);
    }

    cvar = FindConVar("hostname");
    if(cvar != null)
        cvar.SetString(g_Server.m_Hostname, false, false);
    
    char password[24];
    RandomString(password, 24);
    FindConVar("rcon_password").SetString(password);
}

static void resetClient(int client)
{
    g_Client[client].m_PId          = 0;
    g_Client[client].m_TId          = 0;
    g_Client[client].m_FirstJoin    = 0;
    g_Client[client].m_LastSeen     = 0;
    g_Client[client].m_Connections  = 0;
    g_Client[client].m_Onlinetimes  = 0;
    g_Client[client].m_SignInTimes  = 0;
    g_Client[client].m_SignInDate   = 0;
    g_Client[client].m_SignInKeep   = 0;
    g_Client[client].m_PlayTotal    = 0;
    g_Client[client].m_SpecTotal    = 0;
    g_Client[client].m_AliveTime    = 0;
    
    g_IStats[client].m_ConnectTime = 0;
    g_IStats[client].m_PlayTotal   = 0;
    g_IStats[client].m_SpecTotal   = 0;
    g_IStats[client].m_AliveTime   = 0;
    
    g_iTimeout[client] = 0;
}

public void OnClientConnected(int client)
{
    resetClient(client);

    g_IStats[client].m_ConnectTime = GetTime();
}

public void OnClientPutInServer(int client)
{
    if(!ClientIsValid(client))
        return;

    char steamid[32];
    if(!GetClientAuthId(client, AuthId_SteamID64, steamid, 32, true) && !IsClientInKickQueue(client))
    {
        KickClient(client, "Invalid Steam Account!");
        return;
    }

    kMessager_InitBuffer();
    kMessager_WriteChars("steamid", steamid);
    kMessager_SendBuffer(Stats_LoadUser);

    g_Timers[client].m_Load = CreateTimer(30.0, Timer_LoadTimeout, client);
    g_Timers[client].m_Stat = CreateTimer( 1.0, Timer_TrackStats,  client, TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
    // timers
    StopTimer(g_Timers[client].m_Load);
    StopTimer(g_Timers[client].m_Sign);
    StopTimer(g_Timers[client].m_Stat);

    if(g_Client[client].m_PId <= 0)
        return;

    RemoveFromCache(client);

    int duraton = GetTime() - g_IStats[client].m_ConnectTime;
    if(duraton > 10800) duraton = 10800;

    kMessager_InitBuffer();
    kMessager_WriteInt32("pid",         g_Client[client].m_PId);
    kMessager_WriteInt32("tid",         g_Client[client].m_TId);
    kMessager_WriteInt32("connected",   g_IStats[client].m_ConnectTime);
    kMessager_WriteInt32("duration",    duraton);
    kMessager_WriteInt32("play",        g_IStats[client].m_PlayTotal);
    kMessager_WriteInt32("spec",        g_IStats[client].m_SpecTotal);
    kMessager_WriteInt32("alive",       g_IStats[client].m_AliveTime);
    kMessager_SendBuffer(Stats_Update);
}

public void OnClientDisconnect_Post(int client)
{
    // Reset
    resetClient(client);
}

static void OnClientLoad()
{
    char steamid[32];
    kMessager_ReadChars("steamid", steamid, 32);
    
    int client = FindClientBySteamId(AuthId_SteamID64, steamid, false);
    if(client == -1)
        return;

    int pid = kMessager_ReadInt32("pid");
    if(pid > 0 && g_Client[client].m_PId == pid)
    {
        // dumplicate
        return;
    }
    else if(pid <= 0)
    {
        StopTimer(g_Timers[client].m_Load);
        CreateTimer(10.0, Timer_ReloadClient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
        return;
    }

    StopTimer(g_Timers[client].m_Load);

    g_Client[client].m_PId          = kMessager_ReadInt32("pid");
    g_Client[client].m_FirstJoin    = kMessager_ReadInt32("firstjoin");
    g_Client[client].m_LastSeen     = kMessager_ReadInt32("lastseen");
    g_Client[client].m_Connections  = kMessager_ReadInt32("connections");
    g_Client[client].m_Onlinetimes  = kMessager_ReadInt32("onlinetimes");
    g_Client[client].m_SignInTimes  = kMessager_ReadShort("signtimes");
    g_Client[client].m_SignInDate   = kMessager_ReadInt32("signdate");
    g_Client[client].m_SignInKeep   = kMessager_ReadShort("signkeep");
    g_Client[client].m_PlayTotal    = kMessager_ReadInt32("playtotal");
    g_Client[client].m_SpecTotal    = kMessager_ReadInt32("spectotal");
    g_Client[client].m_AliveTime    = kMessager_ReadInt32("alivetime");

    Call_StartForward(g_Handle.m_ClientLoaded);
    Call_PushCell(client);
    Call_PushCell(g_Client[client].m_PId);
    Call_Finish();

    char ticket[37];
    A2SFirewall_GetClientTicket(client, ticket, 37);
    
    char map[128];
    GetCurrentMap(map, 128);
    
    if(GetEngineVersion() == Engine_Insurgency)
    {
        ConVar mp_gamemode = FindConVar("mp_gamemode");
        char mode[16];
        mp_gamemode.GetString(mode, 16);
        Format(map, 128, "%s %s", map, mode);
    }

    char ip[24];
    GetClientIP(client, ip, 24, true);

    kMessager_InitBuffer();
    kMessager_WriteInt32("pid",    g_Client[client].m_PId);
    kMessager_WriteInt32("time",   g_IStats[client].m_ConnectTime);
    kMessager_WriteInt32("srvid",  g_Server.m_SrvId);
    kMessager_WriteInt32("modid",  g_Server.m_ModId);
    kMessager_WriteChars("ticket", ticket);
    kMessager_WriteChars("map",    map);
    kMessager_WriteChars("ip",     ip);
    kMessager_SendBuffer(Stats_Analytics);
}

public Action Timer_ReloadClient(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!ClientIsValid(client))
        return Plugin_Stop;
    
    OnClientPutInServer(client);

    return Plugin_Stop;
}

public Action Timer_LoadTimeout(Handle timer, int client)
{
    g_Timers[client].m_Load = null;
    g_iTimeout[client]++;
    if(g_iTimeout[client] > 3)
    {
        KickClient(client, "Failed to Auth SteamID");
        return Plugin_Stop;
    }
    OnClientPutInServer(client);
    return Plugin_Stop;
}

public Action Command_Sign(int client, int args)
{
    if(g_Client[client].m_PId <= 0)
    {
        Chat(client, "{green}你的数据尚未加载完毕.");
        return Plugin_Handled;
    }

    if(g_Client[client].m_SignInDate >= GetToday())
    {
        Chat(client, "{green}你今天已经签过到了.");
        return Plugin_Handled;
    }
    
    if(g_Timers[client].m_Sign != null)
    {
        Chat(client, "{green}你有一个签到请求正在处理中...");
        return Plugin_Handled;
    }

    kMessager_InitBuffer();
    kMessager_WriteInt32("pid", g_Client[client].m_PId);
    kMessager_WriteInt32("online", g_IStats[client].m_PlayTotal);
    kMessager_SendBuffer(Stats_DailySignIn);

    g_Timers[client].m_Sign = CreateTimer(30.0, Timer_SignTimeout, client);

    return Plugin_Handled;
}

static void OnSignInLoad()
{
    int p = kMessager_ReadInt32("pid");

    int client = FindClientByPId(p);
    if(client == -1)
        return;

    StopTimer(g_Timers[client].m_Sign);
    
    if(!kMessager_ReadBoole("result"))
    {
        char error[128];
        kMessager_ReadChars("error", error, 128);
        Chat(client, "{red}%s", error);
        return;
    }

    g_Client[client].m_SignInDate  = GetToday();
    g_Client[client].m_SignInKeep  = kMessager_ReadShort("signkeep");
    g_Client[client].m_SignInTimes = kMessager_ReadShort("signtimes");

    Chat(client, "{green}签到成功, 您已累计签到了{orange}%d天{green} {silver}({green}连续签到{orange}%d天{silver})", g_Client[client].m_SignInTimes, g_Client[client].m_SignInKeep);

    Call_StartForward(g_Handle.m_ClientSignIn);
    Call_PushCell(client);
    Call_PushCell(g_Client[client].m_SignInTimes);
    Call_PushCell(g_Client[client].m_SignInKeep);
    Call_Finish();
}

public Action Timer_SignTimeout(Handle timer, int client)
{
    g_Timers[client].m_Sign = null;
    Chat(client, "{red}签到超时,请稍后再试...");
    return Plugin_Stop;
}

static int FindClientByPId(int pid)
{
    for(int client = MinClients; client <= MaxClients; ++client)
        if(ClientIsValid(client))
            if(g_Client[client].m_PId == pid)
                return client;
    return -1;
}

static void OnClientStat()
{
    int p = kMessager_ReadInt32("pid");
    
    int client = FindClientByPId(p);
    if(client == -1)
        return;

    g_Client[client].m_TId = kMessager_ReadInt32("tid");
}

#define TEAM_US 0
#define TEAM_OB 1
public Action Timer_TrackStats(Handle timer, int client)
{
    if(IsClientInGame(client))
    {
        g_Timers[client].m_Stat = null;
        return Plugin_Stop;
    }

    // global
    g_Client[client].m_Onlinetimes++;

    // Already in game.
    int  m_TeamId = GetClientTeam(client);

    if(m_TeamId == TEAM_US)
        return Plugin_Continue;

    if(m_TeamId == TEAM_OB)
    {
        g_Client[client].m_SpecTotal++;
        g_IStats[client].m_SpecTotal++;
        return Plugin_Continue;
    }

    if(m_TeamId > TEAM_OB)
    {
        g_Client[client].m_PlayTotal++;
        g_IStats[client].m_PlayTotal++;
        
        if(IsPlayerAlive(client))
        {
            g_Client[client].m_AliveTime++;
            g_IStats[client].m_AliveTime++;
        }
        return Plugin_Continue;
    }
    
    // Exception?
    StopTimer(g_Timers[client].m_Stat);
    LogError("[Timer_TrackStats] %L -> %d -> Exception?", client, m_TeamId);

    return Plugin_Stop;
}