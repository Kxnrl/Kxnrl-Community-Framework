#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <kcf_core>
#include <kcf_menu>

public Plugin myinfo = 
{
    name        = "KCF - Menu",
    author      = "Kyle",
    description = "Menuctl of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://kxnrl.com"
};

#include <topmenus>

enum struct Menu_t
{
    TopMenu m_Admin;
    TopMenu m_Users;
};

enum struct Forward_t
{
    Handle m_OnAdminMenuReady;
    Handle m_OnUsersMenuReady;
}

Menu_t g_TopMenu;
Forward_t g_Forward;

#include "menu/admin.sp"
#include "menu/users.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("KCF-Menu");
    
    CreateNative("KCF_Menu_GetAdminMenu", Native_GetAdminMenu);
    CreateNative("KCF_Menu_GetUsersMenu", Native_GetUsersMenu);

    return APLRes_Success;
}

public any Native_GetAdminMenu(Handle plugin, int numParams)
{
    return g_TopMenu.m_Admin;
}

public any Native_GetUsersMenu(Handle plugin, int numParams)
{
    return g_TopMenu.m_Users;
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("adminmenu.phrases");
    
    g_Forward.m_OnAdminMenuReady = CreateGlobalForward("KCF_Menu_OnAdminMenuReady", ET_Ignore, Param_Cell);
    g_Forward.m_OnUsersMenuReady = CreateGlobalForward("KCF_Menu_OnUsersMenuReady", ET_Ignore, Param_Cell);

    RegConsoleCmd("sm_menu",  Command_DisplayMenu);

    RegAdminCmd("sm_admin", Command_DisplayAdminMenu, ADMFLAG_GENERIC);
}

public void OnAllPluginsLoaded()
{
    Admin_Init();
    Users_Init();
}

public Action Command_DisplayMenu(int client, int args)
{
    if(!client) return Plugin_Handled;
    
    g_TopMenu.m_Users.Display(client, TopMenuPosition_Start);
    
    return Plugin_Handled;
}

public Action Command_DisplayAdminMenu(int client, int args)
{
    if(!client) return Plugin_Handled;

    g_TopMenu.m_Admin.Display(client, TopMenuPosition_Start);

    return Plugin_Handled;
}