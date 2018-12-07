<?php
if(!defined('IN_DISCUZ')){
    exit('Access Denied');
}

require_once __DIR__ . '/configs.php';
require_once __DIR__ . '/function.php';

$dzusers = DB::fetch_first("SELECT * FROM dxg_users WHERE uid = $_G[uid]");

$allowtime = $dzusers['lastupdate']+60;

if($allowtime > time()){
    
    showmessage("请等待1分钟后再尝试刷新");
    
}

$sql = new mysqli($db_host, $db_user, $db_pswd, $db_name, 3306);
if(!$sql) {
    LogMessage('Connect Error: ' . $sql->connect_error);
    showmessage('数据库发生异常错误了.', 'forum.php');
}

if(UpdateSteamProfiles($sql, $api_key, $dzusers['steamid'], $_G['uid'])){

    showmessage("已更新您的Steam账户数据", 'plugin.php?id=kxnrl_x_excella_dxg');

}else{
    
    showmessage("系统繁忙");

}

$sql->close();

?>