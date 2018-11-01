#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <kcf_core>
#include <kcf_bans>

public Plugin myinfo = 
{
    name        = "Kxnrl Community Framework - Bans",
    author      = "Kyle",
    description = "Banning and Admin system of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://kxnrl.com"
};


#include <adminmenu>

enum ban_f
{
    ban_Client,
    ban_Identity
}

enum ban_t
{
    iTarget,
    iLength,
    iBanType,
    ban_f:banProc,
    bool:bListen,
    String:szAuthId[32],
    String:szReason[256]
}

static any g_eBan[MAXPLAYERS+1][ban_t];

static char g_banType[3][32] = {"全服封禁", "当前模式封禁", "当前服务器封禁"};

static TopMenu g_hTopMenu;

static AdminFlag g_FlagBits[26];

static StringMap g_smUserName;
static StringMap g_smUserIPpt;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("KCF-Bans");

    CreateNative("KCF_Bans_BanClient",       Native_BanClient);
    CreateNative("KCF_Bans_BanIdentity",     Native_BanIdentity);

    return APLRes_Success;
}

public int Native_BanClient(Handle plugin, int numParams)
{
    int admin  = GetNativeCell(1);
    int target = GetNativeCell(2);
    int btype  = GetNativeCell(3);
    int length = GetNativeCell(4);
    char reason[128];
    GetNativeString(5, reason, 128); 

    return Util_BanClient(admin, target, btype, length, reason);
}

bool Util_BanClient(int admin, int target, int btype, int length, const char[] reason)
{
    if(KCF_Core_GetServerId() < 0)
        return false;
    
    Database db = KCF_Core_GetMySQL();
    if(db == null)
    {
        if(ClientIsValid(admin))
        {
            Chat(admin, "数据库当前已离线...");
        }
        LogError("Failed to ban \"%L\" :  Database is unavailable", target);
        return false;
    }

    char ip[24];
    GetClientIP(target, ip, 24, false);

    char steamid[32], name[64], adminNick[64];
    int adminUserId = -1;

    if(admin > 0)
    {
        GetClientAuthId(admin, AuthId_Engine, steamid, 32);
        AdminId aid = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid);
        if(aid == INVALID_ADMIN_ID)
            return false;
        
        aid.GetUsername(name, 64);
        db.Escape(name, adminNick, 64);
        
        adminUserId = KCF_Core_GetClientUId(admin);
        
        GetClientAuthId(target, AuthId_Engine, steamid, 32);
        AdminId bid = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid);
        if(bid != INVALID_ADMIN_ID && aid.ImmunityLevel != 100)
        {
            Chat(admin, "你不能封禁管理员!");
            return false;
        }
    }
    else if(admin == -1)
    {
        strcopy(adminNick, 64, "CAT");
        adminUserId = -1;
    }
    else
    {
        strcopy(adminNick, 64, "Server");
        adminUserId = 0;
    }

    char nickname[128];
    GetClientName(target, name, 64);
    db.Escape(name, nickname, 128);

    char bReason[256];
    db.Escape(reason, bReason, 256);

    if(!GetClientAuthId(target, AuthId_SteamID64, steamid, 32, true))
    {
        LogError("We can not fetch target`s steamid64 -> \"%L\"", target);
        return false;
    }

    char m_szQuery[1024];
    FormatEx(m_szQuery, 1024, "INSERT INTO kcf_bans VALUES (DEFAULT, '%s', '%s', '%s', %d, %d, %d, %d, %d, %d, '%s', '%s', -1);", steamid, ip, nickname, GetTime(), length*60, btype, KCF_Core_GetServerId(), KCF_Core_GetSrvModId(), adminUserId, adminNick, bReason);

    DataPack pack = new DataPack();
    pack.WriteCell(admin);
    pack.WriteCell(GetClientUserId(target));
    pack.WriteCell(btype);
    pack.WriteCell(length);
    pack.WriteString(reason);
    pack.WriteString(m_szQuery);

    db.Query(BanClientCallback, m_szQuery, pack);

    return true;
}

