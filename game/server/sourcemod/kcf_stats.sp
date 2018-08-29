#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <kcf_core>

public Plugin myinfo = 
{
    name        = "Kxnrl Community Framework - Stats and Analytics",
    author      = "Kyle",
    description = "Stats and Analytics system of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://kxnrl.com"
};


enum stats_t
{
    iPlayTotal,
    iSpecTotal,
    iPlayOnCT,
    iPlayOnTE,
    iPlayCTAlive,
    iPlayTEAlive
}

static bool g_bLoaded[MAXPLAYERS+1];

static int g_iJoined[MAXPLAYERS+1];
static int g_iUnique[MAXPLAYERS+1];
static int g_TotalDB[MAXPLAYERS+1][stats_t];
static int g_Session[MAXPLAYERS+1][stats_t];

static char    g_szLogFile[128];
static Handle  g_tTracking[MAXPLAYERS+1];
static Database  g_MySQL;
static KeyValues g_KVCache;

#define TEAM_US 0
#define TEAM_OB 1
#define TEAM_TE 2
#define TEAM_CT 3

public void OnPluginStart()
{
    BuildPath(Path_SM, g_szLogFile, 128, "data/com.kxnrl.kcf.stats.playerdata.kv");
}

public void KCF_OnServerLoaded()
{
    g_MySQL = KCF_Core_GetMySQL();
    
    CreateTimer(5.0, Timer_CheckCache);
}

public Action Timer_CheckCache(Handle timer)
{
    g_KVCache = new KeyValues("PlayerData", "", "");
    g_KVCache.ImportFromFile(g_szLogFile);

    if(!g_KVCache.GotoFirstSubKey(true))
    {
        CreateTimer(1.0, Timer_SaveCacheToKeyValue, _, TIMER_REPEAT);
        return Plugin_Stop;
    }

    do
    {
        int uniqueid = g_KVCache.GetNum("uniqueid", 0);

        int playtotal = g_KVCache.GetNum("playtotal", 0);
        int spectotal = g_KVCache.GetNum("spectotal", 0);

        int playonct = g_KVCache.GetNum("playonct", 0);
        int playonte = g_KVCache.GetNum("playonte", 0);
        
        int playoncta = g_KVCache.GetNum("playoncta", 0);
        int playontea = g_KVCache.GetNum("playontea", 0);

        char map[128];
        g_KVCache.GetString("map", map, 128);
        
        char ip[24];
        g_KVCache.GetString("ip", ip, 24);

        int jointime = g_KVCache.GetNum("jointime", 0);
        int duration = g_KVCache.GetNum("duration", 0);

        ImportCacheToDatabase(uniqueid, playtotal, spectotal, playonct, playonte, playoncta, playontea, jointime, duration, ip, map);
    }
    while(g_KVCache.GotoNextKey(true));

    delete g_KVCache;

    g_KVCache = new KeyValues("PlayerData", "", "");
    g_KVCache.ExportToFile(g_szLogFile);

    CreateTimer(1.0, Timer_SaveCacheToKeyValue, _, TIMER_REPEAT);
    
    return Plugin_Stop;
}

static void ImportCacheToDatabase(int uniqueid, int playtotal, int spectotal, int playonct, int playonte, int playoncta, int playontea, int jointime, int duration, const char[] ip, const char[] map)
{
    char m_szQuery[2048];
    FormatEx(m_szQuery, 2048,  "UPDATE `kcf_stats` SET                \
                                `playtotal` = `playtotal` + %d,     \
                                `spectotal` = `spectotal` + %d,     \
                                `playonct`  = `playonct`  + %d,     \
                                `playonte`  = `playonte`  + %d,     \
                                `aliveonct` = `aliveonct` + %d,     \
                                `aliveonte` = `aliveonte` + %d      \
                                WHERE                               \
                                    `uid` = %d;                     \
                               ",
                                playtotal,
                                spectotal,
                                playonct,
                                playonte,
                                playoncta,
                                playontea,
                                uniqueid
            );

    MySQL_VoidQuery(m_szQuery);
    
    FormatEx(m_szQuery, 2048,  "INSERT INTO `kcf_analytics` VALUES (  \
                                DEFAULT,        \
                                %d,             \
                                %d,             \
                                %d,             \
                                %d,             \
                                %d,             \
                                '%s',           \
                                %d,             \
                                '%s'            \
                                );              \
                               ",
                                uniqueid,
                                jointime,
                                GetToday(jointime),
                                KCF_Core_GetServerId(),
                                KCF_Core_GetSrvModId(),
                                map,
                                duration,
                                ip
            );

    MySQL_VoidQuery(m_szQuery);
}

