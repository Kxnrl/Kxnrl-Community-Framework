<?php

function SteamID64ToSteamID32($steam64, $prefix)
{
    $tsid = array(substr($steam64, -1, 1) % 2 == 0 ? 0 : 1);
    $tsid[1] = bcsub($steam64, '76561197960265728');
    if(bccomp($tsid[1], '0') != 1){
        $steamid = '';
    }
    $tsid[1] = bcsub($tsid[1], $tsid[0]);
    list($tsid[1], ) = explode('.',bcdiv($tsid[1], 2), 2);
    $steamid = implode(':', $tsid);
    if($prefix){
        $steamid = 'STEAM_1:'.$steamid;
    }
    return $steamid;
}

function LogMessage($message)
{
    $fp = fopen( __DIR__ . "/errorlog.php", "a");
    fputs($fp, "<?PHP exit;?>    ");
    fputs($fp, $message);
    fputs($fp, "\n");
    fclose($fp);
}

function InsertNewUsers($uid, $steamid)
{
    DB::query("INSERT INTO dxg_users (uid, steamid) VALUES ($uid, '$steamid')");
    $users = DB::fetch_first("SELECT * FROM dxg_users WHERE steamid = '$steamid'");
    return ($users['uid'] == $uid);
}

function UpdateSteamProfiles($rds, $apikey, $steamid, $uid)
{
    $array = array();

    // Get Summaries (name, id, avatar)
    $url = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=$apikey&format=json&steamids=$steamid";

    if(!function_exists("curl_init")){
        LogMessage("curl is unavailable!");
        return false;
    }

    $curl = curl_init();
    curl_setopt($curl, CURLOPT_URL, $url);
    curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($curl, CURLOPT_HEADER, 0);
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
    $data = curl_exec($curl);
    curl_exec($curl);
    curl_close($curl);

    $json = json_decode($data, true);
    
    $array['public'] = true;

    foreach($json as $key => $value)
    {
        foreach($value['players'] as $k => $v)
        {
            $array['nick'] = $v['personaname'];
            $array['steam'] = $v['steamid'];
            $array['avatar'] = $v['avatar'];
            $array['state'] = "Offline";
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
                $array['state'] = "Unknow";
                $array['public'] = false;
            }
            break;
        }
    }

    if($steamid != $array['steam']){
        LogMessage("SteamID ERROR (".$steamid." : ".$array['steam'].")");
        return false;
    }
    
    $array['badges'] = 0;
    $array['levels'] = 0;

    if($array['public']) {

        // Get Badges (level, badges)
        $url = "https://api.steampowered.com/IPlayerService/GetBadges/v1/?key=$apikey&format=json&steamid=$steamid";
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_HEADER, 0);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
        $data = curl_exec($curl);
        curl_close($curl);
        
        $json = json_decode($data, true);

        foreach($json as $key => $value)
        {
            $array['badges'] = 0;
            $array['levels'] = $value['player_level'];
            if($value['player_level'] != null){
                foreach($value['badges'] as $k => $v)
                {
                    $array['badges']++;
                }
            }
        }
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

    $array['nick'] = str_replace(array('&','<','>'),array('&amp;','&lt;','&gt;'), $array['nick']);
    $array['E_nick'] = $rds->real_escape_string($array['nick']);
    $array['E_avatar'] = $rds->real_escape_string($array['avatar']);
    $array['E_current'] = $rds->real_escape_string($array['state']);

    DB::query("UPDATE dxg_users SET lastupdate = '".time()."', nickname = '".$array['E_nick']."', level = '".$array['levels']."', badges = '".$array['badges']."', avatar = '".$array['E_avatar']."', current = '".$array['E_current']."', gameid = '".$array['gameid']."' WHERE uid = '".$uid."'");

    if(!UpdateSteamAvatar($uid, $array)) {
        LogMessage("Update Avatar -> " . $uid . " -> " . $array['avatar']);
    }

    return true;
}

function UpdateSteamAvatar($uid, $array)
{
    $key = strval($uid);
    $redis = new Redis();
    if($redis->connect('127.0.0.1', 4399, 1, NULL, 200)) {
        if($redis->auth('redis-password')){
            $redis->select(1);
            $redis->setOption(Redis::OPT_SERIALIZER, Redis::SERIALIZER_PHP);
            $redis->setOption(Redis::OPT_PREFIX, 'avatar_steam_');
            if($redis->exists($key)) {
                $redis->delete($key);
            }   
            $data = array (
                'steamid'  => $array['steam'],
                'avatar'   => $array['avatar'],
                'nickname' => htmlspecialchars(xss_clean($array['nick'])),
                'levels'   => $array['levels'],
                'state'    => $array['state']
            );
            return $redis->set($key, json_encode($data), array('nx', 'ex'=>86400));
        }
    }
    return false;
}

function xss_clean($data)
{
    $data=str_replace(array('&','<','>'),array('&amp;','&lt;','&gt;'), $data);
    $data=preg_replace('/(&#*\w+)[\x00-\x20]+;/u','$1;',$data);
    $data=preg_replace('/(&#x*[0-9A-F]+);*/iu','$1;',$data);
    $data=html_entity_decode($data,ENT_COMPAT,'UTF-8');
    $data=preg_replace('#(<[^>]+?[\x00-\x20"\'])(?:on|xmlns)[^>]*+>#iu','$1>',$data);
    $data=preg_replace('#([a-z]*)[\x00-\x20]*=[\x00-\x20]*([`\'"]*)[\x00-\x20]*j[\x00-\x20]*a[\x00-\x20]*v[\x00-\x20]*a[\x00-\x20]*s[\x00-\x20]*c[\x00-\x20]*r[\x00-\x20]*i[\x00-\x20]*p[\x00-\x20]*t[\x00-\x20]*:#iu','$1=$2nojavascript...',$data);
    $data=preg_replace('#([a-z]*)[\x00-\x20]*=([\'"]*)[\x00-\x20]*v[\x00-\x20]*b[\x00-\x20]*s[\x00-\x20]*c[\x00-\x20]*r[\x00-\x20]*i[\x00-\x20]*p[\x00-\x20]*t[\x00-\x20]*:#iu','$1=$2novbscript...',$data);
    $data=preg_replace('#([a-z]*)[\x00-\x20]*=([\'"]*)[\x00-\x20]*-moz-binding[\x00-\x20]*:#u','$1=$2nomozbinding...',$data);
    $data=preg_replace('#(<[^>]+?)style[\x00-\x20]*=[\x00-\x20]*[`\'"]*.*?expression[\x00-\x20]*\([^>]*+>#i','$1>',$data);
    $data=preg_replace('#(<[^>]+?)style[\x00-\x20]*=[\x00-\x20]*[`\'"]*.*?behaviour[\x00-\x20]*\([^>]*+>#i','$1>',$data);
    $data=preg_replace('#(<[^>]+?)style[\x00-\x20]*=[\x00-\x20]*[`\'"]*.*?s[\x00-\x20]*c[\x00-\x20]*r[\x00-\x20]*i[\x00-\x20]*p[\x00-\x20]*t[\x00-\x20]*:*[^>]*+>#iu','$1>',$data);
    $data=preg_replace('#</*\w+:\w[^>]*+>#i','',$data);
    do
    {
        $old_data=$data;
        $data=preg_replace('#</*(?:applet|b(?:ase|gsound|link)|embed|frame(?:set)?|i(?:frame|layer)|l(?:ayer|ink)|meta|object|s(?:cript|tyle)|title|xml)[^>]*+>#i','',$data);
    }
    while($old_data!==$data);

    return $data;
}

?>