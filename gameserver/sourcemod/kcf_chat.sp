#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <kcf_core>
#include <kcf_bans>

public Plugin myinfo = 
{
    name        = "KCF - Base Chat",
    author      = "Kyle",
    description = "Base chat of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://kxnrl.com"
};

EngineVersion g_Engine = Engine_Unknown;
Handle g_hSyncHud = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("KCF-Chat");
    return APLRes_Success;
}

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{orange}管理员频道{white}]");
    SMUtils_SetChatSpaces("   ");
    SMUtils_SetChatConSnd(false);

    g_hSyncHud = CreateHudSynchronizer();
    
    g_Engine = GetEngineVersion();
    
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
    if(g_Engine == Engine_Insurgency)
    {
        Chat(client, "当前游戏引擎不支持ASay");
        return;
    }

    SetHudTextParams(-1.0, 0.225, 8.0, 255, 0, 0, 255, 1, 5.0, 1.0, 2.0);

    for(int target = 1; target <= MaxClients; ++target)
    {
        if(!IsClientInGame(target) || IsFakeClient(target))
            continue;

        ClientCommand(target, "play buttons/button18.wav");
        Chat(target, "{blue}%N{white} :{lightred}   %s", client, message);
        ShowSyncHudText(target, g_hSyncHud, "[管理员频道]  %N\n %s", client, message);
    }
    KCF_Admin_LogAction(client, "asay", "message: %s", message);
}

void Utils_Csay(int client, const char[] message)
{
    if(g_Engine == Engine_CSGO)
        TextAll("<font color='#0066CC'><span class='fontSize-xl'>%N</span></font>\n%s", client, message);
    else
        TextAll("<font color='#0066CC' size='23'>%N</font>\n%s", client, message);
    KCF_Admin_LogAction(client, "csay", "message: %s", message);
}

void Utils_Hsay(int client, const char[] message)
{
    if(g_Engine == Engine_CSGO)
        HintAll("<font color='#0066CC'><span class='fontSize-xl'>%N</span></font>\n%s", client, message);
    else
        HintAll("<font color='#0066CC' size='23'>%N</font>\n%s", client, message);
    KCF_Admin_LogAction(client, "hsay", "message: %s", message);
}

void Utils_Msay(int client, const char[] message)
{
    static Panel panel = null;
    if(panel != null)
        delete panel;
    
    char name[32];
    GetClientName(client, name, 32);
    ReplaceString(name, 32, "#", "?");
    
    char text[256];
    strcopy(text, 256, message);
    ReplaceString(text, 256, "\\n", "\n");

    panel = new Panel();
    
    panel.DrawText("=============================");
    panel.DrawText(name);
    panel.DrawText("=============================");
    panel.DrawText("                             ");
    panel.DrawText("                             ");
    panel.DrawText(text);
    panel.DrawText("                             ");
    panel.DrawText("                             ");
    panel.DrawItem("OK");
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && !IsFakeClient(i))
        {
            panel.Send(i, PanelHandler, 10);
        }
    }
    KCF_Admin_LogAction(client, "msay", "message: %s", message);
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

        PrintToChat(target, "[{silver}发送至管理员{white}]  {yellow}%N{white}:{lightred}  %s", client, message);
    }
    KCF_Admin_LogAction(client, "psay", "message: %s", message);
}