public Action Timer_SaveCacheToKeyValue(Handle timer)
{
    g_KVCache.Rewind();

    char map[128];
    GetCurrentMap(map, 128);
    
    char steamid[32];
    for(int client = 1; client <= MaxClients; ++client)
        if(g_bLoaded[client] && g_iUnique[client] > 0)
            if(GetClientAuthId(client, AuthId_Engine, steamid, 32, false))
            {
                g_KVCache.JumpToKey(steamid, true);
                g_KVCache.SetNum("uniqueid",  g_iUnique[client]);
                g_KVCache.SetNum("playtotal", g_Session[client][iPlayTotal]);
                g_KVCache.SetNum("spectotal", g_Session[client][iSpecTotal]);
                g_KVCache.SetNum("playonct",  g_Session[client][iPlayOnCT]);
                g_KVCache.SetNum("playonte",  g_Session[client][iPlayOnTE]);
                g_KVCache.SetNum("playoncta", g_Session[client][iPlayCTAlive]);
                g_KVCache.SetNum("playontea", g_Session[client][iPlayTEAlive]);

                char ip[24];
                GetClientIP(client, ip, 24, true);
                g_KVCache.SetString("ip",  ip);
                g_KVCache.SetString("map", map);

                g_KVCache.SetNum("jointime", g_iJoined[client]);
                g_KVCache.SetNum("duration", GetClientOnline(client));

                g_KVCache.Rewind();
            }

    g_KVCache.Rewind();
    g_KVCache.ExportToFile(g_szLogFile);
    
    return Plugin_Continue;
}

public void KCF_OnClientLoaded(int client, int uid)
{
    g_iUnique[client] = uid;
    g_iJoined[client] = GetTime();

    char m_szQuery[128];
    Format(m_szQuery, 128, "SELECT * FROM `kcf_stats` WHERE uid = '%d';", g_iUnique[client]);
    LogSQL(m_szQuery);
    g_MySQL.Query(MySQL_LoadClientDataCallback, m_szQuery, GetClientUserId(client));
}

public void MySQL_LoadClientDataCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!ClientIsValid(client))
        return;

    if(results == null || error[0])
    {
        LogError("MySQL_LoadClientDataCallback -> %L -> %s", client, error);
        CreateTimer(2.0, Timer_ReloadClient, userid, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }
    
    if(results.RowCount < 1 || !results.FetchRow())
    {
        char m_szQuery[128];
        FormatEx(m_szQuery, 128, "INSERT INTO `kcf_stats` (`uid`) VALUES ('%d');", g_iUnique[client]);
        LogSQL(m_szQuery);
        g_MySQL.Query(MySQL_InsertClientDataCallback, m_szQuery, userid, DBPrio_Normal);
        return;
    }
    
    for(int i = 0; i < view_as<int>(stats_t); ++i)
        g_TotalDB[client][view_as<stats_t>(i)] = results.FetchInt(i+2);
    
    for(int i = 0; i < view_as<int>(stats_t); ++i)
        g_TotalDB[client][view_as<stats_t>(i)] += g_Session[client][view_as<stats_t>(i)];
    
    g_bLoaded[client] = true;
}

public Action Timer_ReloadClient(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!ClientIsValid(client))
        return Plugin_Stop;
    
    KCF_OnClientLoaded(client, g_iUnique[client]);
    
    return Plugin_Stop;
}

public void MySQL_InsertClientDataCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!ClientIsValid(client))
        return;

    if(results == null || error[0])
        LogError("MySQL_InsertClientDataCallback -> %L -> %s", client, error);

    KCF_OnClientLoaded(client, g_iUnique[client]);
}

