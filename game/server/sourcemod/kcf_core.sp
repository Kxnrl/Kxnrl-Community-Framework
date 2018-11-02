#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <kcf_core>

public Plugin myinfo = 
{
    name        = "Kxnrl Community Framework - Core",
    author      = "Kyle",
    description = "Core Api plugin of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://kxnrl.com"
};


static int g_Client[MAXPLAYERS+1][Client_t];

static int g_iServerId; // Server Id
static int g_iSrvModId; // Server Mod Id

static Database  g_MySQL;

static char g_szHostName[128];
static char g_szDataFile[128];

static Handle g_fwdServerLoaded;
static Handle g_fwdClientLoaded;
static Handle g_fwdClientSigned;

static KeyValues g_KVCache;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("KCF-Core");

    CreateNative("KCF_Core_GetMySQL",        Native_GetMySQL);
    CreateNative("KCF_Core_GetServerId",     Native_GetServerId);
    CreateNative("KCF_Core_GetSrvModId",     Native_GetSrvModId);

    // Clients
    CreateNative("KCF_Core_GetClientUId",    Native_GetUniqueId);
    CreateNative("KCF_Core_GetClientData",   Native_GetDataArray);

    return APLRes_Success;
}

public int Native_GetMySQL(Handle plugin, int numParams)
{
    return view_as<int>(g_MySQL);
}

public int Native_GetServerId(Handle plugin, int numParams)
{
    return g_iServerId;
}

public int Native_GetSrvModId(Handle plugin, int numParams)
{
    return g_iSrvModId;
}

public int Native_GetUniqueId(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    return g_Client[client][iUniqueId];
}

public int Native_GetDataArray(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if(!ClientIsValid(client, true))
        ThrowNativeError(SP_ERROR_PARAM, "client index %d in invalid.", client);

    if(g_Client[client][iUniqueId] <= 0)
        return false;

    int data[Client_t];
    for(int i = 0; i < view_as<int>(Client_t); ++i)
        data[view_as<Client_t>(i)] = g_Client[client][view_as<Client_t>(i)];

    SetNativeArray(2, data[0], sizeof(data));

    return true;
}

public void OnPluginStart()
{
    SMUtils_SetChatPrefix("\x0CKCF");
    SMUtils_SetChatSpaces("   ");
    SMUtils_SetChatConSnd(true);

    g_fwdServerLoaded = CreateGlobalForward("KCF_OnServerLoaded",  ET_Ignore, Param_Cell, Param_Cell);
    g_fwdClientLoaded = CreateGlobalForward("KCF_OnClientLoaded",  ET_Ignore, Param_Cell, Param_Cell);
    g_fwdClientSigned = CreateGlobalForward("KCF_OnClientSigned",  ET_Ignore, Param_Cell, Param_Cell);

    CreateTimer(1.0, Timer_ReconnectToDatabase, 0);

    RegConsoleCmd("sm_sign",    Command_Sign);
    RegConsoleCmd("sm_qiandao", Command_Sign);
    
    BuildPath(Path_SM, g_szDataFile, 128, "data/com.kxnrl.kcf.core.playerdata.kv");

    for(int client = 1; client <= MaxClients; ++client)
        if(ClientIsValid(client))
        {
            OnClientConnected(client);
            OnClientPostAdminCheck(client);
        }
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
        cvar.SetString(g_szHostName, false, false);
}

public Action Timer_ReconnectToDatabase(Handle timer, int retry)
{
    if(g_MySQL != null)
    {
        PrintToServer("Database connected!");
        return Plugin_Stop;
    }

    Database.Connect(MySQL_OnConnected, "kxnrl", retry);

    return Plugin_Stop;
}

public void MySQL_OnConnected(Database db, const char[] error, int retry)
{
    if(db == null)
    {
        LogError("Connect failed -> %s", error);
        if(++retry <= 10)
            CreateTimer(5.0, Timer_ReconnectToDatabase, retry);
        else
            SetFailState("connect to database failed! -> %s", error);
        return;
    }

    g_MySQL = db;
    g_MySQL.SetCharset("utf8");

    PrintToServer("Database connected!");

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

    char m_szQuery[128];
    FormatEx(m_szQuery, 128, "SELECT * FROM `kcf_servers` WHERE `ip`='%s' AND `port`='%d';", ip, cvar.IntValue);
    LogSQL(m_szQuery);
    g_MySQL.Query(MySQL_ServerDataCallback, m_szQuery, _, DBPrio_High);
}

