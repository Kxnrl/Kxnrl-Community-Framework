<?php 

if(!defined('websocket_server_kxnrl')){
    http_response_code(404);
    die;
}

$_config['mysql']['host'] = '';
$_config['mysql']['port'] = '';
$_config['mysql']['user'] = '';
$_config['mysql']['pswd'] = '';
$_config['mysql']['db']['forum'] = '';
$_config['mysql']['db']['kxnrl'] = '';

require_once 'forum.class.php';
require_once 'kxnrl.class.php';

?>
