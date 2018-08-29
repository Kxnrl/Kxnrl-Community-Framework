static int _iTarget[MAXPLAYERS+1];
static int _iTPType[MAXPLAYERS+1];

public Action Command_Teleport(int client, int args)
{
    if(!client)
        return Plugin_Handled;
    
    Util_ShowTeleportMenu(client);

    return Plugin_Handled;
}

public void AdminMenu_Teleport(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if(action == TopMenuAction_DisplayOption)
        strcopy(buffer, maxlength, "Teleport");
    else if (action == TopMenuAction_SelectOption)
        Util_ShowTeleportMenu(param);
}

static void Util_ShowTeleportMenu(int client)
{
    Menu menu = new Menu(MenuHandler_TeleportType);
    
    menu.SetTitle("Teleport:");
    
    menu.AddItem("1", "传送你到某个玩家");
    menu.AddItem("2", "传送某玩家到你处");
    menu.AddItem("3", "传送玩家A到玩家B");
    menu.ExitBackButton = true;
    
    menu.Display(client, 30);
}

public int MenuHandler_TeleportType(Menu menu, MenuAction action, int admin, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Cancel && slot == MenuCancel_ExitBack && g_hTopMenu != null)
        g_hTopMenu.Display(admin, TopMenuPosition_LastCategory);
    else if(action == MenuAction_Select)
    {
        char info[4];
        menu.GetItem(slot, info, 4);
        Util_ShowTeleporTargetMenu(admin, StringToInt(info));
    }
}

static void Util_ShowTeleporTargetMenu(int client, int type)
{
    Menu menu = new Menu(MenuHandler_TeleportTarget);
    
    _iTPType[client] = type;
    
    switch(type)
    {
        case 1: menu.SetTitle("选择要传送的玩家");
        case 2: menu.SetTitle("选择要传送的玩家");
        case 3: menu.SetTitle("选择要传送的玩家A");
    }

    AddTargetsToMenu(menu, client, true, true);
    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

public int MenuHandler_TeleportTarget(Menu menu, MenuAction action, int client, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Cancel && slot == MenuCancel_ExitBack && g_hTopMenu != null)
        Util_ShowTeleportMenu(client);
    else if(action == MenuAction_Select)
    {
        char info[8];
        menu.GetItem(slot, info, 8);
        _iTarget[client] = StringToInt(info);
        int target = GetClientOfUserId(_iTarget[client]);

        switch(_iTPType[client])
        {
            case 1: Util_TeleportDest(client, client, target);
            case 2: Util_TeleportDest(client, target, client);
            case 3: DisplayAgainMenu(client);
        }
    }
}

void Util_TeleportDest(int admin, int source, int target)
{
    if(!ClientIsAlive(source))
    {
        Chat(admin, "要传送的玩家已经死了或者离开了游戏");
        return;
    }

    if(!ClientIsAlive(target))
    {
        Chat(admin, "要传送的玩家已经死了或者离开了游戏");
        return;
    }

    float fPos[3], fAgl[3];
    GetClientAbsOrigin(target, fPos);
    GetClientEyeAngles(target, fAgl);
    TeleportEntity(source, fPos, fAgl, NULL_VECTOR);

    ChatAll("\x0E%N\x01把\x04%N\x01传送到了\x04%N\x01所在位置.", admin, source, target);
    LogAction(admin, -1, "\"%L\" 传送 \"%L\" 到 \"%L\"", admin, source, target);
}

void DisplayAgainMenu(int client)
{
    int source = GetClientOfUserId(_iTarget[client]);

    Menu menu = new Menu(MenuHandler_TeleportTarget2);

    menu.SetTitle("选择要传送的玩家B");
    
    char uid[8], name[64];
    for(int i = 1; i <= MaxClients; i++)
    {
        if(i == source || !IsClientInGame(i) || !IsPlayerAlive(i))
            continue;

        int userid = GetClientUserId(i);
        IntToString(userid, uid, 8);
        FormatEx(name, 64, "%N (%d)", i, userid);
        menu.AddItem(uid, name);
    }

    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

public int MenuHandler_TeleportTarget2(Menu menu, MenuAction action, int client, int slot)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Cancel && slot == MenuCancel_ExitBack && g_hTopMenu != null)
        Util_ShowTeleportMenu(client);
    else if(action == MenuAction_Select) 
    {
        char info[8];
        menu.GetItem(slot, info, 8);
        Util_TeleportDest(client, GetClientOfUserId(_iTarget[client]), GetClientOfUserId(StringToInt(info)));
    }
}