public void MySQL_ServerDataCallback(Database db, DBResultSet results, const char[] error, any unuse)
{
    if(results == null || error[0])
    {
        if(StrContains(error, "lost connection", false) == -1)
        {
            SetFailState("Query Server Info: %s", error);
            return;
        }

        ConVar cvar = null;

        cvar = FindConVar("hostip");
        if(cvar == null)
            SetFailState("hostip is invalid CVar");

        char ip[24];
        FormatEx(ip, 24, "%d.%d.%d.%d", ((cvar.IntValue & 0xFF000000) >> 24) & 0xFF, ((cvar.IntValue & 0x00FF0000) >> 16) & 0xFF, ((cvar.IntValue & 0x0000FF00) >>  8) & 0xFF, ((cvar.IntValue & 0x000000FF) >>  0) & 0xFF);

        cvar = FindConVar("hostport");
        if(cvar == null)
            SetFailState("hostport is invalid CVar");

        char m_szQuery[128];
        FormatEx(m_szQuery, 128, "SELECT * FROM `kcf_servers` WHERE `ip`='%s' AND `port`='%d';", ip, cvar.IntValue);

        DataPack pack = new DataPack();
        pack.WriteFunction(MySQL_ServerDataCallback);
        pack.WriteCell(strlen(m_szQuery)+1);
        pack.WriteString(m_szQuery);
        pack.WriteCell(unuse);
        pack.WriteCell(DBPrio_High);
        CreateTimer(1.0, Timer_SQLQueryDelay, pack);
        return;
    }

    if(!results.FetchRow())
    {
        SetFailState("Not Found this server in database");
        return;
    }

    g_iServerId = results.FetchInt(0);
    g_iSrvModId = results.FetchInt(1);
    results.FetchString(2, g_szHostName, 128);

    char password[24];
    RandomString(password, 24);
    FindConVar("rcon_password").SetString(password);

    char m_szQuery[128];
    FormatEx(m_szQuery, 128, "UPDATE `kcf_servers` SET `rcon`='%s' WHERE `sid`='%d';", password, g_iServerId);
    LogSQL(m_szQuery);
    g_MySQL.Query(MySQL_UpdatePasswordCallback, m_szQuery, _, DBPrio_High);
}

public void MySQL_UpdatePasswordCallback(Database db, DBResultSet results, const char[] error, any unuse)
{
    if(results == null || error[0])
        LogError("Update RCon password: %s", error);

    Call_StartForward(g_fwdServerLoaded);
    Call_PushCell(g_iServerId);
    Call_PushCell(g_iSrvModId);
    Call_Finish();
    
    OnConfigsExecuted();
    CheckKeyValueCache();
    
    PrintToServer("Server Started! -> %d:%d", g_iSrvModId, g_iServerId);
}

public Action Timer_SQLQueryDelay(Handle timer, DataPack pack)
{
    pack.Reset();
    SQLQueryCallback callback = view_as<SQLQueryCallback>(pack.ReadFunction());
    int strsize = pack.ReadCell();
    char[] m_szQuery = new char[strsize];
    pack.ReadString(m_szQuery, strsize);
    any cell = pack.ReadCell();
    DBPriority prio = pack.ReadCell();
    delete pack;

    if(g_MySQL == null)
    {
        LogError("Timer_SQLQueryDelay -> [%s]", m_szQuery);
        return Plugin_Stop;
    }

    LogSQL(m_szQuery);
    g_MySQL.Query(callback, m_szQuery, cell, prio);

    return Plugin_Stop;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    if(g_MySQL == null)
    {
        strcopy(rejectmsg, maxlen, "Server is currently unavailable");
        return false;
    }
    
    return true;
}

public void OnClientConnected(int client)
{
    for(int i = 0; i < view_as<int>(Client_t); ++i)
        g_Client[client][view_as<Client_t>(i)] = -1;
}

public void OnClientPostAdminCheck(int client)
{
    if(!ClientIsValid(client))
        return;

    char steam[32];
    if(!GetClientAuthId(client, AuthId_SteamID64, steam, 32, true) && !IsClientInKickQueue(client))
    {
        KickClient(client, "Invalid Steam Account!");
        return;
    }

    char m_szQuery[128];
    FormatEx(m_szQuery, 128, "SELECT * FROM `kcf_players` WHERE steamid = '%s';", steam);
    LogSQL(m_szQuery);
    g_MySQL.Query(MySQL_LoadClientDataCallback, m_szQuery, GetClientUserId(client), DBPrio_Normal);
}

