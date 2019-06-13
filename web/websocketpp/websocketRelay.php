<?php

require_once __DIR__ . '/lib/' . 'message.inc.php';

$ipAdr = array();
$authd = array();

try {

    $client = new swoole_http_client('127.0.0.1', 420);
    $server = new swoole_websocket_server("127.0.0.1", 421);

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

} catch (Exception $e) {

    _sprintf("Failed to create server: " . $e->getMessage());
    die();
}

$client->upgrade('/', function (swoole_http_client $_client) {
    $_client->push("WebSocketRelay");
});

$client->on('message', function (swoole_http_client $_client, $frame) {
    
    global $server, $ipAdr;

    $array = @json_decode($frame->data, true);

    if (!isset($array['Message_Type']) || $array['Message_Type'] <= Message_Type::Invalid || $array['Message_Type'] >= Message_Type::MaxMessage)
    {
        _sprintf("=============[Received]=============");
        _sprintf("Data: {$frame->data}");
        return true;
    }

    switch($array['Message_Type'])
    {
        case Message_Type::Client_S2S:
            $_client->push($frame->fd, json_encode($array));
            break;
        case Message_Type::Client_HeartBeat:
            foreach ($server->connections as $fd)
            {
                if (strcmp($ipAdr[$fd], $array['Message_Data']['ipAdr']) != 0) {
                    continue;
                }
                $array = array(
                    'Message_Type' => 'Ping',
                    'Message_Data' => time(),
                );
                $server->push(json_encode($array), $fd);
            }
            break;
    }
});

$server->on('message', function(swoole_websocket_server $_server, $frame) {

    global $client, $ipAdr, $authd;

    $array = @json_decode($frame->data, true);

    if (!isset($authd[$frame->fd]) || !$authd[$frame->fd])
    {
        if (!isset($array['ip']) || !isset($array['system']))
        {
            $_server->close($frame->fd, false);
            return false;
        }
        $ipAdr[$frame->fd] = $array['ip'];
        $authd = true;
        return true;
    }

    if (!isset($array['Message_Type']) || $array['Message_Type'] <= Message_Type::Invalid || $array['Message_Type'] >= Message_Type::MaxMessage)
    {
        _sprintf("=============[Received]=============");
        _sprintf("Data: {$frame->data}");
        return true;
    }

    switch($array['Message_Type'])
    {
        case Message_Type::Client_ForwardUser:
            $ret = array(
                'Message_Type' => $array['Message_Type'],
                'Message_Type' => array(
                    'ipAdr' => $authd[$frame-fd],
                    'unixt' => time()
                )
            );
            $client->push(json_encode($ret));
            break;
    }
});

$server->on('open', function(swoole_websocket_server $_server, swoole_http_request $request) {
    global $authd;
    $authd[$request->fd] = false;
});

$server->on('close', function(swoole_websocket_server $_server, $fd) {
    global $authd;
    $authd[$fd] = false;
});