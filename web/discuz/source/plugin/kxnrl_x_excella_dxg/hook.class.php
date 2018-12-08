<?php
if(!defined('IN_DISCUZ')){
    exit('Access Denied');
}

// https://open.discuz.net/?ac=document&page=plugin_hooklist
// https://blog.csdn.net/le3600/article/details/7969221

class plugin_kxnrl_x_excella_dxg {

}

class plugin_kxnrl_x_excella_dxg_forum extends plugin_kxnrl_x_excella_dxg {
    
    function viewthread_sidetop_output() {
        
        global $_G, $postlist;

        $returns = array();
        
        foreach ($postlist as $post) {
            //$uid = $post['authorid'];
            
            $returns[] = 'viewthread_sidetop_output()';
        }

    }

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

            if(isset($data['gameid']) && intval($data['gameid']) > 0){
                $data['appid'] = 'https://store.steampowered.com/app/' . $data['gameid'];
                $data['gameu'] = '<a class="steam_user_bar_game" href="' . $data['appid'] . '" target="_blank">' . $data['state'] . '</a>';
            } else {
                $data['gameu'] = '<span class="steam_user_bar_offl">' . $data['state'] . '</span>';
            }

            $results[] =
<<<EOF
<div style="margin-top:10px;">
    <p class="steam_user_bar"><span class="steam_user_bar_ttle">社区昵称：</span><a class="steam_user_bar_nick" href="https://steam.1mgou.com/profiles/{$data['steamid']}" target="_blank">{$data['nickname']}</a> <span class="pipe">|</span> <span class="steam_user_bar_ttle">社区等级：</span><span class="steam_user_bar_lvls">{$data['levels']}</span> <span class="pipe">|</span> <span class="steam_user_bar_ttle">社区状态：</span>{$data['gameu']} <span class="pipe">|</span> <a class="steam_user_bar_link" href="https://steam.1mgou.com/profiles/{$data['steamid']}" target="_blank" title="查看资料">个人主页</a></p>
</div>
EOF;
        }
        return $results;
    }
}

class plugin_kxnrl_x_excella_dxg_home extends plugin_kxnrl_x_excella_dxg {

    function spacecp_usergroup_top_output() {

		global $_G, $maingroup, $usergroups;

        if(!$usergroups) return;

		$maingroup['grouptitle'] .= '(Test spacecp_usergroup_top_output by eXCELLa)';
	}

    function space_profile_baseinfo_top_output() {
        
        global $_G, $space;
        
        if(!$_G['uid'])
            return '';
        
        if($space['uid'] == 120) {
            return '(Test space_profile_baseinfo_top_output by eXCELLa)';
        }

        return '';
    }
}