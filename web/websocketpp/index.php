<?php

define('websocket_server_kxnrl', '~~~~~~~~', true);

ini_set("mysqli.reconnect", "On");

$authed = array();
$global = array();

require_once __DIR__ . '/lib/' . 'configs.inc.php';

function _sprintf($p) {

    print_r($p . PHP_EOL);
}

function _log($l, $p = true) {

    $fp = fopen(__DIR__ . "/errorlog.php", "a+");
    fputs($fp, "<?php exit; ?> [" . date("Y-m-d H:i:s", time()) . "]    " . $l . "\n");
    fclose($fp);

    if ($p) {
        _push($l);
    }
}

function _push($e) {

    global $global, $_config;
    $t = date("Y-m-d H:i:s", time());
    $d = 
<<<EOT
时间: $t  
错误: $e  
数据:  
```json  
{$global['array']}  
```  
EOT;

    $form = array(
        'text' => 'Websocket.service',
        'desp' => $d
    );

    $curl = curl_init();
    curl_setopt($curl, CURLOPT_URL, "https://sc.ftqq.com/" . $_config['sckey'] . ".send");
    curl_setopt($curl, CURLOPT_POST, true);
    curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($curl, CURLOPT_POSTFIELDS, $form);
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
    curl_exec($curl);
    curl_close($curl);
}

function _msg($m) {

    global $global, $_config;
    $t = date("Y-m-d H:i:s", time());
    $d = <<<EOT
时间: $t  
消息: $m
EOT;

    $form = array(
        'text' => 'Websocket.service',
        'desp' => $d
    );

    $curl = curl_init();
    curl_setopt($curl, CURLOPT_URL, "https://sc.ftqq.com/" . $_config['sckey'] . ".send");
    curl_setopt($curl, CURLOPT_POST, true);
    curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($curl, CURLOPT_POSTFIELDS, $form);
    curl_exec($curl);
    curl_close($curl);
}

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

_sprintf("Starting WebSocket Server...");

try {

    $global['kxnrl'] = new Kxnrl();
  //$global['forum'] = new Forum();
    $global['timeQ'] = time();
    $global['isBot'] = -1;

    $server = new swoole_websocket_server("127.0.0.1", 420);

    $server->set(
        [
            'buffer_output_size' => 16 * 1024 * 1024,
            'socket_buffer_size' => 64 * 1024 * 1024,
            'max_connection' => 100,
            'reactor_num' => 4,
            'worker_num' => 4,
            'tcp_fastopen' => true,
        ]
    );

    _msg("Websocket服务启动成功...");

} catch (Exception $e) {

    _sprintf("Failed to create server: " . $e->getMessage());
    die();
}

