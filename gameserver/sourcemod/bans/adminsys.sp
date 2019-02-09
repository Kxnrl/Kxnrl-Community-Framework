static StringMap g_smAdminList = null;
static int       g_iAdminId[MAXPLAYERS+1] = {INVALID_AID, ...};
static char      g_szAdminName[MAXPLAYERS+1][32];
static bool      g_AdminLoaded = false;
static Handle    g_AdminTimer = null;
static AdminFlag g_FlagBits[26];

void AdmSys_CreateNative()
{
    CreateNative("KCF_Admin_IsAuthAdmin",   Native_IsAuthAdmin);
    CreateNative("KCF_Admin_IsClientAdmin", Native_IsClientAdmin);
    CreateNative("KCF_Admin_GetAdminId",    Native_GetAdminId);
    CreateNative("KCF_Admin_GetAdminName",  Native_GetAdminName);
    CreateNative("KCF_Admin_LogAction",     Native_LogAction);
}

public int Native_IsAuthAdmin(Handle plugin, int numParams)
{
    char authid[32];
    GetNativeString(1, authid, 32);
    return FindAdminId(authid);
}

public int Native_IsClientAdmin(Handle plugin, int numParams)
{
    return (GetAdminId(GetNativeCell(1)) > INVALID_AID);
}

public int Native_GetAdminId(Handle plugin, int numParams)
{
    return GetAdminId(GetNativeCell(1));
}

public int Native_GetAdminName(Handle plugin, int numParams)
{
    char name[32];
    GetAdminName(GetNativeCell(1), name, 32);
    SetNativeString(2, name, GetNativeCell(3), true);
    return 1;
}

public int Native_LogAction(Handle plugin, int numParams)
{
    int aid = GetAdminId(GetNativeCell(1));

    char action[32];
    GetNativeString(2, action, 32);

    char format[256];
    GetNativeString(3, format, 256);

    char message[512];
    FormatNativeString(0, 0, 4, 512, _, message, format);

    kMessager_InitBuffer();
    kMessager_WriteShort("aid", aid);
    kMessager_WriteShort("sid", KCF_Server_GetSrvId());
    kMessager_WriteChars("act", action);
    kMessager_WriteChars("msg", message);
    kMessager_SendBuffer(Ban_LogAdminAction);
}

void AdmSys_Init()
{
    g_smAdminList = new StringMap();

    RegConsoleCmd("sm_who", Command_Who);

    RegServerCmd("reloadadmins", Command_ReloadAdmins);

    CreateTimer(3600.0 * 12.0, Timer_ReloadAdmins, _, TIMER_REPEAT); // 12 hrs

    g_FlagBits['a'-'a'] = Admin_Reservation;
    g_FlagBits['b'-'a'] = Admin_Generic;
    g_FlagBits['c'-'a'] = Admin_Kick;
    g_FlagBits['d'-'a'] = Admin_Ban;
    g_FlagBits['e'-'a'] = Admin_Unban;
    g_FlagBits['f'-'a'] = Admin_Slay;
    g_FlagBits['g'-'a'] = Admin_Changemap;
    g_FlagBits['h'-'a'] = Admin_Convars;
    g_FlagBits['i'-'a'] = Admin_Config;
    g_FlagBits['j'-'a'] = Admin_Chat;
    g_FlagBits['k'-'a'] = Admin_Vote;
    g_FlagBits['l'-'a'] = Admin_Password;
    g_FlagBits['m'-'a'] = Admin_RCON;
    g_FlagBits['n'-'a'] = Admin_Cheats;
    g_FlagBits['o'-'a'] = Admin_Custom1;
    g_FlagBits['p'-'a'] = Admin_Custom2;
    g_FlagBits['q'-'a'] = Admin_Custom3;
    g_FlagBits['r'-'a'] = Admin_Custom4;
    g_FlagBits['s'-'a'] = Admin_Custom5;
    g_FlagBits['t'-'a'] = Admin_Custom6;
    g_FlagBits['z'-'a'] = Admin_Root;
}

void AdmSys_OnServerLoaded()
{
    DumpAdminCache(AdminCache_Admins, true);
    PrintToServer("[KCF-Bans]  Loading Admins list...");
}

void AdmSys_OnClientConnected(int client)
{
    g_iAdminId[client] = INVALID_AID;
    g_szAdminName[client][0] = '\0';
}

void AdmSys_OnClientAuthorized(int client, const char[] auth, const char[] steamid)
{
    g_iAdminId[client] = FindAdminId(steamid);

    if(g_iAdminId[client] == INVALID_AID)
        return;

    AdminId adminId = FindAdminByIdentity(AUTHMETHOD_STEAM, auth);
    if(adminId == INVALID_ADMIN_ID)
    {
        LogError("Admin \"%L\" -> AID[%d] -> INVALID_ADMIN_ID", client, g_iAdminId[client]);
        return;
    }

    adminId.GetUsername(g_szAdminName[client], 32);
}

void AdmSys_OnClientDisconnected(int client)
{
    g_iAdminId[client] = INVALID_AID;
    g_szAdminName[client][0] = '\0';
}

public Action Command_ReloadAdmins(int args)
{
    DumpAdminCache(AdminCache_Admins, true);
    return Plugin_Handled;
}

