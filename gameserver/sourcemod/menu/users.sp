TopMenuObject g_MenuObj;

void Users_Init()
{
    g_TopMenu.m_Users = new TopMenu(MenuHandler_UsersDefault);
    
    g_MenuObj = g_TopMenu.m_Users.AddItem("m_Admin", MenuHandler_UsersDefault, INVALID_TOPMENUOBJECT, "sm_admin", ADMFLAG_GENERIC);

    Call_StartForward(g_Forward.m_OnUsersMenuReady);
    Call_PushCell(g_TopMenu.m_Users);
    Call_Finish();
}

public void MenuHandler_UsersDefault(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
    if(action == TopMenuAction_DisplayTitle)
    {
        if(topobj_id == g_MenuObj) FormatEx(buffer, maxlength, "管理员菜单");
        else                       FormatEx(buffer, maxlength, "主菜单");
    }
    else if(action == TopMenuAction_DisplayOption)
    {
        if(topobj_id == g_MenuObj) FormatEx(buffer, maxlength, "管理员菜单");
    }
}