$server->on('message', function(swoole_websocket_server $_server, $frame) {
    
    global $authed, $global, $_config;

    //if ($frame->opcode == )

    //_sprintf("=============[Received]=============");
    //_sprintf("Data: {$frame->data}");

    $recv = $frame->data;
    if (!isset($authed[$frame->fd]['verify']) || !$authed[$frame->fd]['verify'])
    {
        if (strcmp($recv, $_config['pwkey']) != 0)
        {
            _sprintf("Message Auth: '{$recv}' X");
            $_server->close($frame->fd, false);
            return false;
        }
        _sprintf("Message Auth: {$frame->fd} √");
        $authed[$frame->fd]['verify'] = true;
        return true;
    }

    $array = @json_decode($recv, true);
    if (!isset($array['Message_Type']) || $array['Message_Type'] <= Message_Type::Invalid || $array['Message_Type'] >= Message_Type::MaxMessage)
    {
        _sprintf("=============[Received]=============");
        _sprintf("Data: {$frame->data}");
        return true;
    }

    $global['array'] = json_encode($array, JSON_PRETTY_PRINT);

    $time_t = time();

    if ($global['timeQ']- 60 < $time_t) {

        $global['kxnrl']->ping();
        //$global['forum']->ping();
        $global['timeQ'] = $time_t;
    }

    switch($array['Message_Type'])
    {
        case Message_Type::PingPong:
            $global['kxnrl']->ping();
            //$global['forum']->ping();
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => array('Ping' => 'Pong')
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Disconnect:
            $_server->close($frame->fd, true);
            break;

        case Message_Type::Server_Load:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Server_Load($array['Message_Data']['ip'], $array['Message_Data']['port'])
            );
            $_server->push($frame->fd, json_encode($ret));
            $authed[$frame->fd]['ip'] = $array['Message_Data']['ip'];
            $authed[$frame->fd]['pt'] = $array['Message_Data']['port'];
            break;
        
        case Message_Type::Server_Start:
            // deprecated
            break;

        case Message_Type::Server_StartMap:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Server_StartMap($array['Message_Data']['sid'], $array['Message_Data']['map'])
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Server_EndMap:
            $global['kxnrl']->Server_EndMap($array['Message_Data']['sid'], $array['Message_Data']['tid']);
            break;

        case Message_Type::Server_Query:
            // todo
            break;

        /*
        case Message_Type::Forums_LoadUser:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['forum']->LoadUser($array['Message_Data']['steamid'])
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Forums_LoadAll:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['forum']->LoadAll()
            );
            $_server->push($frame->fd, json_encode($ret));
            break;
        */

        case Message_Type::Broadcast_Chat:
            $servername = $global['kxnrl']->Broadcast_Chat($array['Message_Data']['pid'], $array['Message_Data']['srvid'], $array['Message_Data']['message']);
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => array(
                    'RawMessage' => $array['Message_Data']['RawMessage'],
                    'ServerName' => ((strlen($servername) > 5) ? $servername : "煋")
                )
            );
            $json = json_encode($ret);
            foreach ($_server->connections as $fd)
            {
                if ($fd == $frame->fd) continue;
                $_server->push($fd, $json);
            }
            break;

        case Message_Type::Broadcast_Admin:
            $servername = $global['kxnrl']->Broadcast_Admin($array['Message_Data']['aid'], $array['Message_Data']['sid'], $array['Message_Data']['message']);
            $ret = json_encode(
                array(
                    'RawMessage' => $array['Message_Data']['RawMessage'],
                    'ServerName' => ((strlen($servername) > 5) ? $servername : "煋")
                ),
                true
            );
            foreach ($_server->connections as $fd)
            {
                if ($fd == $frame->fd) continue;
                $_server->push($fd, $ret);
            }
            break;

        case Message_Type::Broadcast_QQBot:
            // 酷Q机器人
            switch ($array['Message_Data']['type'])
            {
                case "toGroup":
                    foreach ($_server->connections as $fd)
                    {
                        if ($global['isBot'] == $fd)
                        {
                            $_server->push($fd, $frame->data);
                        }
                    }
                    break;
                case "toServer":
                    foreach ($_server->connections as $fd)
                    {
                        if ($global['isBot'] != $fd)
                        {
                            $_server->push($fd, $frame->data);
                        }
                    }
                    break;
                case "oAuth":
                    if (strcmp($array['Message_Data']['data'], "CQPBot") == 0) {
                        
                        $global['isBot'] = $frame->fd;

                        _sprintf("CQPBot connected.");
                        _msg("CQPBot connected.");

                        $ret = json_encode(
                            array(
                                'err' => 0,
                                'msg' => "WebSocket connected."
                            ),
                            true
                        );

                        $_server->push($frame->fd, $ret);
                    }
                    break;
            }
            break;

        case Message_Type::Broadcast_Wedding:
            foreach ($_server->connections as $fd)
            {
                $_server->push($fd, $frame->data);
            }
            break;

        case Message_Type::Broadcast_Other:
            // pUnknow
            break;

        case Message_Type::Ban_LoadAdmins:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Ban_LoadAdmins()
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Ban_LoadAllBans:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Ban_LoadAllBans()
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Ban_CheckUser:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Ban_CheckUser($array['Message_Data']['steamid'], $array['Message_Data']['bSrv'], $array['Message_Data']['bMod'])
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Ban_InsertIdentity:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Ban_InsertIdentity($array['Message_Data']['steamid'], $array['Message_Data']['bLength'], $array['Message_Data']['bType'], $array['Message_Data']['bSrv'], $array['Message_Data']['bMod'], $array['Message_Data']['bAdminId'], $array['Message_Data']['bReason'])
            );
            $json = json_encode($ret);
            foreach ($_server->connections as $fd)
            {
                $_server->push($fd, $json);
            }
            break;

        case Message_Type::Ban_InsertComms:
            // todo
            break;

        case Message_Type::Ban_UnbanIdentity:
            // todo
            break;

        case Message_Type::Ban_UnbanComms:
            // todo
            break;

        case Message_Type::Ban_RefreshAdmins:
            $ret = array(
                'Message_Type' => $array['Message_Type']
            );
            $json = json_encode($ret);
            foreach ($_server->connections as $fd)
            {
                $_server->push($fd, $json);
            }
            break;

        case Message_Type::Ban_LogAdminAction:
            $global['kxnrl']->Ban_LogAdminAction($array['Message_Data']['aid'], $array['Message_Data']['sid'], $array['Message_Data']['act'], $array['Message_Data']['msg']);
            break;

        case Message_Type::Ban_LogBlocks:
            $global['kxnrl']->Ban_LogBlocks($array['Message_Data']['bid'], $array['Message_Data']['adr']);
            break;

        case Message_Type::Couple_LoadAll:
            // todo 
            break;

        case Message_Type::Couple_LoadUser:
            $dat = $global['kxnrl']->Couple_LoadUser($array['Message_Data']['steamid']);
            if ($dat) {
                $ret = array(
                    'Message_Type' => $array['Message_Type'],
                    'Message_Data' => $dat
                );
                $_server->push($frame->fd, json_encode($ret));
            }
            break;

        case Message_Type::Couple_Update:
            $global['kxnrl']->Couple_Update($array['Message_Data']['cpid'], $array['Message_Data']['exp'], $array['Message_Data']['lily'], $array['Message_Data']['time']);
            break;

        case Message_Type::Couple_Wedding:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Couple_Wedding($array['Message_Data']['source'], $array['Message_Data']['target'])
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Couple_Divorce:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Couple_Divorce($array['Message_Data']['cpid'], $array['Message_Data']['source'])
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Couple_MarriageSeek:
            // todo 
            break;

        case Message_Type::Stats_LoadUser:
            _sprintf("LoadUser: " . $array['Message_Data']['steamid']);
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Stats_LoadUser($array['Message_Data']['steamid'])
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Stats_Analytics:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Stats_Analytics($array['Message_Data']['pid'], $array['Message_Data']['ticket'], $array['Message_Data']['time'], $array['Message_Data']['srvid'], $array['Message_Data']['modid'], $array['Message_Data']['map'], $array['Message_Data']['ip'])
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Stats_Update:
            $global['kxnrl']->Stats_Update($array['Message_Data']['tid'], $array['Message_Data']['pid'], $array['Message_Data']['duration'], $array['Message_Data']['play'], $array['Message_Data']['spec'], $array['Message_Data']['alive'], $array['Message_Data']['connected']);
            break;

        case Message_Type::Stats_DailySignIn:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Stats_DailySignIn($array['Message_Data']['pid'], $array['Message_Data']['online'])
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Stats_IS_LoadUser:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Stats_IS_LoadUser($array['Message_Data']['pid'])
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Stats_IS_LoadAll:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Data' => $global['kxnrl']->Stats_IS_LoadAll()
            );
            $_server->push($frame->fd, json_encode($ret));
            break;

        case Message_Type::Invalid:
        {
            _log("Recv Invliad Message from {$frame->fd}.\n```json\n{$frame->data}\n```");
            break;
        }

        default:
        {
            _log("Recv Invliad Message from {$frame->fd}.\n```json\n{$frame->data}\n```");
            break;
        }
    }

    $global['kxnrl']->clear();
});

$server->on('open', function(swoole_websocket_server $_server, swoole_http_request $request) {
    global $authed;
    $authed[$request->fd]['verify'] = false;
    $r = 0;
    foreach ($_server->connections as $c)
    {
        $r++;
    }
    _sprintf("=============[OnStart]=============");
    _sprintf("Connection start: {$request->fd}");
    _sprintf("Total connection: {$r}");
});

$server->on('close', function($_server, $fd) {
    global $global, $authed;
    unset($authed[$fd]);
    $r = 0;
    foreach ($_server->connections as $c)
    {
        $r++;
    }
    _sprintf("=============[OnClose]=============");
    _sprintf("Connection close: {$fd}");
    _sprintf("Total connection: {$r}");

    if ($global['isBot'] == $fd) {

        $global['isBot'] = -1;

        _msg("CQPBot disconnected.");
    }
});

$server->start();

?>
