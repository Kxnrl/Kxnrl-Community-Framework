<?php

if(!defined('IN_DISCUZ')){
    exit('Access Denied');
}

$logsnum = 0;
$itemnum = 0;

if(($result = $rds->query("SELECT * FROM store_players WHERE authid='$steamid'")) && ($row = $result->fetch_array())){

    $storeid = $row['id'];
    $credits = $row['credits'];

    if($storeid > 0){

        if($coinnum < 0 && $credits > 0){
            
            $rds->query("UPDATE store_players SET credits=credits+$coinnum WHERE authid='$steamid' AND id = '$storeid'");

            if($rds->affected_rows != 0){

                $rds->query("INSERT INTO store_newlogs VALUES (DEFAULT, $storeid, $credits+$coinnum, $coinnum, '补全负数信用点', UNIX_TIMESTAMP())");
                updatemembercount($_G['uid'], array('extcredits1'=>-$coinnum), '', '', '', '积分补全', '积分补全', '补全负数信用点');
                showmessage("已为您更新商店数据,请刷新页面!", 'home.php?mod=spacecp&ac=plugin&id=kxnrl_x_excella_dxg:credits');

            }

        }elseif($coinnum > 0 && $credits < 0){

            $rds->query("UPDATE store_players SET credits=0 WHERE authid='$steamid' AND id = '$storeid'");
            
            if($rds->affected_rows != 0){

                $rds->query("INSERT INTO store_newlogs VALUES (DEFAULT, $storeid, 0, -$credits, '补全负数信用点', UNIX_TIMESTAMP())");
                updatemembercount($_G['uid'], array('extcredits1'=>$credits), '', '', '', '积分补全', '积分补全', '补全负数信用点');
                showmessage("已为您更新商店数据,请刷新页面!", 'home.php?mod=spacecp&ac=plugin&id=kxnrl_x_excella_dxg:credits');

            }
        }

        if($result2 = $rds->query("SELECT * FROM store_newlogs WHERE store_id='$storeid' AND timestamp >= UNIX_TIMESTAMP()-259200 ORDER BY id DESC")){

            $rows = array();

            while($row2 = $result2->fetch_array())
            {
                $row2['date'] = date("Y年m月d日 H:i:s", $row2['timestamp']);
                $row2['tkid'] = str_pad($row2['Id']+5256052, 7, "0", STR_PAD_LEFT);
                if($row2['difference'] < 0){

                    $row2['difference'] = "<font color='red'>" . number_format($row2['difference'], 0) . "</font>";
                    
                }else if($row2['difference'] > 0){
                    
                    $row2['difference'] = "<font color='green'>+ " . number_format($row2['difference'], 0) . "</font>";
                    
                }else{
                    
                    $row2['difference'] = "<font color='black'>± " .number_format($row2['difference'], 0) . "</font>";

                }

                $row2['credits'] = number_format($row2['credits'], 0);
                $rows[] = $row2;
                $logsnum++;
            }
        }
        
        if($result3 = $rds->query("SELECT * FROM store_items WHERE player_id=$storeid")){
            
            $itemnum = $result3->$num_rows;

        }
    }else{
        
        showmessage("请您先进入一次服务器", 'plugin.php?id=kxnrl_x_excella_dxg');
        
    }
}

?>