public void BanClientCallback(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    pack.Reset();
    int admin  = pack.ReadCell();
    int target = pack.ReadCell(); target = GetClientOfUserId(target);
    int btype  = pack.ReadCell();
    int length = pack.ReadCell();
    char reason[128];
    pack.ReadString(reason, 128);
    char query[1024];
    pack.ReadString(query, 1024);
    delete pack;

    if(results == null || error[0])
    {
        LogError("User", "BanClientCallback", "SQL Error:  %s -> \n%s", error, query);
        return;
    }

    if(!target || !IsClientConnected(target))
        return;
    
    if(ClientIsValid(admin))
    {
        Chat(admin, "\x0A已成功封禁\01[\x04%N\x01]", target);
    }

    char adminNick[64];
    if(admin > 0)
    {
        char steamid[32];
        GetClientAuthId(admin, AuthId_Engine, steamid, 32);
        AdminId aid = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid);
        if(aid == INVALID_ADMIN_ID)
            return;
        
        aid.GetUsername(adminNick, 64);
        ChatAll("\x05%N\01已被管理员\x04%s\x01封锁, 原因: \x0A%s", target, adminNick, reason);
    }
    else if(admin == -1)
    {
        strcopy(adminNick, 64, "CAT");
        ChatAll("\x05%N\01已被\x04%s\x01封锁, 原因: \x0A%s", target, adminNick, reason);
    }
    else
    {
        strcopy(adminNick, 64, "Server");
        ChatAll("\x05%N\01已被\x04%s\x01封锁, 原因: \x0A%s", target, adminNick, reason);
    }

    char timeExpired[64];
    if(length != 0)
        FormatTime(timeExpired, 64, "%Y.%m.%d %H:%M:%S", GetTime()+length*60);
    else
        FormatEx(timeExpired, 64, "永久封禁");

    char kickReason[256];
    FormatEx(kickReason, 256, "您已被服务器封锁,禁止进入游戏!\n类型: %s\n原因: %s\n到期: %s", g_banType[btype], reason, timeExpired);
    BanClient(target, 10, BANFLAG_AUTHID, kickReason, kickReason);
}

public int Native_BanIdentity(Handle plugin, int numParams)
{
    int admin = GetNativeCell(1);
    
    char steamIdentity[32];
    GetNativeString(2, steamIdentity, 32);

    int btype  = GetNativeCell(3);
    int length = GetNativeCell(4);
    char reason[128];
    GetNativeString(5, reason, 128);
    
    return Util_BanIdentity(admin, steamIdentity, btype, length, reason);
}

bool Util_BanIdentity(int admin, const char[] steamIdentity, int btype, int length, const char[] reason)
{
    if(KCF_Core_GetServerId() < 0)
        return false;
    
    if(strcmp(steamIdentity, "76561198048432253", false) == 0)
        return false;

    Database db = KCF_Core_GetMySQL();
    if(db == null)
    {
        if(ClientIsValid(admin))
        {
            Chat(admin, "数据库当前已离线...");
        }
        LogError("Failed to ban \"%s\" :  Database is unavailable", steamIdentity);
        return false;
    }

    char ip[32], targetName[64];
    int target = FindClientBySteamId(AuthId_SteamID64, steamIdentity);
    if(target != -1)
    {
        GetClientIP(target, ip, 32);

        char _name[32];
        GetClientName(target, _name, 32);
        db.Escape(_name, targetName, 64);
    }
    else
    {
        char steam32[32];
        GetClientAuthId(target, AuthId_Engine, steam32, 32);
        
        char nn[32];
        g_smUserIPpt.GetString(steam32, ip, 32);
        g_smUserName.GetString(steam32, nn, 32);
        db.Escape(nn, targetName, 64);
    }

    char steamid[32], name[64], adminNick[64];
    int adminUserId = -1;
    
    if(admin > 0)
    {
        GetClientAuthId(admin, AuthId_Engine, steamid, 32);
        AdminId aid = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid);
        if(aid == INVALID_ADMIN_ID)
            return false;
        
        aid.GetUsername(name, 64);
        db.Escape(name, adminNick, 64);
        
        adminUserId = KCF_Core_GetClientUId(admin);
    }
    else if(admin == -1)
    {
        strcopy(adminNick, 64, "CAT");
        adminUserId = -1;
    }
    else
    {
        strcopy(adminNick, 64, "Server");
        adminUserId = 0;
    }

    char bReason[256];
    db.Escape(reason, bReason, 256);

    char m_szQuery[1024];
    FormatEx(m_szQuery, 1024, "INSERT INTO kcf_bans VALUES (DEFAULT, '%s', '%s', '%s', %d, %d, %d, %d, %d, %d, '%s', '%s', -1);", steamIdentity, ip, targetName, GetTime(), length*60, btype, KCF_Core_GetServerId(), KCF_Core_GetSrvModId(), adminUserId, adminNick, bReason);

    DataPack pack = new DataPack();
    pack.WriteCell(admin);
    pack.WriteString(steamIdentity);
    pack.WriteCell(btype);
    pack.WriteCell(length);
    pack.WriteString(reason);
    pack.WriteString(m_szQuery);

    db.Query(BanIdentityCallback, m_szQuery, pack);
    
    return true;
}

