<?php

class Message_Type
{
    const Invalid = 0;

    /* Global */

    // Connections
    const PingPong = 1;
    const Disconnect = 2;

    // Servers
    const Server_Load         = 101;
    // deprecated
    //const Server_Update       = 102;
    const Server_Start        = 103;
    const Server_StartMap     = 104;
    const Server_EndMap       = 105;
    const Server_Query        = 106;

    // Forums
    const Forums_LoadUser     = 201;
    const Forums_LoadAll      = 202;

    // Broadcast
    const Broadcast_Chat      = 301;
    const Broadcast_Admin     = 302;
    const Broadcast_QQBot     = 303;
    const Broadcast_Wedding   = 304;
    const Broadcast_Other     = 305;

    // Baning
    const Ban_LoadAdmins      = 401;
    const Ban_LoadAllBans     = 402;
    const Ban_CheckUser       = 403;
    const Ban_InsertIdentity  = 404;
    const Ban_InsertComms     = 405;
    const Ban_UnbanIdentity   = 406;
    const Ban_UnbanComms      = 407;
    const Ban_RefreshAdmins   = 408;
    const Ban_LogAdminAction  = 409;
    const Ban_LogBlocks       = 410;

    // Couples
    const Couple_LoadAll      = 501;
    const Couple_LoadUser     = 502;
    const Couple_Update       = 503;
    const Couple_Wedding      = 504;
    const Couple_Divorce      = 505;
    const Couple_MarriageSeek = 506;

    /* VIP/Donator */
    const Vip_LoadUser        = 601;
    const Vip_LoadAll         = 602;
    const Vip_FromClient      = 603;

    /* Client */
    const Client_ForwardUser  = 701;
    const Client_HeartBeat    = 702;
    const Client_S2S          = 703;

    /* Analytics */
    
    // Global
    const Stats_LoadUser      = 1001;
    const Stats_Analytics     = 1002;
    const Stats_Update        = 1003;
    const Stats_DailySignIn   = 1004; // todo

    // CSGO->MiniGames
    const Stats_MG_LoadUser   = 1101;
    const Stats_MG_Update     = 1102;
    const Stats_MG_Session    = 1103;
    const Stats_MG_Trace      = 1104;
    const Stats_MG_Ranking    = 1105;
    const Stats_MG_Details    = 1106;

    // CSGO->ZombieEscape
    const Stast_ZE_LoadUser   = 1111;
    const Stast_ZE_Update     = 1112;
    const Stats_ZE_Session    = 1113;
    const Stats_ZE_Ranking    = 1114;
    const Stats_ZE_Details    = 1115;

    // CSGO->TTT
    const Stats_TT_LoadUser   = 1121;
    const Stats_TT_Update     = 1122;
    const Stats_TT_Session    = 1123;

    // L4D2->V
    const Stats_L2_LoadUser   = 1201;
    const Stats_L2_Update     = 1202;
    const Stats_L2_Session    = 1203;

    // INS->PVP
    const Stats_IS_LoadUser   = 1301;
    const Stats_IS_Update     = 1302;
    const Stats_IS_Session    = 1303;
    const Stats_IS_Ranking    = 1304;
    const Stats_IS_Trace      = 1305;
    const Stats_IS_LoadAll    = 1306;

    // End
    const MaxMessage          = 2000;
};

?>