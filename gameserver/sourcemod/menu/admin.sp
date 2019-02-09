enum struct MenuObj_t
{
    TopMenuObject m_Player;
    TopMenuObject m_Server;
    TopMenuObject m_Plugin;
    TopMenuObject m_Config;
    TopMenuObject m_Voting;
}

static MenuObj_t g_MenuObj;

void Admin_Init()
{
    g_TopMenu.m_Admin = new TopMenu(MenuHandler_AdminDefault);
    
    g_MenuObj.m_Player = g_TopMenu.m_Admin.AddCategory("m_Player", MenuHandler_AdminDefault, "sm_player", ADMFLAG_GENERIC);
    g_MenuObj.m_Server = g_TopMenu.m_Admin.AddCategory("m_Server", MenuHandler_AdminDefault, "sm_server", ADMFLAG_CONFIG);
    g_MenuObj.m_Plugin = g_TopMenu.m_Admin.AddCategory("m_Plugin", MenuHandler_AdminDefault, "sm_plugin", ADMFLAG_CONFIG);
    g_MenuObj.m_Config = g_TopMenu.m_Admin.AddCategory("m_Config", MenuHandler_AdminDefault, "sm_config", ADMFLAG_CONFIG);
    g_MenuObj.m_Voting = g_TopMenu.m_Admin.AddCategory("m_Voting", MenuHandler_AdminDefault, "sm_voting", ADMFLAG_CONFIG);

    Call_StartForward(g_Forward.m_OnAdminMenuReady);
    Call_PushCell(g_TopMenu.m_Admin);
    Call_Finish();
}

public void MenuHandler_AdminDefault(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
    if(action == TopMenuAction_DisplayTitle)
    {
        if(topobj_id == INVALID_TOPMENUOBJECT)   FormatEx(buffer, maxlength, "管理员菜单");
        else if(topobj_id == g_MenuObj.m_Player) FormatEx(buffer, maxlength, "玩家管理菜单");
        else if(topobj_id == g_MenuObj.m_Plugin) FormatEx(buffer, maxlength, "插件管理菜单");
        else if(topobj_id == g_MenuObj.m_Config) FormatEx(buffer, maxlength, "参数管理菜单");
        else if(topobj_id == g_MenuObj.m_Voting) FormatEx(buffer, maxlength, "投票管理菜单");
        else if(topobj_id == g_MenuObj.m_Server) FormatEx(buffer, maxlength, "服务器管理菜单");
    }
    else if(action == TopMenuAction_DisplayOption)
    {
        if(topobj_id == INVALID_TOPMENUOBJECT)   FormatEx(buffer, maxlength, "管理员菜单");
        else if(topobj_id == g_MenuObj.m_Player) FormatEx(buffer, maxlength, "玩家指令");
        else if(topobj_id == g_MenuObj.m_Plugin) FormatEx(buffer, maxlength, "插件管理");
        else if(topobj_id == g_MenuObj.m_Config) FormatEx(buffer, maxlength, "参数管理");
        else if(topobj_id == g_MenuObj.m_Voting) FormatEx(buffer, maxlength, "投票指令");
        else if(topobj_id == g_MenuObj.m_Server) FormatEx(buffer, maxlength, "服务器管理");
    }
}
