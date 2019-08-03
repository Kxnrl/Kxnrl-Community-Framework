enum ban_t
{
    ban_Client,
    ban_Identity
}

enum struct ban_info_t
{
    int   m_Target;
    int   m_Length;
    int   m_BanType;
    ban_t m_BanProc;
    char  m_AuthId[32];
    char  m_Reason[256];
};

enum struct check_info_t
{
    int  m_Retries;
    bool m_Require;
    bool m_Checked;
    Handle m_Timer;
}

static   ban_info_t g_AdminSelect[MAXPLAYERS+1];
static check_info_t g_BanningInfo[MAXPLAYERS+1];

static char g_banType[4][32] = {"全服封禁", "当前游戏封禁", "当前模式封禁", "当前服务器封禁"};

void BanSys_CreateNative()
{
    CreateNative("KCF_Ban_BanClient",   Native_BanClient);
    CreateNative("KCF_Ban_BanIdentity", Native_BanIdentity);
}

public int Native_BanClient(Handle plugin, int numParams)
{
    int admin  = GetNativeCell(1);
    int target = GetNativeCell(2);
    int btype  = GetNativeCell(3);
    int length = GetNativeCell(4);
    char reason[128];
    GetNativeString(5, reason, 128); 

    return BanSys_BanClient(admin, target, btype, length, reason);
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

    return BanSys_BanIdentity(admin, steamIdentity, btype, length, reason);
}

static bool BanSys_BanClient(int admin, int target, int btype, int length, const char[] reason)
{
    char steamid[32];
    if(!GetClientAuthId(target, AuthId_SteamID64, steamid, 32, true))
    {
        LogError("We can not fetch target's steamid64 -> \"%L\"", target);
        return false;
    }
    
    int aid = GetAdminId(admin);
    
    if(aid == INVALID_AID)
        return false;

    if(admin > 0)
    {
        if(!CanUserTarget(admin, target))
        {
            Chat(admin, "你想干嘛?");
            return false;
        }

        if(GetAdminId(target) != INVALID_AID)
        {
            Chat(admin, "???");
            return false;
        }
    }

    return BanSys_BanIdentity(admin, steamid, btype, length, reason);
}

static bool BanSys_BanIdentity(int admin, const char[] steamid, int btype, int length, const char[] reason, bool check = false)
{
    if(KCF_Server_GetSrvId() < 0)
        return false;
    
    if(check)
    {
        int target = FindClientBySteamId(AuthId_SteamID64, steamid);
        if(target > -1) return BanSys_BanClient(admin, target, btype, length, reason);
    }
    
    int aid = GetAdminId(admin);
    
    if(aid == INVALID_AID)
        return false;

    kMessager_InitBuffer();
    kMessager_WriteInt64("steamid",  steamid);
    kMessager_WriteShort("bLength",  length);
    kMessager_WriteShort("bType",    btype);
    kMessager_WriteShort("bSrv",     KCF_Server_GetSrvId());
    kMessager_WriteShort("bMod",     KCF_Server_GetModId());
    kMessager_WriteShort("bAdminId", aid);
    kMessager_WriteChars("bReason",  reason);
    kMessager_SendBuffer(Ban_InsertIdentity);

    return true;
}

void BanSys_OnIdentityBan()
{
    int aid = kMessager_ReadShort("aid");
    int bid = kMessager_ReadShort("bid");
    int len = kMessager_ReadShort("len");

    int type = kMessager_ReadShort("type");

    char steamid[32];
    kMessager_ReadChars("steamid", steamid, 32);

    char reason[128];
    kMessager_ReadChars("reason", reason, 128);

    // notifaction
    int client = FindClientByAId(aid);
    if(client >= MinClients)
    {
        // ......
        Chat(client, "{green}已成功封禁{red}%s", steamid);

        if(bid == -1)
        {
            Chat(client, "{red}写入数据库失败...", steamid);
            LogError("Failed to ban identity %s", steamid);
        }
    }

    char timeExpired[32], timeLeft[32];
    if(len != 0)
    {
        FormatTime(timeExpired, 32, "%Y.%m.%d %H:%M", GetTime()+len*60);
        FormatEx(timeLeft, 32, "%d分钟", len);
    }
    else
    {
        FormatEx(timeLeft, 32, "有生之年");
        FormatEx(timeExpired, 32, "下辈子");
    }

    int target = FindClientBySteamId(AuthId_SteamID64, steamid);
    if(target != -1)
    {
        char kick[256];
        FormatEx(kick, 256, "您已被服务器封锁,禁止进入游戏!\n类型: %s    到期: %s\n原因: %s", g_banType[type], timeExpired, reason);
        PrintToConsole(client, " \n\n\n\n\n%s\n\n", kick);
        BanClient(target, len, BANFLAG_AUTHID, reason, kick);
        ChatAll("{red}%N{white} 已被服务器封禁. ", target);
        SMUtils_SkipNextPrefix();
        ChatAll("类型: {green}%s", g_banType[type]);
        SMUtils_SkipNextPrefix();
        ChatAll("时长: {green}%s", timeLeft);
        SMUtils_SkipNextPrefix();
        ChatAll("原因: {green}%s", reason);
    }
    else
    {
        char identity[32];
        ConvertToSteamId32(steamid, identity, 32);
        BanIdentity(identity, len, BANFLAG_AUTHID, reason);
    }

    LogMessage("Banned %s for %d minutes", steamid, len);
}