public void MySQL_LoadClientDataCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!ClientIsValid(client))
        return;

    if(results == null || error[0])
    {
        if(StrContains(error, "lost connection", false) == -1)
        {
            LogError("MySQL_LoadClientDataCallback -> %L -> %s", client, error);
            
            if(!IsClientInKickQueue(client))
                KickClient(client, "SteamId is not allow!");

            return;
        }

        char m_szQuery[128];
        FormatEx(m_szQuery, 128, "SELECT * FROM `kcf_players` WHERE steamid = '%d';", userid);

        DataPack pack = new DataPack();
        pack.WriteFunction(MySQL_LoadClientDataCallback);
        pack.WriteCell(strlen(m_szQuery)+1);
        pack.WriteString(m_szQuery);
        pack.WriteCell(userid);
        pack.WriteCell(DBPrio_High);
        CreateTimer(1.0, Timer_SQLQueryDelay, pack);
        return;
    }

    if(results.RowCount < 1 || !results.FetchRow())
    {
        char steam[32];
        GetClientAuthId(client, AuthId_SteamID64, steam, 32, false);
        
        char m_szQuery[128];
        FormatEx(m_szQuery, 128, "INSERT INTO `kcf_players` (`firstjoin`, `steamid`) VALUES ('%d', '%s');", GetTime(), steam);
        LogSQL(m_szQuery);
        g_MySQL.Query(MySQL_InsertClientDataCallback, m_szQuery, userid, DBPrio_Normal);
        return;
    }

    g_Client[client][iUniqueId] = results.FetchInt(0);

    for(int i = 1; i < view_as<int>(Client_t); ++i)
        g_Client[client][view_as<Client_t>(i)] = results.FetchInt(i+1);

    Call_StartForward(g_fwdClientLoaded);
    Call_PushCell(client);
    Call_PushCell(results.FetchInt(0));
    Call_Finish();
}

public void MySQL_InsertClientDataCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!ClientIsValid(client))
        return;

    if(results == null || error[0])
        LogError("MySQL_InsertClientDataCallback -> %L -> %s", client, error);

    OnClientPostAdminCheck(client);
}

public void OnClientDisconnect(int client)
{
    if(g_Client[client][iUniqueId] <= 0)
        return;

    char steam[32];
    GetClientAuthId(client, AuthId_SteamID64, steam, 32, false);

    char m_szQuery[2048];
    FormatEx(m_szQuery, 2048,  "UPDATE `kcf_players` SET              \
                                `lastseen` = %d,                    \
                                `connections` = `connections` + 1,  \
                                `onlinetimes` = `onlinetimes` + %d  \
                                WHERE                               \
                                    `uid` = %d                      \
                                  AND                               \
                                    `steamid` = '%s';               \
                                ",
                                GetTime(),
                                RoundToFloor(GetClientTime(client)),
                                g_Client[client][iUniqueId],
                                steam
            );

    MySQL_VoidQuery(m_szQuery);

    char m_szAuth[32];
    GetClientAuthId(client, AuthId_Engine, m_szAuth, 32, true);
    
    g_KVCache.Rewind();
    if(g_KVCache.JumpToKey(m_szAuth, false))
    {
        g_KVCache.DeleteThis();
        g_KVCache.Rewind();
        g_KVCache.ExportToFile(g_szDataFile);
    }
}

public void OnClientDisconnect_Post(int client)
{
    for(int i = 0; i < view_as<int>(Client_t); ++i)
        g_Client[client][view_as<Client_t>(i)] = -1;
}

public Action Command_Sign(int client, int args)
{
    if(!(g_Client[client][iUniqueId] > 0))
    {
        Chat(client, "\x04Your data haven't beed loaded yet.");
        return Plugin_Handled;
    }

    if(g_Client[client][iSignDate] >= GetToday())
    {
        Chat(client, "\x04You've already signed.");
        return Plugin_Handled;
    }

    char m_szQuery[256];
    FormatEx(m_szQuery, 256, "UPDATE `kcf_players` SET `signtimes` = `signtimes` + 1, `signdate` = %d WHERE uid = %d", GetToday(), g_Client[client][iUniqueId]);
    LogSQL(m_szQuery);
    g_MySQL.Query(MySQL_SignClientCallback, m_szQuery, GetClientUserId(client), DBPrio_High);

    Chat(client, "\x04Processing your request.");

    return Plugin_Handled;
}