public void BanIdentityCallback(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    pack.Reset();
    int admin  = pack.ReadCell();
    char steamIdentity[32];
    pack.ReadString(steamIdentity, 32);
    int btype  = pack.ReadCell();
    int length = pack.ReadCell();
    char reason[128];
    pack.ReadString(reason, 128);
    char query[1024];
    pack.ReadString(query, 1024);
    delete pack;

    if(results == null || error[0])
    {
        LogError("User", "BanClientCallback", "SQL Error:  %s -> \n%s", error, query);
        return;
    }
    
    if(ClientIsValid(admin))
    {
        Chat(admin, "\x0A已成功封禁SteamId \01[\x04%s\x01]", steamIdentity);
    }

    int target = FindClientBySteamId(AuthId_SteamID64, steamIdentity);

    if(target < 0 || !IsClientConnected(target))
        return;
    
    char adminNick[64];
    if(admin > 0)
    {
        char steamid[32];
        GetClientAuthId(admin, AuthId_Engine, steamid, 32);
        AdminId aid = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid);
        if(aid == INVALID_ADMIN_ID)
            return;
        
        aid.GetUsername(adminNick, 64);
        ChatAll("\x05%N\01已被管理员\x04%s\x01封锁, 原因: \x0A%s", target, adminNick, reason);
    }
    else if(admin == -1)
    {
        strcopy(adminNick, 64, "CAT");
        ChatAll("\x05%N\01已被\x04%s\x01封锁, 原因: \x0A%s", target, adminNick, reason);
    }
    else
    {
        strcopy(adminNick, 64, "Server");
        ChatAll("\x05%N\01已被\x04%s\x01封锁, 原因: \x0A%s", target, adminNick, reason);
    }

    char timeExpired[64];
    if(length != 0)
        FormatTime(timeExpired, 64, "%Y.%m.%d %H:%M:%S", GetTime()+length*60);
    else
        FormatEx(timeExpired, 64, "永久封禁");

    char kickReason[256];
    FormatEx(kickReason, 256, "您已被服务器封锁,禁止进入游戏!\n类型: %s\n原因: %s\n到期: %s", g_banType[btype], reason, timeExpired);
    BanClient(target, 10, BANFLAG_AUTHID, kickReason, kickReason);
}

public void OnPluginStart()
{
    SMUtils_SetChatPrefix("[\x04KCF\x01]");
    SMUtils_SetChatSpaces("    ");
    SMUtils_SetChatConSnd(true);

    g_smUserName = new StringMap();
    g_smUserIPpt = new StringMap();

    RegAdminCmd("sm_ban", Command_Ban, ADMFLAG_BAN);
    RegAdminCmd("sm_cat", Command_CAT, ADMFLAG_ROOT);

    RegServerCmd("reloadadmins", Command_ReloadAdmins);
    
    LoadTranslations("basebans.phrases");
    LoadTranslations("common.phrases");
    
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

public void OnAllPluginsLoaded()
{
    DumpAdminCache(AdminCache_Admins, true);
    PrintToServer("[KCF-Bans]  Loading Admins list...");
}

public Action Command_ReloadAdmins(int args)
{
    DumpAdminCache(AdminCache_Admins, true);
    PrintToServer("[KCF-Bans]  Reloading Admins list...");
    return Plugin_Handled;
}

public void OnRebuildAdminCache(AdminCachePart part)
{
    if(part != AdminCache_Admins)
        return;

    static int times = 0;
    
    Database db = KCF_Core_GetMySQL();
    
    if(db == null)
    {
        CreateTimer(10.0, Timer_ReloadAdmins);
        return;
    }

    char m_szQuery[256];
    FormatEx(m_szQuery, 256, "SELECT a.* FROM kcf_admins a LEFT JOIN kcf_admsrv b ON a.aid = b.aid WHERE b.srv_id = '%d' OR b.mod_id = '%d'", KCF_Core_GetServerId(), KCF_Core_GetSrvModId());
    db.Query(LoadAdminsCallback, m_szQuery, times++);
}

public void LoadAdminsCallback(Database db, DBResultSet results, const char[] error, int times)
{
    if(results == null || error[0])
    {
        LogError("LoadAdminsCallback:  [%d] %s", times, error);
        CreateTimer(300.0, Timer_ReloadAdmins);
        return;
    }

    while(results.FetchRow())
    {
        char name[32], stid[32], auth[32], flag[32];
        
        results.FetchString(1, name, 32);
        results.FetchString(2, stid, 32);
        results.FetchString(3, flag, 32);

        TrimString(name);
        TrimString(stid);
        TrimString(flag);

        int immunity = results.FetchInt(4);

        ConvertSteam64ToSteam32(stid, auth, 32);

        AdminId admin;
        
        if((admin = FindAdminByIdentity(AUTHMETHOD_STEAM, auth)) != INVALID_ADMIN_ID)
        {
            RemoveAdmin(admin);
            admin = INVALID_ADMIN_ID;
        }

        if((admin = CreateAdmin(name)) != INVALID_ADMIN_ID)
        {
            if(!admin.BindIdentity(AUTHMETHOD_STEAM, auth))
            {
                LogError("Unable to bind admin %s to identity %s", name, auth);
                RemoveAdmin(admin);
                continue;
            }

            if(strcmp(stid, "76561198048432253", false) != 0 && immunity >= 99)
                immunity -= 20;

            admin.ImmunityLevel = immunity;

            for (int i = 0; i < strlen(flag); ++i)
            {
                if(flag[i] < 'a' || flag[i] > 'z')
                    continue;
                    
                if(g_FlagBits[flag[i] - 'a'] < Admin_Reservation)
                    continue;

                SetAdminFlag(admin, g_FlagBits[flag[i] - 'a'], true);
            }
        }
    }
    
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client))
            RunAdminCacheChecks(client);
}

