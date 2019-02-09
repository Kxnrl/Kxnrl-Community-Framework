#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <kcf_core>
#undef REQUIRE_PLUGIN
#include <kcf_menu>
#define REQUIRE_PLUGIN

public Plugin myinfo = 
{
    name        = "KCF - Cmds",
    author      = "Kyle",
    description = "Commands of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://kxnrl.com"
};

#undef REQUIRE_EXTENSIONS
#include <topmenus>
#include <cstrike>
#define REQUIRE_EXTENSIONS

bool g_pCstrike;
//bool g_pTopMenu;

TopMenu g_hTopMenu;

#include "cmds/slay.sp"
#include "cmds/teleport.sp"
#include "cmds/rounddraw.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("KCF-Cmds");
    return APLRes_Success;
}

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");
    SMUtils_SetChatConSnd(false);

    LoadTranslations("common.phrases");
    LoadTranslations("playercommands.phrases");

    RegAdminCmd("sm_slay",      Command_Slay,       ADMFLAG_SLAY);
    RegAdminCmd("sm_rounddraw", Command_RoundDraw,  ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_teleport",  Command_Teleport,   ADMFLAG_SLAY);
    
    g_pCstrike = LibraryExists("cstrike");
    //g_pTopMenu = LibraryExists("TopMenus");
}

public void KCF_Menu_OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

    if(topmenu == g_hTopMenu)
        return;

    g_hTopMenu = topmenu;

    TopMenuObject player_commands = g_hTopMenu.FindCategory(ADMIN_PLAYERCOMMAND);
    TopMenuObject server_commands = g_hTopMenu.FindCategory(ADMIN_SERVERCOMMAND);

    if(player_commands != INVALID_TOPMENUOBJECT)
    {
        g_hTopMenu.AddItem("sm_slay",       AdminMenu_Slay,      player_commands, "sm_slay",      ADMFLAG_SLAY);
        g_hTopMenu.AddItem("sm_teleport",   AdminMenu_Teleport,  player_commands, "sm_teleport",  ADMFLAG_SLAY);
    }

    if(server_commands != INVALID_TOPMENUOBJECT && g_pCstrike)
    {
        g_hTopMenu.AddItem("sm_rounddraw",  AdminMenu_RoundDraw, player_commands, "sm_rounddraw", ADMFLAG_CHANGEMAP);
    }
}