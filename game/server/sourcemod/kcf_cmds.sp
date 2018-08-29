#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <kcf_core>

public Plugin myinfo = 
{
    name        = "Kxnrl Community Framework - Cmds",
    author      = "Kyle",
    description = "Commands of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://kxnrl.com"
};


#include <adminmenu>
#include <cstrike>

TopMenu g_hTopMenu;

#include "cmds/slay.sp"
#include "cmds/teleport.sp"
#include "cmds/rounddraw.sp"

public void OnPluginStart()
{
    SMUtils_SetChatPrefix("[\x04KCF\x01]");
    SMUtils_SetChatSpaces("    ");
    SMUtils_SetChatConSnd(false);

    LoadTranslations("common.phrases");
    LoadTranslations("playercommands.phrases");

    RegAdminCmd("sm_slay",      Command_Slay,       ADMFLAG_SLAY);
    RegAdminCmd("sm_rounddraw", Command_RoundDraw,  ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_teleport",  Command_Teleport,   ADMFLAG_SLAY);
}

public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

    if(topmenu == g_hTopMenu)
        return;

    g_hTopMenu = topmenu;

    TopMenuObject player_commands = g_hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
    TopMenuObject server_commands = g_hTopMenu.FindCategory(ADMINMENU_SERVERCOMMANDS);

    if(player_commands != INVALID_TOPMENUOBJECT)
    {
        g_hTopMenu.AddItem("sm_slay",       AdminMenu_Slay,      player_commands, "sm_slay",      ADMFLAG_SLAY);
        g_hTopMenu.AddItem("sm_teleport",   AdminMenu_Teleport,  player_commands, "sm_teleport",  ADMFLAG_SLAY);
    }
    
    if(server_commands != INVALID_TOPMENUOBJECT)
    {
        g_hTopMenu.AddItem("sm_rounddraw",  AdminMenu_RoundDraw, player_commands, "sm_rounddraw", ADMFLAG_CHANGEMAP);
    }
}