public Action Timer_ReloadAdmins(Handle timer)
{
    DumpAdminCache(AdminCache_Admins, true);
    PrintToServer("[KCF-Bans]  Reloading Admins list...");
    return Plugin_Stop;
}

public Action Command_CAT(int client, int args)
{
    if(args < 2)
    {
        ReplyToCommand(client, "\x04用法\x01: sm_ban <#userid或者名字> <原因>");
        return Plugin_Handled;
    }
    
    int admin = client;

    char buffer[64];
    GetCmdArg(1, buffer, 64);
    int target = FindTarget(client, buffer, true);
    if(target == -1)
    {
        ReplyToCommand(client, "目标无效");
        return Plugin_Handled;
    }

    char reason[256];
    for(int i = 2; i <= args; i++)
    {
        GetCmdArg(i, buffer, 64);
        Format(reason, 256, "%s %s", reason, buffer);
    }

    g_eBan[admin][iTarget]  = target;
    g_eBan[admin][iLength]  = 0;
    g_eBan[admin][iBanType] = 0;
    g_eBan[admin][banProc]  = ban_Client;

    FormatEx(g_eBan[admin][szReason], 256, "CAT: %s", reason);

    Util_BanClient(-1, g_eBan[admin][iTarget], g_eBan[admin][iBanType], g_eBan[admin][iLength], g_eBan[admin][szReason]);

    return Plugin_Handled;
}

public Action Command_Ban(int client, int args)
{
    if(!client)
        return Plugin_Handled;

    if(args < 1)
    {
        Util_ShowBanMemu(client);
        return Plugin_Handled;
    }
    
    if(args < 3)
    {
        Chat(client, "\x04用法\x01: sm_ban <#userid或者名字> <时间(分钟)|0为永久> [原因]");
        return Plugin_Handled;
    }

    int admin = client;

    char buffer[64];
    GetCmdArg(1, buffer, 64);
    int target = FindTarget(client, buffer, true);
    if(target == -1)
    {
        Chat(client, "目标无效");
        return Plugin_Handled;
    }

    GetCmdArg(2, buffer, 64);
    int length = StringToInt(buffer);
    if(length == 0 && client && !(CheckCommandAccess(client, "sm_unban", ADMFLAG_UNBAN|ADMFLAG_ROOT)))
    {
        Chat(client, "你没有永久封禁的权限");
        return Plugin_Handled;
    }

    char reason[256];
    for(int i = 3; i <= args; i++)
    {
        GetCmdArg(i, buffer, 64);
        Format(reason, 256, "%s %s", reason, buffer);
    }

    g_eBan[admin][iTarget] = target;
    g_eBan[admin][iLength] = length;
    g_eBan[admin][banProc] = ban_Client;
    
    strcopy(g_eBan[admin][szReason], 256, reason);

    Util_ShowBanType(admin);

    return Plugin_Handled;
}