public void OnClientPutInServer(int client)
{
    for(int i = 0; i < view_as<int>(stats_t); ++i)
    {
        g_TotalDB[client][view_as<stats_t>(i)] = 0;
        g_Session[client][view_as<stats_t>(i)] = 0;
    }

    g_tTracking[client] = CreateTimer(1.0, Timer_TrackingClient, client, TIMER_REPEAT);
}

public Action Timer_TrackingClient(Handle timer, int client)
{
    int team = GetClientTeam(client);
    
    if(team > TEAM_OB)
    {
        g_TotalDB[client][iPlayTotal]++;
        g_Session[client][iPlayTotal]++;
    }
    else
    {
        g_TotalDB[client][iSpecTotal]++;
        g_Session[client][iSpecTotal]++;
    }
    
    if(team == TEAM_TE)
    {
        g_TotalDB[client][iPlayOnTE]++;
        g_Session[client][iPlayOnTE]++;

        if(IsPlayerAlive(client))
        {
            g_TotalDB[client][iPlayTEAlive]++;
            g_Session[client][iPlayTEAlive]++;
        }
    }
    
    if(team == TEAM_CT)
    {
        g_TotalDB[client][iPlayOnCT]++;
        g_Session[client][iPlayOnCT]++;

        if(IsPlayerAlive(client))
        {
            g_TotalDB[client][iPlayCTAlive]++;
            g_Session[client][iPlayCTAlive]++;
        }
    } 
    
    return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
    StopTimer(g_tTracking[client]);
    
    if(!g_bLoaded[client] || g_iUnique[client] < 1 || g_iJoined[client] < 1 || GetClientOnline(client) > 65535)
        return;

    char m_szQuery[2048];
    FormatEx(m_szQuery, 2048,  "UPDATE `kcf_stats` SET                \
                                `playtotal` = `playtotal` + %d,     \
                                `spectotal` = `spectotal` + %d,     \
                                `playonct`  = `playonct`  + %d,     \
                                `playonte`  = `playonte`  + %d,     \
                                `aliveonct` = `aliveonct` + %d,     \
                                `aliveonte` = `aliveonte` + %d      \
                                WHERE                               \
                                    `uid` = %d                      \
                               ",
                                g_Session[client][iPlayTotal],
                                g_Session[client][iSpecTotal],
                                g_Session[client][iPlayOnCT],
                                g_Session[client][iPlayOnTE],
                                g_Session[client][iPlayCTAlive],
                                g_Session[client][iPlayTEAlive],
                                g_iUnique[client]
            );

    MySQL_VoidQuery(m_szQuery);

    char map[128];
    GetCurrentMap(map, 128);
    
    char ip[24];
    GetClientIP(client, ip, 24, true);

    FormatEx(m_szQuery, 2048,  "INSERT INTO `kcf_analytics` VALUES (  \
                                DEFAULT,        \
                                %d,             \
                                %d,             \
                                %d,             \
                                %d,             \
                                %d,             \
                                '%s',           \
                                %d,             \
                                '%s'            \
                                );              \
                               ",
                                g_iUnique[client],
                                g_iJoined[client],
                                GetToday(g_iJoined[client]),
                                KCF_Core_GetServerId(),
                                KCF_Core_GetSrvModId(),
                                map,
                                GetClientOnline(client),
                                ip
            );

    MySQL_VoidQuery(m_szQuery);

    char m_szAuth[32];
    GetClientAuthId(client, AuthId_Engine, m_szAuth, 32, true);
    
    g_KVCache.Rewind();
    if(g_KVCache.JumpToKey(m_szAuth, false))
    {
        g_KVCache.DeleteThis();
        g_KVCache.Rewind();
        g_KVCache.ExportToFile(g_szLogFile);
    }
}

public void OnClientDisconnect_Post(int client)
{
    g_bLoaded[client] = false;
    g_iUnique[client] = -1;
    g_iJoined[client] = -1;
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

static int GetClientOnline(int client)
{
    return GetTime() - g_iJoined[client];
}

static void LogSQL(const char[] buffer)
{
    char path[256];
    BuildPath(Path_SM, path, 256, "data/MySQL_Query.log");
    LogToFileEx(path, buffer);
}