public void OnRebuildAdminCache(AdminCachePart part)
{
    if(part != AdminCache_Admins || g_AdminTimer != null)
        return;

    g_AdminLoaded = false;

    kMessager_InitBuffer();
    kMessager_WriteInt32("sid",         KCF_Server_GetSrvId());
    kMessager_WriteInt32("mid",         KCF_Server_GetModId());
    kMessager_SendBuffer(Ban_LoadAdmins);

    g_AdminTimer = CreateTimer(30.0, Timer_LoadAdminTimeout);
}

public Action Timer_ReloadAdmins(Handle timer)
{
    DumpAdminCache(AdminCache_Admins, true);
    PrintToServer("[KCF-Bans]  Reloading Admins list...");
    return Plugin_Continue;
}

public Action Timer_LoadAdminTimeout(Handle timer)
{
    g_AdminTimer = null;

    if(g_AdminLoaded)
        return Plugin_Stop;
    
    LogError("Load admins timeout. reloading...");
    OnRebuildAdminCache(AdminCache_Admins);

    return Plugin_Stop;
}

void AdmSys_OnAdminsLoaded()
{
    // flags
    g_AdminLoaded = true;
    StopTimer(g_AdminTimer);

    if(!kMessager_ReadArray())
    {
        LogError("Admins data is not an array?");
        return;
    }
    
    g_smAdminList.Clear();

    char sid[8], mid[8];
    FormatEx(sid, 8, "%d,", KCF_Server_GetSrvId());
    FormatEx(mid, 8, "%d,", KCF_Server_GetModId());

    int aid, imm;
    char name[32], flag[24], steamid[32], authsrv[64], authMod[64];
    do
    {
        aid = kMessager_ReadShort("aid");
        imm = kMessager_ReadShort("immunity");
        
        kMessager_ReadChars("adminName", name,      32);
        kMessager_ReadChars("steamid",   steamid,   32);
        kMessager_ReadChars("flags",     flag,      24);
        kMessager_ReadChars("authSrv",   authsrv,   64);
        kMessager_ReadChars("authMod",   authMod,   64);

        if(!(
            StrContains(authsrv,   sid) > -1 || 
            StrContains(authMod,   mid) > -1 || 
            StrContains(authsrv, "all") > -1 || 
            StrContains(authMod, "all") > -1
           )) continue;

        char steam32[32];
        ConvertToSteamId32(steamid, steam32, 32);

        AdminId admin;

        if((admin = FindAdminByIdentity(AUTHMETHOD_STEAM, steam32)) != INVALID_ADMIN_ID)
        {
            RemoveAdmin(admin);
            admin = INVALID_ADMIN_ID;
        }
        
        if((admin = CreateAdmin(name)) != INVALID_ADMIN_ID)
        {
            if(!admin.BindIdentity(AUTHMETHOD_STEAM, steam32))
            {
                LogError("Unable to bind admin %s to identity %s", name, steam32);
                RemoveAdmin(admin);
                continue;
            }

            admin.ImmunityLevel = imm;

            for (int i = 0; i < strlen(flag); ++i)
            {
                if(flag[i] < 'a' || flag[i] > 'z')
                    continue;
                    
                if(g_FlagBits[flag[i] - 'a'] < Admin_Reservation)
                    continue;

                SetAdminFlag(admin, g_FlagBits[flag[i] - 'a'], true);
            }
        }

        g_smAdminList.SetValue(steamid, aid);
    }
    while (kMessager_NextArray());

    for(int client = MinClients; client <= MaxClients; ++client)
        if(IsClientInGame(client) && !IsFakeClient(client))
        {
            RunAdminCacheChecks(client);
            AdmSys_OnClientConnected(client);
            if(GetClientAuthId(client, AuthId_SteamID64, steamid, 32, false))
                AdmSys_OnClientAuthorized(client, steamid, steamid);
        }
}

public Action Command_Who(int client, int args)
{
    if(!client) return Plugin_Handled;
    
    PrintToConsole(client, "# %8s %8s %40s %40s", "userid", "adminId", "name", "adminName");

    char userid[8], adminid[8], name[32];
    for(int target = MinClients; target <= MaxClients; ++target)
        if(g_iAdminId[target] > INVALID_AID)
        {
            IntToString(GetClientUserId(target), userid, 8);
            IntToString(g_iAdminId[target], adminid, 8);
            GetClientName(client, name, 32);
            PrintToConsole(client, "# %8s %8s %32s %32s", userid, adminid, name, g_szAdminName[target]);
        }

    return Plugin_Handled;
}

// invoker
int GetAdminId(int client)
{
    if(client == 0) return 0;
    return g_iAdminId[client];
}

int GetAdminName(int client, char[] buffer, int maxLen)
{
    if(client == 0) return strcopy(buffer, maxLen, "CAT");
    return strcopy(buffer, maxLen, g_szAdminName[client]);
}

static int FindAdminId(const char[] steamid)
{
    int aid = INVALID_AID;
    g_smAdminList.GetValue(steamid, aid);
    return aid;
}

int FindClientByAId(int aid)
{
    if(aid == 0) return 0;
    for(int target = MinClients; target <= MaxClients; ++target)
        if(g_iAdminId[target] == aid)
            return target;
    return -1;
}