public void OnAdminMenuReady(Handle topmenu)
{
    TopMenu menu = TopMenu.FromHandle(topmenu);

    if(menu == g_hTopMenu)
        return;

    g_hTopMenu = menu;

    TopMenuObject player_commands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_PLAYERCOMMANDS);

    if(player_commands != INVALID_TOPMENUOBJECT)
        AddToTopMenu(g_hTopMenu, "sm_ban", TopMenuObject_Item, AdminMenu_Ban, player_commands, "sm_ban", ADMFLAG_BAN);
}

public void AdminMenu_Ban(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if(action == TopMenuAction_DisplayOption)
        FormatEx(buffer, maxlength, "%T", "Ban player", param);
    else if(action == TopMenuAction_SelectOption)
        Util_ShowBanMemu(param);
}

void Util_ShowBanMemu(int admin)
{
    Menu menu = new Menu(MenuHandler_BanMemu);

    menu.SetTitle("%T:", "Ban player", admin);

    AddTargetsToMenu(menu, admin, true, false);

    menu.ExitButton = false;
    menu.Display(admin, 0);
}

public int MenuHandler_BanMemu(Menu menu, MenuAction action, int admin, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        char info[32], name[32];
        int userid, target;

        menu.GetItem(slot, info, 32, _, name, 32);
        userid = StringToInt(info);

        if((target = GetClientOfUserId(userid)) == 0)
        {
            Chat(admin, "该玩家已经离开服务器");
        }
        else
        {
            g_eBan[admin][banProc] = ban_Client;
            g_eBan[admin][iTarget] = target;
            Util_ShowBanTime(admin);
        }
    }
}

