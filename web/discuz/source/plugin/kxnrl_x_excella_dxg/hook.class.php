<?php
if(!defined('IN_DISCUZ')){
    exit('Access Denied');
}

class plugin_kxnrl_x_excella_dxg {

}

class plugin_kxnrl_x_excella_dxg_forum extends plugin_kxnrl_x_excella_dxg {

    function viewthread_postheader_output() {
        
        global $_G, $postlist;

        $results = array();

        $redis = new Redis();
        if($redis->connect('127.0.0.1', 4399, 1, NULL, 200)) {
            if($redis->auth('redis-password')){
                $redis->select(1);
                $redis->setOption(Redis::OPT_SERIALIZER, Redis::SERIALIZER_PHP);
                $redis->setOption(Redis::OPT_PREFIX, 'avatar_steam_');
            } else {
                return $results;
            }
        } else {
            return $results;
        }

        foreach($postlist as $pid => $post) {
            
            $key = strval($post['authorid']);
            
            $json = $redis->get(strval($key));
            
            if(!$json) {
                $results[] = '';
                continue;
            }

            $data = json_decode($json, true);
            $results[] =
<<<EOF
<div style="margin-top:10px;">
    <p class="steam_user_bar"><span class="steam_user_bar_ttle">社区昵称：</span><span class="steam_user_bar_nick">{$data['nickname']}</span> <span class="pipe">|</span> <span class="steam_user_bar_ttle">社区等级：</span><span class="steam_user_bar_lvls">{$data['levels']}</span> <span class="pipe">|</span> <span class="steam_user_bar_ttle">社区状态：</span><span class="steam_user_bar_game">{$data['state']}</span> <span class="pipe">|</span> <a class="steam_user_bar_link" href="https://steamproxy.1mgou.com/profiles/{$data['steamid']}" target="_blank" title="查看资料">个人主页</a></p>
</div>
EOF;
        }
        return $results;
    }
}