void BanSys_Init()
{
    RegAdminCmd("sm_ban", Command_Ban, ADMFLAG_BAN);
    
    LoadTranslations("basebans.phrases");
    LoadTranslations("common.phrases");
}

void BanSys_OnServerLoaded()
{
    // todo: load all bans
}

void BanSys_OnClientConnected(int client)
{
    g_BanningInfo[client].m_Retries = 0;
    g_BanningInfo[client].m_Require = true;
    g_BanningInfo[client].m_Checked = false;
}

void BanSys_OnClientAuthorized(int client, const char[] auth, const char[] steamid)
{
    if(!g_BanningInfo[client].m_Require)
        return;

    kMessager_InitBuffer();
    kMessager_WriteInt64("steamid",  steamid);
    kMessager_WriteChars("auth",     auth);
    kMessager_WriteShort("bSrv",     KCF_Server_GetSrvId());
    kMessager_WriteShort("bMod",     KCF_Server_GetModId());
    kMessager_SendBuffer(Ban_CheckUser);

    g_BanningInfo[client].m_Timer = CreateTimer(30.0, Timer_CheckTimeout, client);
}

void BanSys_OnClientDisconnected(int client)
{
    StopTimer(g_BanningInfo[client].m_Timer);

    g_BanningInfo[client].m_Retries = 0;
    g_BanningInfo[client].m_Require = false;
    g_BanningInfo[client].m_Checked = false;
}

public Action Command_Ban(int client, int args)
{
    if(!client)
        return Plugin_Handled;

    if(args < 1)
    {
        BanSys_ShowBanMemu(client);
        return Plugin_Handled;
    }

    if(args < 3)
    {
        Chat(client, "{green}用法{white}: sm_ban <#userid或者名字> <时间(分钟)|0为永久> <原因>");
        return Plugin_Handled;
    }

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

    g_AdminSelect[client].m_Target = target;
    g_AdminSelect[client].m_Length = length;
    g_AdminSelect[client].m_BanProc = ban_Client;

    strcopy(g_AdminSelect[client].m_Reason, 256, reason);

    BanSys_ShowBanType(client);

    return Plugin_Handled;
}

void BanSys_ShowBanMemu(int admin)
{
    Menu menu = new Menu(MenuHandler_BanMemu);

    menu.SetTitle("%T:", "Ban player", admin);

    //AddTargetsToMenu(menu, admin, true, false);
    
    char userid[8], name[32], auth[32], buffer[128];
    for(int target = MinClients; target <= MaxClients; ++target)
        if(IsClientInGame(target) && !IsFakeClient(target) && CanUserTarget(admin, target))
        {
            IntToString(GetClientUserId(target), userid, 8);
            GetClientName(target, name, 32);
            GetClientAuthId(target, AuthId_Steam2, auth, 32, false);
            FormatEx(buffer, 128, "(#%4s) %32s [%12s]", userid, name, auth[8]);
            menu.AddItem(userid, buffer);
        }

    //menu.ExitButton = false;
    menu.Display(admin, 0);
}

public int MenuHandler_BanMemu(Menu menu, MenuAction action, int admin, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(slot, info, 32);

        int target = GetClientOfUserId(StringToInt(info));

        if(target == 0)
        {
            // leave
            Chat(admin, "该玩家已经离开服务器");
        }
        else
        {
            g_AdminSelect[admin].m_BanProc = ban_Client;
            g_AdminSelect[admin].m_Target = target;
            BanSys_ShowBanTime(admin);
        }
    }
}

void BanSys_ShowBanTime(int admin)
{
    Menu menu = new Menu(MenuHandler_BanTime);
    
    menu.SetTitle("%T:", "Ban player", admin);

    menu.AddItem("null", "永久", CheckCommandAccess(admin, "sm_unban", ADMFLAG_UNBAN|ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    menu.AddItem("null", "10分钟");
    menu.AddItem("null", "30分钟");
    menu.AddItem("null", "60分钟");
    menu.AddItem("null", "24小时");
    menu.AddItem("null", "72小时");

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
            case 0: g_AdminSelect[admin].m_Length =    0;
            case 1: g_AdminSelect[admin].m_Length =   10;
            case 2: g_AdminSelect[admin].m_Length =   30;
            case 3: g_AdminSelect[admin].m_Length =   60;
            case 4: g_AdminSelect[admin].m_Length = 1440;
            case 5: g_AdminSelect[admin].m_Length = 4320;
        }

        BanSys_ShowReason(admin);
    }
}