void Util_ShowBanTime(int admin)
{
    Menu menu = new Menu(MenuHandler_BanTime);
    
    menu.SetTitle("%T:", "Ban player", admin);

    menu.AddItem("yukiim", "永久", CheckCommandAccess(admin, "sm_unban", ADMFLAG_UNBAN|ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    menu.AddItem("yukiim", "10分钟");
    menu.AddItem("yukiim", "30分钟");
    menu.AddItem("yukiim", "60分钟");
    menu.AddItem("yukiim", "24小时");
    menu.AddItem("yukiim", "72小时");

    menu.ExitButton = false;
    menu.Display(admin, 0);
}

public int MenuHandler_BanTime(Menu menu, MenuAction action, int admin, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        switch(slot)
        {
            case 0: g_eBan[admin][iLength] =    0;
            case 1: g_eBan[admin][iLength] =   10;
            case 2: g_eBan[admin][iLength] =   30;
            case 3: g_eBan[admin][iLength] =   60;
            case 4: g_eBan[admin][iLength] = 1440;
            case 5: g_eBan[admin][iLength] = 4320;
        }

        g_eBan[admin][bListen] = true;
        Chat(admin, "请按Y输入封禁原因!");
    }
}

public Action OnClientSayCommand(int admin, const char[] command, const char[] sArgs)
{
    if(!g_eBan[admin][bListen])
        return Plugin_Continue;
    
    strcopy(g_eBan[admin][szReason], 256, sArgs);
    g_eBan[admin][bListen] = false;
    Util_ShowBanType(admin);
    
    return Plugin_Handled;
}

void Util_ShowBanType(int admin)
{
    Menu menu = new Menu(MenuHandler_BanType);
    
    menu.SetTitle("对象: %N\n时长: %d分钟\n \n请选择封禁模式: \n ", g_eBan[admin][iTarget], g_eBan[admin][iLength]);

    menu.AddItem("yukiim", "全服封禁", CheckCommandAccess(admin, "sm_unban", ADMFLAG_UNBAN|ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    menu.AddItem("yukiim", "模式封禁");
    menu.AddItem("yukiim", "单服封禁");
    
    menu.ExitButton = false;
    menu.Display(admin, 0);
}
 
public int MenuHandler_BanType(Menu menu, MenuAction action, int admin, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        g_eBan[admin][iBanType] = slot;
        switch (g_eBan[admin][banProc])
        {
            case ban_Client:   Util_BanClient(admin, g_eBan[admin][iTarget], g_eBan[admin][iBanType], g_eBan[admin][iLength], g_eBan[admin][szReason]);
            case ban_Identity: Util_BanIdentity(admin, g_eBan[admin][szAuthId], g_eBan[admin][iBanType], g_eBan[admin][iLength], g_eBan[admin][szReason]);
        }
    }
}

public void OnClientAuthorized(int client, const char[] authId)
{
    if(IsFakeClient(client) || IsClientSourceTV(client))
        return;
    
    char steamid[32];
    if(!GetClientAuthId(client, AuthId_SteamID64, steamid, 32, true))
    {
        KickClient(client, "Invalid Steam Id");
        return;
    }

    char name[32];
    GetClientName(client, name, 32);
    g_smUserName.SetString(steamid, name, true);
    
    char ippt[32];
    GetClientIP(client, ippt, 32, true);
    g_smUserIPpt.SetString(steamid, ippt, true);

    char m_szQuery[256];
    FormatEx(m_szQuery, 256, "SELECT bType, bSrv, bSrvMod, bCreated, bLength, bReason, bAdminName, id FROM kcf_bans WHERE steamid = '%s' AND bRemovedBy = -1", steamid);
    KCF_Core_GetMySQL().Query(CheckBanCallback, m_szQuery, GetClientUserId(client));
}

public void CheckBanCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;

    if(results == null || error[0])
    {
        LogError("SQL Error:  %s -> \"%L\"", error, client);
        CreateTimer(2.0, Timer_ReloadBans, client, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }

    if(results.RowCount <= 0)
        return;

    while(results.FetchRow())
    {
        //bType, bSrv, bSrvMod, bCreated, bLength, bReason, id

        char bReason[128], bAdminName[32];
        int bType    = results.FetchInt(0);
        int bSrv     = results.FetchInt(1);
        int bSrvMod  = results.FetchInt(2);
        int bCreated = results.FetchInt(3);
        int bLength  = results.FetchInt(4);
        results.FetchString(5, bReason,     128);
        results.FetchString(6, bAdminName,   32);

        /* process results */
        
        // if ban has expired
        if((GetTime() > (bCreated + bLength)) && bLength > 0)
            continue;

        // if srv ban and current server id != ban server id
        if(bType == 2 && KCF_Core_GetServerId() != bSrv)
            continue;
        
        // if mod ban and current server mod != ban mod id
        if(bType == 1 && KCF_Core_GetSrvModId() != bSrvMod)
            continue;
 
        char ip[32];
        GetClientIP(client, ip, 32);

        SQL_VoidQuery(db, "INSERT INTO kcf_blocks VALUES (DEFAULT, %d, '%s', %d)", results.FetchInt(6), ip, GetTime());

        char timeExpired[64];
        if(bLength != 0)
            FormatTime(timeExpired, 64, "%Y.%m.%d %H:%M:%S", bCreated+bLength);
        else
            FormatEx(timeExpired, 64, "永久封禁");

        char kickReason[256];
        FormatEx(kickReason, 256, "您已被服务器封锁,禁止进入游戏!\n封禁类型:\t%s\n封禁原因:\t%s\n操作人员:\t%s\n到期时间:\t%s", g_banType[bType], bReason, bAdminName, timeExpired);
        BanClient(client, 10, BANFLAG_AUTHID, kickReason, kickReason);

        break;
    }
}

void SQL_VoidQuery(Database db, const char[] buffer, any ...)
{
    char m_szQuery[256];
    VFormat(m_szQuery, 256, buffer, 3);

    DataPack pack = new DataPack();
    pack.WriteString(m_szQuery);
    pack.Reset();

    db.Query(VoidQueryCallback, m_szQuery, pack);
}

public void VoidQueryCallback(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if(results == null || error[0])
    {
        char m_szQuery[256];
        pack.ReadString(m_szQuery, 256);
        LogError("VoidQueryCallback -> %s\n%s", error, m_szQuery);
    }
    
    delete pack;
}

public Action Timer_ReloadBans(Handle timer, int client)
{
    if(!IsClientConnected(client) || !IsClientAuthorized(client))
        return Plugin_Stop;

    OnClientAuthorized(client, "BYPASS");

    return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
    if(!IsClientInGame(client))
        return;
    
    Database db = KCF_Core_GetMySQL();
    
    char auth[32];
    GetClientAuthId(client, AuthId_Engine, auth, 32);
    
    AdminId admin = FindAdminByIdentity(AUTHMETHOD_STEAM, auth);
    if(admin == INVALID_ADMIN_ID)
        return;

    char name[32], nick[64];
    admin.GetUsername(name, 32);
    db.Escape(name, nick, 64);

    SQL_VoidQuery(db, "UPDATE kcf_admins SET lastseen = '%d' WHERE adminName = '%s'", GetTime(), nick);
}
