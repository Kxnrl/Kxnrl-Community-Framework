#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <kcf_core>

public Plugin myinfo = 
{
    name        = "Kxnrl Community Framework - Base Chat",
    author      = "Kyle",
    description = "Base chat of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://kxnrl.com"
};


Handle g_hSyncHud = null;
Panel  g_hMenuHud = null;

public void OnPluginStart()
{
    SMUtils_SetChatPrefix("[\x10管理员频道\x01]");
    SMUtils_SetChatSpaces("   ");
    SMUtils_SetChatConSnd(false);
    
    SMUtils_SetTextDest(HUD_PRINTCENTER);

    g_hSyncHud = CreateHudSynchronizer();
    
    RegAdminCmd("sm_chat", Command_Chat, ADMFLAG_CHAT);
}

public Action Command_Chat(int client, int args)
{
    if(!client)
        return Plugin_Handled;
    
    Chat(client, "管理员喊话用法:");
    Chat(client, "ASay: @内容");
    Chat(client, "CSay: #内容");
    Chat(client, "HSay: $内容");      
    Chat(client, "MSay: %%内容");
    
    return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if(!ClientIsValid(client))
        return Plugin_Continue;
    
    if(strlen(sArgs) <= 3)
        return Plugin_Continue;

    if(strcmp(command, "say", false) == 0)
    {
        if(!CheckCommandAccess(client, "sm_chat", ADMFLAG_CHAT))
            return Plugin_Continue;

        switch(sArgs[0])
        {
            case '@': Utils_Asay(client, sArgs[1]);
            case '#': Utils_Csay(client, sArgs[1]);
            case '$': Utils_Hsay(client, sArgs[1]);
            case '%': Utils_Msay(client, sArgs[1]);
            default : return Plugin_Continue;
        }

        return Plugin_Handled;
    }
    else if (strcmp(command, "say_team", false) == 0 || strcmp(command, "say_squad", false) == 0)
    {
        switch(sArgs[0])
        {
            case '@': Utils_Psay(client, sArgs[1]);
            default : return Plugin_Continue;
        }

        return Plugin_Handled;
    }

    return Plugin_Continue;
}

void Utils_Asay(int client, const char[] message)
{
    SetHudTextParams(-1.0, 0.225, 8.0, 255, 0, 0, 255, 1, 5.0, 1.0, 2.0);

    for(int target = 1; target <= MaxClients; ++target)
    {
        if(!IsClientInGame(target) || IsFakeClient(target))
            continue;

        ClientCommand(target, "play buttons/button18.wav");
        Chat(target, "\x0C%N\x01 :\x07   %s", client, message);
        ShowSyncHudText(target, g_hSyncHud, "[管理员频道]  %N\n %s", client, message);
    }
    
    LogAction(client, -1, "\"%L\" 使用ASAY: %s", client, message);
}

void Utils_Csay(int client, const char[] message)
{
    TextAll("<font color='#0066CC'><span class='fontSize-xl'>%N</span></font>\n%s", client, message);
    LogAction(client, -1, "\"%L\" 使用CSAY: %s", client, message);
}

void Utils_Hsay(int client, const char[] message)
{
    HintAll("<font color='#0066CC'><span class='fontSize-xl'>%N</span></font>\n%s", client, message);
    LogAction(client, -1, "\"%L\" 使用HSAY: %s", client, message);
}

void Utils_Msay(int client, const char[] message)
{
    if(g_hMenuHud != null)
        delete g_hMenuHud;
    
    char name[32];
    GetClientName(client, name, 32);
    ReplaceString(name, 32, "#", "?");
    
    char text[256];
    strcopy(text, 256, message);
    ReplaceString(text, 256, "\\n", "\n");

    g_hMenuHud = new Panel();
    
    g_hMenuHud.DrawText("=============================");
    g_hMenuHud.DrawText(name);
    g_hMenuHud.DrawText("=============================");
    g_hMenuHud.DrawText("                             ");
    g_hMenuHud.DrawText("                             ");
    g_hMenuHud.DrawText(text);
    g_hMenuHud.DrawText("                             ");
    g_hMenuHud.DrawText("                             ");
    g_hMenuHud.DrawItem("OK");
    
    for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			g_hMenuHud.Send(i, PanelHandler, 10);
		}
	}
    
    LogAction(client, -1, "\"%L\" 使用MSAY: %s", client, message);
}

public int PanelHandler(Menu menu, MenuAction action, int param1, int param2)
{

}

void Utils_Psay(int client, const char[] message)
{
    for(int target = 1; target <= MaxClients; ++target)
    {
        if(!IsClientInGame(target) || IsFakeClient(target))
            continue;

        if(!CheckCommandAccess(target, "sm_ban", ADMFLAG_BAN) && target != client)
            continue;

        PrintToChat(target, "[\x0A发送至管理员\x01]  \x05%N\x01:\x07  %s", client, message);
    }
    LogAction(client, -1, "\"%L\" 使用PSAY: %s", client, message);
}