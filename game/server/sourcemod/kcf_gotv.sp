#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <kcf_core>

public Plugin myinfo = 
{
    name        = "Kxnrl Community Framework - GOTV",
    author      = "Kyle",
    description = "GOTV and Demo of Kxnrl Community Framework",
    version     = PI_VERSION,
    url         = "https://kxnrl.com"
};


#include <system2>

static ConVar tv_autorecord;
static ConVar tv_enable;

static char g_szDemoName[128];
static bool g_bRecording;
static bool g_bNeedBzip;
static int g_iRecTime;
static Handle g_hInitTimer;

public void OnPluginStart()
{
    SMUtils_SetChatPrefix("[\x04KCF\x01]");
    SMUtils_SetChatSpaces("    ");
    SMUtils_SetChatConSnd(true);

    RegConsoleCmd("sm_demo", Command_Demo);

    tv_enable = FindConVar("tv_enable");
    tv_autorecord = FindConVar("tv_autorecord");

    tv_enable.AddChangeHook(OnConVarChanged);
    tv_autorecord.AddChangeHook(OnConVarChanged);

    CheckRecordingDir();

    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

static void CheckRecordingDir()
{
    if(!DirExists("recording"))
    {
        CreateDirectory("recording", 511);
        return;
    }

    DirectoryListing hDir = OpenDirectory("recording");
    if(hDir == null)
        return;

    FileType type = FileType_Unknown;
    char filename[128];
    while(hDir.GetNext(filename, 128, type))
    {
        if(type != FileType_File)
            continue;

        TrimString(filename);

        if(StrContains(filename, ".dem", false) == -1)
            continue;

        Format(filename, 128, "recording/%s", filename);
        if(DeleteFile(filename))
            LogMessage("Delete invalid demo: %s", filename);
    }
    delete hDir;
}

public void OnPluginEnd() 
{
    StopRecord();
}

public void OnConfigsExecuted()
{
    CheckConVarValue();
    StopTimer(g_hInitTimer);
    g_hInitTimer = CreateTimer(10.0, OnMapStartPost);
}

public void OnMapEnd()
{
    StopTimer(g_hInitTimer);
    StopRecord();
}

public void OnClientDisconnect_Post(int client)
{
    CheckAllowRecord();
}

public void StopRecord()
{
    g_iRecTime = 0;
    g_bRecording = false;
    ServerCommand("tv_stoprecord");
    if(g_bNeedBzip ||  !g_bRecording)
    {
        g_bNeedBzip = false;
        CreateTimer(0.1, Timer_MoveFile);
    }
}

public Action Timer_MoveFile(Handle timer)
{
    char oldfile[128];
    FormatEx(oldfile, 128, "recording/%s.dem", g_szDemoName);

    if(FileExists(oldfile))
    {
        char newfile[128];
        FormatEx(newfile, 128, "recording/bz2/%s.dem.7z", g_szDemoName);
        DataPack pack = new DataPack();
        pack.WriteString(g_szDemoName);
        pack.Reset();
        //LogMessage("CompressFile %s to %s", oldfile, newfile);
        //System2_CompressFile(OnBz2Completed, oldfile, newfile, ARCHIVE_7Z, LEVEL_9, pack);
        System2_Compress(OnBz2Completed, oldfile, newfile, ARCHIVE_7Z, LEVEL_9, pack, false);
    }

    g_szDemoName[0] = '\0';
}

public void OnBz2Completed(bool success, const char[] command, System2ExecuteOutput output, DataPack pack)
{
    pack.Reset();
    char demoname[128];
    pack.ReadString(demoname, 128);

    if(success)
    {
        LogMessage("Bz2 CompressFile %s successful.", demoname);
        char oldfile[128], newfile[128];
        FormatEx(oldfile, 128, "recording/%s.dem", demoname);
        if(!DeleteFile(oldfile))
            LogError("Delete %s failed.", oldfile);
        
        FormatEx(newfile, 128, "recording/bz2/%s.dem.7z", demoname);
        
        if(FileSize(newfile) < 10240000)
        {
            LogMessage("%s is too small, deleted", newfile);
            if(!DeleteFile(newfile))
                LogError("Delete %s failed.", newfile);
            return;
        }
        
        //char remote[256];
        //Format(remote, 256, "/Trouble in Terrorist Town/%s.dem.7z", demoname);
        //PrintToServer("Upload %s to FTP %s", demoname, remote);
        //LogMessage("FTP Upload %s to %s.", demoname, remote);
        //System2_UploadFTPFile(OnFTPUploadCompleted, newfile, remote, "demo.kxnrl.com", "cgftp", "nimasile", 12306, pack);
    }
    else
    {
        LogError("7z CompressFile %s failed.", demoname);

        char oldfile[128];
        FormatEx(oldfile, 128, "recording/%s.dem", demoname);
        if(!DeleteFile(oldfile))
            LogError("Delete %s failed.", oldfile);
    }
    
    delete pack;
}

public void OnFTPUploadCompleted(bool finished, const char[] error, float dltotal, float dlnow, float ultotal, float ulnow, DataPack pack)
{
    pack.Reset();
    char demoname[128];
    pack.ReadString(demoname, 128);

    if(finished)
    {
        char oldfile[128];
        Format(oldfile, 128, "recording/bz2/%s.dem.7z", demoname);
        if(!DeleteFile(oldfile))
            LogError("Delete %s failed.", oldfile);

        LogMessage("FTP Upload %s.dem.7z finished. %s", demoname, error);
        delete pack;
    }
}

public Action OnMapStartPost(Handle timer)
{
    g_hInitTimer = null;

    if(!CheckAllowRecord())
        return Plugin_Stop;

    char time[64], map[64];
    FormatTime(time, 64, "%Y%m%d_%H-%M-%S", GetTime());

    GetCurrentMap(map, 64);

    char exp[2][8];
    ExplodeString(map, "_", exp, 2, 8, true);
    FormatEx(g_szDemoName, 128, "%s_%d_%s_%s", exp[0], KCF_Core_GetServerId(), time, map);

    ServerCommand("tv_record recording/%s.dem", g_szDemoName);

    LogMessage("Recording recording/%s.dem ...", g_szDemoName);

    g_bRecording = true;
    g_bNeedBzip = true;

    CreateTimer(1.0, Timer_RecTime, _, TIMER_REPEAT);
    
    return Plugin_Stop;
}

public Action Timer_RecTime(Handle timer)
{
    if(!g_bRecording)
        return Plugin_Stop;

    g_iRecTime++;

    return Plugin_Continue;
}

public Action Timer_Broadcast(Handle timer)
{    
    ChatAll("\x10DEMO名称\x04[\x0F%s\x04]", g_szDemoName);
    return Plugin_Continue;
}

public Action Command_Demo(int client, int args)
{
    if(!g_bRecording)
    {
        ChatAll("\x04[\x0F目前还未开始录制DEMO\x04]");
        return Plugin_Handled;
    }

    char szTime[32];
    FormatTime(szTime, 32, "%M:%S", g_iRecTime-2);
    ChatAll("\x10DEMO名称\x04[\x0F%s\x04]", g_szDemoName);
    ChatAll("\x10DEMO时间\x04[\x0F%s\x04]", szTime);

    return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool DB)
{    
    if(g_bRecording) CreateTimer(15.0, Timer_Broadcast);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    CheckConVarValue();
}

static void CheckConVarValue()
{
    tv_enable.SetInt(1);
    tv_autorecord.SetInt(0);
}

static bool CheckAllowRecord()
{
    int players;

    for(int i = 1; i <= MaxClients; ++i)
        if(IsClientConnected(i) && !IsFakeClient(i))
            players++;

    if(players < 3)
    {
        StopRecord();
        return false;
    }

    return true;
}