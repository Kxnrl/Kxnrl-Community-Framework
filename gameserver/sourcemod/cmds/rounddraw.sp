public Action Command_RoundDraw(int client, int args)
{
    if(!client || !g_pCstrike)
        return Plugin_Handled;

    Util_RoundDraw(client);

    return Plugin_Handled;
}

public void AdminMenu_RoundDraw(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if(action == TopMenuAction_DisplayOption)
        strcopy(buffer, maxlength, "RoundDraw");
    else if (action == TopMenuAction_SelectOption)
        Util_RoundDraw(param);
}

static void Util_RoundDraw(int admin)
{
    CS_TerminateRound(12.0, CSRoundEnd_Draw, false);
    LogAction(admin, -1, "\"%L\" 令本局平局", admin);
    ChatAll("{blue}%N {silver}令本局{green}平局", admin);
}