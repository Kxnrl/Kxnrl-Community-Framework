<?php

//cronname:update_steam
//minute:4,14,24,34,44,54,59

if(!defined('IN_DISCUZ')) {
    define('DISCUZ_ROOT', '/var/www/direct');
    exit('Access Denied');
}

logM("Cron started at " . date("Y-m-d H:i:s", time()) . " .");

require_once DISCUZ_ROOT . '/source/plugin/kxnrl_x_excella_dxg/configs.php';
require_once DISCUZ_ROOT . '/source/plugin/kxnrl_x_excella_dxg/function.php';

$rds = new mysqli($db_host, $db_user, $db_pswd, "ultrax", 3306);
if(!$rds) {
    logM('Connect Error: ' . $rds->connect_error);
    exit;
}

//$users = DB::fetch_all("SELECT * FROM dxg_users WHERE uid <> 120 AND lastupdate < NOW()-1800 LIMIT 99;");
$result = $rds->query("SELECT * FROM dxg_users WHERE uid <> 120 AND lastupdate < (unix_timestamp()-1800) LIMIT 99;");
if(!$result) {
    logM('Query Error: ' . $rds->error);
    exit;
}

$levels = array();
$badges = array();
$myuids = array();

$baseURL = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=$api_key&format=json&steamids=76561198048432253";
$myuids['76561198048432253'] = 120;
$levels['76561198048432253'] = 1010;
$badges['76561198048432253'] = 2997;

print_r("load -> " . $myuids['76561198048432253'] . " -> " . $levels['76561198048432253'] . " -> " . $badges['76561198048432253']);
print_r(PHP_EOL);

/*
foreach($users as $key => $val) {

    $steamid = strval($val['steamid']);

    $baseURL .= ";";
    $baseURL .= $steamid;
    
    $levels[$steamid] = isset($val['level'])  ? $val['level']  : 0;
    $badges[$steamid] = isset($val['badges']) ? $val['badges'] : 0;
    $myuids[$steamid] = $val['uid'];

}
*/

while($row = $result->fetch_array())
{
    $steamid = strval($row['steamid']);

    $baseURL .= ";" . $steamid;

    $levels[$steamid] = $row['level'];
    $badges[$steamid] = $row['badges'];
    $myuids[$steamid] = $row['uid'];

    print_r("load -> " . $myuids[$steamid] . " -> " . $row['level'] . " -> " . $row['badges']);
    print_r(PHP_EOL);
}

for($i = 0; $i < 5; $i++) {
    
    $curl = curl_init();
    curl_setopt($curl, CURLOPT_URL, $baseURL);
    curl_setopt($curl, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, 0);
    curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 5);
    curl_setopt($curl, CURLOPT_TIMEOUT, 5);

    $json = curl_exec($curl);
    $info = curl_getinfo($curl);
    $error = curl_errno($curl);
    $status = $error ? curl_error($curl) : '';
    
    curl_close($curl);

    if (!$error) {
        break;
    } else {
        logM("Failed to curl steamApi: " . $status);
    }
}

$data = json_decode($json, true);

foreach($data as $key => $value)
{
    foreach($value['players'] as $k => $v)
    {
        $array['nick'] = $v['personaname'];
        $array['steam'] = $v['steamid'];
        $array['avatar'] = $v['avatar'];
        $array['gameid'] = 0;

        if(isset($v['gameextrainfo'])){
            $array['state'] = $v['gameextrainfo'];
            $array['gameid'] = $v['gameid'];
        }elseif($v['personastate'] > 0){
            switch($v['personastate'])
            {
                case 0: $array['state'] = "Offline"; break;
                case 1: $array['state'] = "Online"; break;
                case 2: $array['state'] = "Busy"; break;
                case 3: $array['state'] = "Away"; break;
                case 4: $array['state'] = "Snooze"; break;
                case 5: $array['state'] = "looking to trade"; break;
                case 6: $array['state'] = "looking to play"; break;
            }
        }elseif($v['communityvisibilitystate'] == 1){
            $array['state'] = "Private Profile";
            $array['public'] = false;
        }else{
            $array['state'] = "Offline";
            $array['public'] = false;
        }
        
        if(!isset($array['nick']) || empty($array['nick']) || strlen($array['nick']) < 2) {
            $array['nick'] = 'unnamed';
        }
        
        if(!isset($array['avatar']) || empty($array['avatar']) || strlen($array['avatar']) < 20) {
            $array['avatar'] = 'https://media.st.dl.bscstorage.net/steamcommunity/public/images/avatars/fe/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb.jpg';
        }
        
        if(!isset($array['state']) || empty($array['state']) || strlen($array['state']) < 3) {
            $array['state'] = 'unknow';
        }
        
        $steamid = strval($array['steam']);
        $array['levels'] = $levels[$steamid];
        $array['badges'] = $badges[$steamid];

        $array['nick'] = str_replace(array('&','<','>'),array('&amp;','&lt;','&gt;'), $array['nick']);
        $array['E_nick'] = $rds->real_escape_string($array['nick']);
        $array['E_avatar'] = $rds->real_escape_string($array['avatar']);
        $array['E_current'] = $rds->real_escape_string($array['state']);
        
        //DB::query("UPDATE dxg_users SET lastupdate = '".time()."', nickname = '".$array['E_nick']."', level = '".$array['levels']."', badges = '".$array['badges']."', avatar = '".$array['E_avatar']."', current = '".$array['E_current']."', gameid = '".$array['gameid']."' WHERE uid = '".$myuids[$steamid]."'");
        $rds->query("UPDATE dxg_users SET lastupdate = '".time()."', nickname = '".$array['E_nick']."', level = '".$array['levels']."', badges = '".$array['badges']."', avatar = '".$array['E_avatar']."', current = '".$array['E_current']."', gameid = '".$array['gameid']."' WHERE uid = '".$myuids[$steamid]."'");
        if($rds->affected_rows == 0) {
            logM("Failed to update -> " . $myuids[$steamid] . " -> " . $steamid);
        } else {
            print_r("Updated -> " . $myuids[$steamid] . " -> " . $steamid);
            print_r(PHP_EOL);
            //logM("Updated -> " . $myuids[$steamid] . " -> " . $steamid);
        }

        if(!UpdateSteamAvatar($myuids[$steamid], $array)){
            logM("Update Avatar -> " . $myuids[$steamid] . " -> " . $array['avatar']);
        }
    }
}

$rds->close();

function logM($message) {
    print_r($message);
    print_r(PHP_EOL);

    $fp = fopen(__DIR__ . "/errorlog.php", "a+");
    fputs($fp, "<?PHP exit;?>    ");
    fputs($fp, $message);
    fputs($fp, "\n");
    fclose($fp);
}
?>