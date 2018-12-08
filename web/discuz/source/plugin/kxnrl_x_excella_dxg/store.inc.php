<?php
if(!defined('IN_DISCUZ')) {
    exit('Access Denied');
}

require_once __DIR__ . '/configs.php';
require_once __DIR__ . '/function.php';

if($_GET['type'] != 'dele'){
    
    showmessage("功能开发中");

}

if($_GET['itemid'] < 0){

    showmessage("ItemID错误");

}

$steam64 = DB::fetch_first("SELECT * FROM dxg_users WHERE uid='" . $_G[uid] . "';")['steamid'];

if(!$steam64){
    
    showmessage("请您先关联您的Steam账户", 'plugin.php?id=kxnrl_x_excella_dxg');
    
}

$steamid = SteamID64ToSteamID32($steam64, false);

$coinnum = C::t('common_member_count')->fetch($_G['uid'])['extcredits2'];

$sql = new mysqli($db_host, $db_user, $db_pswd, $db_name, 3306);
if(!$sql) {
    LogMessage('Connect Error: ' . $sql->connect_error);
    showmessage('数据库发生异常错误了.', 'forum.php');
}

if(($result = $sql->query("SELECT * FROM store_players WHERE authid='$steamid'")) && ($row = $result->fetch_array())){

    $credits = $row['credits'];
    $storeid = $row['id'];

}

$sql->query("DELETE FROM store_items WHERE player_id = $storeid AND id = $_GET[itemid]");

$sql->close();

showmessage("操作完成", 'plugin.php?id=kxnrl_x_excella_dxg&ac=store');

?>