void BanSys_ShowReason(int admin)
{
    Menu menu = new Menu(MenuHandler_BanReason);
    
    menu.SetTitle("%T:", "Ban reason", admin);

    menu.AddItem("使用外挂", "使用外挂");
    menu.AddItem("恶意捣乱", "恶意捣乱");
    menu.AddItem("宣传广告", "宣传广告");
    menu.AddItem("骚扰他人", "骚扰他人");
    menu.AddItem("队友伤害", "队友伤害");
    menu.AddItem("破坏规则", "破坏规则");

    menu.ExitButton = false;
    menu.Display(admin, 0);
    
    Chat(admin, "{green}若要使用自定义利用请使用指令");
    Chat(admin, "sm_ban <#userid或者名字> <时间(分钟)|0为永久> <原因>");
}

public int MenuHandler_BanReason(Menu menu, MenuAction action, int admin, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        char reason[32];
        menu.GetItem(slot, reason, 32);
        strcopy(g_AdminSelect[admin].m_Reason, 256, reason);
        BanSys_ShowBanType(admin);
    }
}

void BanSys_ShowBanType(int admin)
{
    Menu menu = new Menu(MenuHandler_BanType);
    
    menu.SetTitle("对象: %N\n时长: %d分钟\n原因: %s\n \n请选择封禁模式: \n ", g_AdminSelect[admin].m_Target, g_AdminSelect[admin].m_Length, g_AdminSelect[admin].m_Reason);

    menu.AddItem("null", "全服封禁", CheckCommandAccess(admin, "sm_unban", ADMFLAG_UNBAN|ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    menu.AddItem("null", "游戏封禁", CheckCommandAccess(admin, "sm_unban", ADMFLAG_UNBAN|ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    menu.AddItem("null", "模式封禁");
    menu.AddItem("null", "单服封禁");

    menu.ExitButton = false;
    menu.Display(admin, 0);
}

public int MenuHandler_BanType(Menu menu, MenuAction action, int admin, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        g_AdminSelect[admin].m_BanType = slot;
        switch (g_AdminSelect[admin].m_BanProc)
        {
            case ban_Client:   BanSys_BanClient(admin, g_AdminSelect[admin].m_Target, g_AdminSelect[admin].m_BanType, g_AdminSelect[admin].m_Length, g_AdminSelect[admin].m_Reason);
            case ban_Identity: BanSys_BanIdentity(admin, g_AdminSelect[admin].m_AuthId, g_AdminSelect[admin].m_BanType, g_AdminSelect[admin].m_Length, g_AdminSelect[admin].m_Reason);
        }
    }
}

void BanSys_OnCheckUser()
{
    char steamid[32];
    kMessager_ReadChars("pid", steamid, 32);

    int client = FindClientBySteamId(AuthId_SteamID64, steamid);
    if(client == -1) return;
    
    StopTimer(g_BanningInfo[client].m_Timer);
    g_BanningInfo[client].m_Checked = true;

    if(!kMessager_ReadBoole("eResult"))
        return;

    int b = kMessager_ReadShort("bid");
    int t = kMessager_ReadShort("bType");
    
    int l = kMessager_ReadInt32("bLength");
    int c = kMessager_ReadInt32("bCreate");

    int offset = l - ((GetTime() -  c) / 60);
    
    if(offset < 0)
    {
        LogError("Recv result bid: %d -> offset: %d", b, offset);
        return;
    }

    char reason[256];
    kMessager_ReadChars("bReason", reason, 256);

    char timeExpired[32];
    if(l != 0)
        FormatTime(timeExpired, 32, "%Y.%m.%d %H:%M", GetTime()+l*60);
    else
        FormatEx(timeExpired, 32, "下辈子");

    char kick[256];
    FormatEx(kick, 256, "您已被服务器封锁,禁止进入游戏!\n类型: %s    到期: %s\n原因: %s", g_banType[t], timeExpired, reason);
    BanClient(client, l, BANFLAG_AUTHID, reason, kick);

    char i[16];
    GetClientIP(client, i, 16, true);

    kMessager_InitBuffer();
    kMessager_WriteShort("bid", b);
    kMessager_WriteChars("adr", i);
    kMessager_SendBuffer(Ban_LogBlocks);
}

public Action Timer_CheckTimeout(Handle timer, int client)
{
    g_BanningInfo[client].m_Timer = null;
    
    if(g_BanningInfo[client].m_Checked)
        return Plugin_Stop;
    
    if(++g_BanningInfo[client].m_Retries > 3)
    {
        KickClient(client, "Failed to check you banning info.\nPlease try again later.");
        return Plugin_Stop;
    }

    char steamid[32];
    GetClientAuthId(client, AuthId_SteamID64, steamid, 32, false);
    BanSys_OnClientAuthorized(client, "null", steamid);

    return Plugin_Stop;
}