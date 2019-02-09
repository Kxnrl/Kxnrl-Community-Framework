#if defined _kMessager_included
    #endinput
#endif
#define _kMessager_included

enum Message_Type
{
    Invalid = 0,

    /* Global */

    // Connections
    PingPong = 1,
    Disconnect = 2,

    // Servers
    Server_Load         = 101,
    Server_Update       = 102,
    Server_Start        = 103,
    Server_StartMap     = 104,
    Server_EndMap       = 105,
    Server_Query        = 106,

    // Forums
    Forums_LoadUser     = 201,
    Forums_LoadAll      = 202,

    // Broadcast
    Broadcast_Chat      = 301,
    Broadcast_Admin     = 302,
    Broadcast_QQBot     = 303,
    Broadcast_Wedding   = 304,
    Broadcast_Other     = 305,

    // Baning
    Ban_LoadAdmins      = 401,
    Ban_LoadAll         = 402,
    Ban_CheckUser       = 403,
    Ban_InsertIdentity  = 404,
    Ban_InsertComms     = 405,
    Ban_UnbanIdentity   = 406,
    Ban_UnbanComms      = 407,
    Ban_RefreshAdmins   = 408,
    Ban_LogAdminAction  = 409,
    Ban_LogBlocks       = 410,

    // Couples
    Couple_LoadAll      = 501,
    Couple_LoadUser     = 502,
    Couple_Update       = 503,
    Couple_Wedding      = 504,
    Couple_Divorce      = 505,
    Couple_MarriageSeek = 506,

    /* Analytics */
    
    // Global
    Stats_LoadUser      = 1001,
    Stats_Analytics     = 1002,
    Stats_Update        = 1003,
    Stats_DailySignIn   = 1004,

    // CSGO->MiniGames
    Stats_MG_LoadUser   = 1101,
    Stats_MG_Update     = 1102,
    Stats_MG_Session    = 1103,
    Stats_MG_Trace      = 1104,
    Stats_MG_Ranking    = 1105,
    Stats_MG_Details    = 1106,

    // CSGO->ZombieEscape
    Stast_ZE_LoadUser   = 1111,
    Stast_ZE_Update     = 1112,
    Stats_ZE_Session    = 1113,
    Stats_ZE_Ranking    = 1114,
    Stats_ZE_Details    = 1115,

    // CSGO->TTT
    Stats_TT_LoadUser   = 1121,
    Stats_TT_Update     = 1122,
    Stats_TT_Session    = 1123,

    // L4D2->V
    Stats_L2_LoadUser   = 1201,
    Stats_L2_Update     = 1202,
    Stats_L2_Session    = 1203,

    // INS->PVP
    Stats_IS_LoadUser   = 1301,
    Stats_IS_Update     = 1302,
    Stats_IS_Session    = 1303,
    Stats_IS_Ranking    = 1304,
    Stats_IS_Trace      = 1305,
    Stats_IS_LoadAll    = 1306,

    // End
    MaxMessage = 2000
};

// @return if connection is established.
native bool Native_IsConnected();

// @buffer to send
native bool kMessager_InitBuffer();
native bool kMessager_WriteShort(const char[] key, int          _short);
native bool kMessager_WriteInt32(const char[] key, int          _int32);
native bool kMessager_WriteInt64(const char[] key, const char[] _int64);
native bool kMessager_WriteFloat(const char[] key, float        _float);
native bool kMessager_WriteBoole(const char[] key, bool         _boole);
native bool kMessager_WriteChars(const char[] key, const char[] _chars);
native bool kMessager_SendBuffer(Message_Type type);

// @buffer to read
native int   kMessager_ReadShort(const char[] key);
native int   kMessager_ReadInt32(const char[] key);
native bool  kMessager_ReadInt64(const char[] key, char[] buffer, int maxLen);
native float kMessager_ReadFloat(const char[] key);
native bool  kMessager_ReadBoole(const char[] key);
native bool  kMessager_ReadChars(const char[] key, char[] buffer, int maxLen);
native bool  kMessager_ReadArray();
native bool  kMessager_ReadLists();
native bool  kMessager_NextArray();

// @global forward
forward void kMessager_OnRecv(Message_Type type);

public Extension __ext_kMessager = 
{
    name = "kMessager",
    file = "kxnrl.messager.ext",
#if defined AUTOLOAD_EXTENSIONS
    autoload = 1,
#else
    autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_kMessager_SetNTVOptional()
{
    MarkNativeAsOptional("Native_IsConnected");

    MarkNativeAsOptional("kMessager_InitBuffer");
    MarkNativeAsOptional("kMessager_WriteShort");
    MarkNativeAsOptional("kMessager_WriteInt32");
    MarkNativeAsOptional("kMessager_WriteInt64");
    MarkNativeAsOptional("kMessager_WriteFloat");
    MarkNativeAsOptional("kMessager_WriteChars");
    MarkNativeAsOptional("kMessager_SendBuffer");

    MarkNativeAsOptional("kMessager_ReadShort");
    MarkNativeAsOptional("kMessager_ReadInt32");
    MarkNativeAsOptional("kMessager_ReadInt64");
    MarkNativeAsOptional("kMessager_ReadFloat");
    MarkNativeAsOptional("kMessager_ReadChars");
}
#endif