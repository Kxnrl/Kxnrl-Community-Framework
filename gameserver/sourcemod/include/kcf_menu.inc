#if defined _KCF_Menu_Include_
    #endinput
#endif

#define _KCF_Menu_Include_

native TopMenu KCF_Menu_GetAdminMenu();
native TopMenu KCF_Menu_GetUsersMenu();

forward void KCF_Menu_OnAdminMenuReady(Handle adminMenu);
forward void KCF_Menu_OnUsersMenuReady(Handle usersMenu);

#define ADMIN_PLAYERCOMMAND "m_Player"
#define ADMIN_SERVERCOMMAND "m_Server"
#define ADMIN_PLUGINCOMMAND "m_Plugin"
#define ADMIN_CONFIGCOMMAND "m_Config"
#define ADMIN_VOTINGCOMMAND "m_Voting"

public SharedPlugin __pl_KCF_Bans =
{
    name = "KCF-Menu",
    file = "kcf_menu.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};