public void MySQL_SignClientCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!ClientIsValid(client))
        return;

    if(results == null || error[0])
    {
        LogError("MySQL_SignClientCallback -> %L -> %s", client, error);
        return;
    }

    g_Client[client][iSignDate]  = GetToday();
    g_Client[client][iSignTimes]++;

    Chat(client, "\x04Sign was successful.");

    Call_StartForward(g_fwdClientSigned);
    Call_PushCell(client);
    Call_PushCell(g_Client[client][iSignTimes]);
    Call_Finish();
}

static void CheckKeyValueCache()
{
    g_KVCache = new KeyValues("PlayerData", "", "");
    g_KVCache.ImportFromFile(g_szDataFile);

    if(!g_KVCache.GotoFirstSubKey(true))
    {
        CreateTimer(1.0, Timer_SaveCacheToKeyValue, _, TIMER_REPEAT);
        return;
    }

    do
    {
        int uniqueId = g_KVCache.GetNum("uniqueid", 0);
        int onlinetk = g_KVCache.GetNum("onlinetk", 0);
        int lastseen = g_KVCache.GetNum("lastseen", GetTime());

        ImportCacheToDatabase(uniqueId, onlinetk, lastseen);
    }
    while(g_KVCache.GotoNextKey(true));

    delete g_KVCache;

    g_KVCache = new KeyValues("PlayerData", "", "");
    g_KVCache.ExportToFile(g_szDataFile);

    CreateTimer(1.0, Timer_SaveCacheToKeyValue, _, TIMER_REPEAT);
}

static void ImportCacheToDatabase(int uid, int online, int lastseen)
{
    char m_szQuery[256];
    FormatEx(m_szQuery, 256,   "UPDATE `kcf_players` SET              \
                                `lastseen` = %d,                    \
                                `connections` = `connections` + 1,  \
                                `onlinetimes` = `onlinetimes` + %d  \
                                WHERE                               \
                                    `uid` = %d                      \
                               ",
                                lastseen,
                                online,
                                uid
            );

    MySQL_VoidQuery(m_szQuery);
}

public Action Timer_SaveCacheToKeyValue(Handle timer)
{
    g_KVCache.Rewind();
    
    int now = GetTime();
    
    char steamid[32];
    for(int client = 1; client <= MaxClients; ++client)
        if(g_Client[client][iUniqueId] > 0)
            if(GetClientAuthId(client, AuthId_Engine, steamid, 32, false))
            {
                g_KVCache.JumpToKey(steamid, true);
                g_KVCache.SetNum("uniqueid", g_Client[client][iUniqueId]);
                g_KVCache.SetNum("onlinetk", RoundToFloor(GetClientTime(client)));
                g_KVCache.SetNum("lastseen", now);

                g_KVCache.Rewind();
            }

    g_KVCache.Rewind();
    g_KVCache.ExportToFile(g_szDataFile);
    
    return Plugin_Continue;
}

static void MySQL_VoidQuery(const char[] m_szQuery)
{
    DataPack pack = new DataPack();
    pack.WriteCell(strlen(m_szQuery)+1);
    pack.WriteString(m_szQuery);
    pack.Reset();

    LogSQL(m_szQuery);
    g_MySQL.Query(MySQL_VoidQueryCallback, m_szQuery, pack, DBPrio_Low);
}

public void MySQL_VoidQueryCallback(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if(results == null || error[0])
    {
        int maxLen = pack.ReadCell();
        char[] m_szQuery = new char[maxLen];
        pack.ReadString(m_szQuery, maxLen);
        
        char path[256];
        BuildPath(Path_SM, path, 256, "logs/MySQL_VoidQueryError.log");
        
        LogToFileEx(path, "----------------------------------------------------------------");
        LogToFileEx(path, "Query: %s", m_szQuery);
        LogToFileEx(path, "Error: %s", error);
    }
    delete pack;
}

static void LogSQL(const char[] buffer)
{
    LogToFileEx("addons/sourcemod/data/MySQL_Query.log", buffer);
}