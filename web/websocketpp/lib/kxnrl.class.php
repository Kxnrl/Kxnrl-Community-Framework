<?php

class Kxnrl
{
    protected $db = null;

    public function __construct() {

        $this->connect();

        /*
        $this->db->multi_query(
<<<EOF
            CREATE TABLE IF NOT EXISTS `kcf_admins` (
              `aid` smallint(6) NOT NULL AUTO_INCREMENT,
              `adminName` varchar(32) DEFAULT NULL,
              `steamid` bigint(20) unsigned NOT NULL DEFAULT '0',
              `flags` char(26) DEFAULT NULL,
              `authSrv` char(64) NOT NULL DEFAULT 'NULL SERVER',
              `immunity` tinyint(3) unsigned NOT NULL DEFAULT '20',
              `lastseen` int(11) unsigned DEFAULT '0',
              `idname` varchar(10) DEFAULT NULL,
              `identity` char(20) DEFAULT NULL,
              `hide` tinyint(2) unsigned NOT NULL DEFAULT '0',
              PRIMARY KEY (`aid`),
              UNIQUE KEY `uk_steamid` (`steamid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            
            CREATE TABLE IF NOT EXISTS `kcf_analytics` (
              `tid` int(11) unsigned NOT NULL AUTO_INCREMENT,
              `uid` int(11) unsigned NOT NULL DEFAULT '0',
              `ticket` char(36) NOT NULL DEFAULT 'INVALID_TICKET',
              `connect_time` int(11) unsigned NOT NULL DEFAULT '0',
              `server_id` smallint(5) unsigned NOT NULL DEFAULT '0',
              `mod_id` smallint(5) unsigned NOT NULL DEFAULT '0',
              `map` char(128) DEFAULT NULL,
              `duration` smallint(5) unsigned NOT NULL DEFAULT '0',
              `ip` char(20) DEFAULT NULL,
              PRIMARY KEY (`tid`),
              UNIQUE KEY `uk_connections` (`uid`,`connect_time`),
              UNIQUE KEY `uk_ticket` (`ticket`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            
            CREATE TABLE IF NOT EXISTS `kcf_bans` (
              `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
              `steamid` bigint(20) NOT NULL DEFAULT '0',
              `bCreated` int(11) unsigned NOT NULL DEFAULT '0',
              `bLength` int(11) unsigned NOT NULL DEFAULT '0',
              `bType` tinyint(3) unsigned NOT NULL DEFAULT '0',
              `bSrv` smallint(3) unsigned NOT NULL DEFAULT '0',
              `bSrvMod` smallint(5) unsigned NOT NULL DEFAULT '0',
              `bAdminId` tinyint(3) NOT NULL DEFAULT '0',
              `bAdminName` varchar(32) DEFAULT NULL,
              `bReason` varchar(128) DEFAULT NULL,
              `bRemovedBy` int(11) NOT NULL DEFAULT '-1',
              PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            
            CREATE TABLE `kcf_blocks` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `bid` int(11) unsigned NOT NULL DEFAULT '0',
              `ip` char(20) DEFAULT NULL,
              `date` int(11) unsigned NOT NULL DEFAULT '0',
              PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            
            CREATE TABLE IF NOT EXISTS `kcf_players` (
              `uid` int(11) unsigned NOT NULL AUTO_INCREMENT,
              `steamid` bigint(20) unsigned NOT NULL DEFAULT '0',
              `firstjoin` int(11) NOT NULL DEFAULT '-1',
              `lastseen` int(11) NOT NULL DEFAULT '-1',
              `connections` int(11) unsigned NOT NULL DEFAULT '0',
              `onlinetimes` int(11) unsigned NOT NULL DEFAULT '0',
              `signtimes` int(11) unsigned NOT NULL DEFAULT '0',
              `signdate` int(11) NOT NULL DEFAULT '-1',
              `signkeep` smallint(5) unsigned NOT NULL DEFAULT '0',
              PRIMARY KEY (`uid`),
              UNIQUE KEY `uk_steamid` (`steamid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            
            CREATE TABLE IF NOT EXISTS `kcf_servers` (
              `sid` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
              `mod` smallint(5) unsigned NOT NULL DEFAULT '0',
              `hostname` varchar(128) NOT NULL DEFAULT 'Server Hostname',
              `ip` varchar(24) NOT NULL DEFAULT 'Server IP',
              `port` smallint(5) unsigned NOT NULL DEFAULT '27015',
              `rcon` char(32) NOT NULL DEFAULT 'Rcon Password',
              `display` tinyint(3) unsigned NOT NULL DEFAULT '1',
              PRIMARY KEY (`sid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            
            CREATE TABLE IF NOT EXISTS `kcf_stats` (
              `sid` int(11) unsigned NOT NULL AUTO_INCREMENT,
              `uid` int(11) unsigned NOT NULL DEFAULT '0',
              `playtotal` int(11) unsigned NOT NULL DEFAULT '0',
              `spectotal` int(11) unsigned NOT NULL DEFAULT '0',
              `alivetime` int(11) unsigned NOT NULL DEFAULT '0',
              PRIMARY KEY (`sid`),
              UNIQUE KEY `uk_uid` (`uid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
EOF
        );
        */
    }

    function connect() {

        if ($this->db != null) {
            $this->db->close();
        }

        global $_config;
        $this->db = new \mysqli($_config['mysql']['host'], $_config['mysql']['user'], $_config['mysql']['pswd'], $_config['mysql']['db']['kxnrl'], $_config['mysql']['port']);
    
        if ($this->db->connect_errno) {
            throw new Exception("Failed to connect to database: " . $this->db->connect_error);
        }

        if (!$this->db->set_charset("utf8mb4")) {
            $this->db->Close();
            _log("kxnrl: " . $this->db->error);
        }

        _sprintf("Connected to database: Kxnrl");
    }

    public function ping() {

        if ($this->db->ping()) {
            return true;
        }

        if ($this->db->query("SELECT UNIX_TIMESTAMP();")) {
            return true;
        }

        _log("Failed to ping MYSQL server.", false);
        $this->connect();
    }

    function fetchFirst($t, $c, $k) {

        if ($result = $this->db->query("SELECT * FROM $t WHERE `$c` = '$k' LIMIT 1;")) {

            if ($row = $result->fetch_array(MYSQLI_ASSOC)) {

                $result->free();

                return $row;
            }

            $result->free();
        }

        return null;
    }

    public function clear() {

        do {
            if ($res = $this->db->store_result()) {
                $res->free();
            }
        } while ($this->db->more_results() && $this->db->next_result());     
    }

    public function Server_Load($i, $p) {

        if ($result = $this->db->query("SELECT * FROM `kcf_servers` WHERE `ip` = '$i' AND `port` = '$p';")) {

            if ($row = $result->fetch_array(MYSQLI_ASSOC)) {

                $result->free();

                return array(
                    'hostname' => $row['hostname'],
                    'sid'      => intval($row['sid']),
                    'mid'      => intval($row['mod'])
                );
            }

            $result->free();

        }

        _log("Server_Load: " . $this->db->error);

        return array(
            'hostname' => '[KCF] Unknown Server',
            'sid'      => -1,
            'mid'      => -1,
        );
    }

    public function Server_StartMap($s, $m) {

        $s = intval($s);

        $this->db->query("INSERT INTO `kcf_serverlog` VALUES (DEFAULT, $s, '" . $this->db->real_escape_string($m) . "', UNIX_TIMESTAMP(), 0);");

        if ($this->db->affected_rows > 0) {
            
            return array(
                'sid' => $s,
                'tid' => intval($this->db->insert_id)
            );
        }

        _log("Server_StartMap: " . $this->db->error);

        return array(
            'sid' => $s,
            'tid' => -1
        );
    }

    public function Server_EndMap($s, $t) {

        $s = intval($s);
        $t = intval($t);

        $this->db->query("UPDATE `kcf_serverlog` SET end = UNIX_TIMESTAMP() WHERE `tid` = $t;");

        if ($this->db->affected_rows == 0) {
            _log("Server_EndMap: " . $this->db->error);
        }
    }

    public function Broadcast_Chat($p, $s, $m) {

        $s = intval($s);
        $p = intval($p);

        $this->db->query("INSERT INTO `kcf_chat` VALUES (DEFAULT, '$s', '$p', '" . $this->db->real_escape_string($m) . "', UNIX_TIMESTAMP());");

        if ($this->db->affected_rows == 0) {
            _log("Broadcast_Chat: " . $this->db->error);
            return null;
        }

        $servers = $this->fetchFirst('kcf_servers', 'sid', $s);

        if (!$servers || !isset($servers['shortname'])) {
            return null;
        }

        return $servers['shortname'];
    }

    public function Broadcast_Admin($a, $s, $m) {

        $s = intval($s);
        $a = intval($a);

        $this->db->query("INSERT INTO `kcf_adminlog` VALUES (DEFAULT, $a, $s, 'broadcast_chat', '" . $this->db->real_escape_string($m) . "');");

        if ($this->db->affected_rows == 0) {
            _log("Broadcast_Admin: " . $this->db->error);
        }

        $servers = $this->fetchFirst('kcf_servers', 'sid', $s);

        if (!$servers || !isset($servers['shortname'])) {
            return null;
        }

        return $servers['shortname'];
    }

    public function Ban_LoadAdmins() {

        if ($result = $this->db->query("SELECT * FROM `kcf_admins`;")) {

            $ret = array();

            while ($row = $result->fetch_array(MYSQLI_ASSOC))
            {
                $ret[] = array(
                    'aid'       => intval($row['aid']),
                    'steamid'   => $row['steamid'],
                    'adminName' => $row['adminName'],
                    'flags'     => $row['flags'],
                    'immunity'  => intval($row['immunity']),
                    'authSrv'   => $row['authSrv'],
                    'authMod'   => $row['authMod']
                );
            }

            $result->free();

            return $ret;

        }

        _log("Ban_LoadAdmins: " . $this->db->error);

        return array();
    }

    public function Ban_LoadAllBans() {

        if ($result = $this->db->query("SELECT * FROM `kcf_bans`;")) {

            $ret = array();

            while ($row = $result->fetch_array(MYSQLI_ASSOC))
            {
                $ret[] = $row;
            }

            $result->free();

            return $ret;
        }

        _log("Ban_LoadAllBans: " . $this->db->error);

        return array();
    }

    public function Ban_CheckUser($p, $s, $m) {

        $p = intval($p);
        $s = intval($s);
        $m = intval($m);
        $t = time();

        if ($result = $this->db->query("SELECT `bType`, `bSrv`, `bMod`, `bCreated`, `bLength`, `bReason`, `bid` FROM `kcf_bans` WHERE `steamid` = '$p' AND `bRemovedBy` = -1 ORDER BY `bType` ASC")) {

            $ret = array('eResult' => false, 'pid' => $p);

            while ($row = $result->fetch_array(MYSQLI_ASSOC))
            {
                $c = intval($row['bCreated']);
                $l = intval($row['bLength']);
                $y = intval($row['bType']);
                $v = intval($row['bSrv']);
                $d = intval($row['bMod']);
                $b = intval($row['bid']);

                // time check?
                if ($l > 0) {
                    $e = $c + $l * 60;
                    if ($t >= $e) {
                        continue;
                    }
                }

                if ($y == 1) {
                    // game ban

                    // for insurgency
                    if ($m > 1000 && $m < 1100  && ($d >= 1100 || 1000 >= $d)) {
                        continue;
                    }
                    // for left 4 dead
                    if ($m > 1100 && $m < 1200  && ($d >= 1100 || 1000 >= $d)) {
                        continue;
                    }
                    // for csgo
                    if ($m < 1000 && $d > 1000) {
                        continue;
                    }
                }

                if ($y == 2) {
                    // mode ban 
                    if ($m != $d) {
                        continue;
                    }
                }

                if ($y == 3) {
                    // server ban
                    if ($s != $v) {
                        continue;
                    }
                }

                $ret['bid'] = $b;
                $ret['bType'] = $y;
                $ret['bLength'] = $l;
                $ret['bCreate'] = $c;
                $ret['bReason'] = $row['bReason'];
                $ret['eResult'] = true;

                break;
            }

            $result->free();

            return $ret;
        }

        _log("Ban_CheckUser: " . $this->db->error);

        return array();
    }

    public function Ban_InsertIdentity($s, $l, $t, $sid, $mid, $aid, $r) {

        $s = intval($s);
        $l = intval($l);
        $t = intval($t);

        $sid = intval($sid);
        $aid = intval($aid);

        $this->db->query("INSERT INTO `kcf_bans` VALUES (DEFAULT, '$s', UNIX_TIMESTAMP(), $l, $t, $sid, $mid, $aid, '" . $this->db->real_escape_string($r) . "', DEFAULT);");

        $b = -1;

        if ($this->db->affected_rows == 0) {
            _log("Ban_InsertIdentity: " . $this->db->error);
        } else {
            $b = $this->db->insert_id;
        }

        return array(
            'aid' => $aid,
            'bid' => $b,
            'len' => $l,
            'type' => $t,
            'steamid' => $s,
            'reason' => $r
        );
    }

    public function Ban_LogAdminAction($a, $s, $c, $m) {

        $s = intval($s);
        $a = intval($a);

        $this->db->query("INSERT INTO `kcf_adminlog` VALUES (DEFAULT, $a, $s, '" . $this->db->real_escape_string($c) . "', '" . $this->db->real_escape_string($m) . "');");
    
        if ($this->db->affected_rows == 0) {
            _log("Ban_LogAdminAction: " . $this->db->error);
        }
    }

    public function Ban_LogBlocks($b, $l) {
        $b = intval($b);

        $this->db->query("INSERT INTO `kcf_blocks` VALUES (DEFAULT, $b, '" . $this->db->real_escape_string($l) . "', UNIX_TIMESTAMP());");

        if ($this->db->affected_rows == 0) {
            _log("Ban_LogBlocks: " . $this->db->error);
        }
    }

    public function Couple_LoadUser($p) {

        $p = intval($p);

        if ($result = $this->db->query("SELECT * FROM `kcf_couples` WHERE `source` = $p OR `target` = $p LIMIT 1;")) {

            if ($row = $result->fetch_array(MYSQLI_ASSOC)) {

                $b = ($p == $row['source']);

                $ret = array(
                    'cpid'     => intval($row['cpid']),
                    'partner'  => intval(($b ? $row['target'] : $row['source'])),
                    'issource' => $b ? 'true' : 'false',
                    'time'     => intval($row['time']),
                    'level'    => intval($row['level']),
                    'exp'      => intval($row['exp']),
                    'date'     => intval($row['date'])
                );

                $result->free();

                return $ret;
            }

            $result->free();

        }

        _log("Couple_LoadUser: " . $this->db->error);

        return null;
    }

    public function Couple_Update($c, $e, $l, $t) {

        $c = intval($c);

        $this->db->query("UPDATE `kcf_couples` SET `exp`=`exp`+$c, `lily`=`lily`+$l, `time`=`time`+$t WHERE `cpid` = $c;");

        if ($this->db->affected_rows == 0) {
            _log("Couple_Update: " . $this->db->error);
        }
    }

    public function Couple_Wedding($s, $t) {

        $s = intval($s);
        $t = intval($t);

        $this->db->query("INSERT INTO `kcf_couples` VALUES ($s, $t, 0, 0, 0, UNIX_TIMESTAMP());");

        if ($this->db->affected_rows == 0) {
            _log("Couple_Wedding: " . $this->db->error);
        }

        return array(
            'result' => ($this->db->affected_rows == 0) ? false : true
        );
    }

    public function Couple_Divorce($c, $s) {

        $s = intval($s);
        $c = intval($c);

        if ($result = $this->db->query("SELECT * FROM `kcf_couples` WHERE `cpid` = $c;")) {

            if ($row = $result->fetch_array(MYSQLI_ASSOC)) {

                $result->free();

                $this->db->query("DELETE FROM `kcf_couples` WHERE `cpid` = $c;");

                if ($this->db->affected_rows > 0) {

                    $this->db->query("INSERT INTO `kcf_divorce` VALUES (DEFAULT, " . $row['source'] . ", " . $row['target'] . ", " . $row['time'] . ", " . $row['exp'] . ", " . $row['lily'] . ", " . $row['date'] . ", UNIX_TIMESTAMP(), $s");
                
                    if ($this->db->affected_rows > 0) {

                        return array (
                            'result' => true
                        );
                    }
                }
            }

            $result->free();

        }

        _log("Couple_Divorce: " . $this->db->error);

        return array (
            'result' => false
        );
    }

    public function Stats_LoadUser($s) {

        $s = intval($s);

        if ($result = $this->db->query("SELECT * FROM `kcf_players` p LEFT JOIN `kcf_stats` s ON p.`pid`=s.`pid` WHERE p.`steamid` = '$s' LIMIT 1;")) {

            if ($row = $result->fetch_array(/*MYSQLI_ASSOC*/)) {

                $result->free();

                return array(
                    'pid'           => intval($row['pid']),
                    'firstjoin'     => intval($row['firstjoin']),
                    'lastseen'      => intval($row['lastseen']),
                    'connections'   => intval($row['connections']),
                    'onlinetimes'   => intval($row['onlinetimes']),
                    'signtimes'     => intval($row['signtimes']),
                    'signdate'      => intval($row['signdate']),
                    'signkeep'      => intval($row['signkeep']),
                    'playtotal'     => intval($row['playtotal']),
                    'spectotal'     => intval($row['spectotal']),
                    'alivetime'     => intval($row['alivetime']),
                    'steamid'       => strval($s),
                    'error'         => 'none'
                );

            } elseif ($result->num_rows == 0) {

                $this->db->query("INSERT INTO `kcf_players` (`steamid`, `firstjoin`) VALUES ('$s', UNIX_TIMESTAMP());");

                if ($this->db->affected_rows > 0) {

                    $p = $this->db->insert_id;

                    $this->db->query("INSERT INTO `kcf_stats` (`pid`) VALUES ('$p');");

                    if ($this->db->affected_rows > 0) {

                        return array(
                            'pid'           => intval($p),
                            'firstjoin'     => intval(time()),
                            'lastseen'      => intval(time()),
                            'connections'   => 0,
                            'onlinetimes'   => 0,
                            'signtimes'     => 0,
                            'signdate'      => -1,
                            'signkeep'      => 0,
                            'playtotal'     => 0,
                            'spectotal'     => 0,
                            'alivetime'     => 0,
                            'steamid'       => strval($s),
                            'error'         => 'none'
                        );
                    } else {

                        _log("Stats_LoadUser: Failed to Insert kcf_stats :$s");
                    }
                } else {

                    _log("Stats_LoadUser: Failed to Insert kcf_players :$s");
                }
            } else {

                _log("Stats_LoadUser: What happend?");
            }

            $result->free();

        } else {

            _log("Stats_LoadUser: " . $this->db->error);
        }

        return array(
            'pid'           => -1,
            'firstjoin'     => intval(time()),
            'lastseen'      => intval(time()),
            'connections'   => 0,
            'onlinetimes'   => 0,
            'signtimes'     => 0,
            'signdate'      => -1,
            'signkeep'      => 0,
            'playtotal'     => 0,
            'spectotal'     => 0,
            'alivetime'     => 0,
            'steamid'       => strval($s),
            'error'         => ':('
        );
    }

    public function Stats_Analytics($p, $t, $u, $s, $m, $map, $i) {

        $p = intval($p);
        $s = intval($s);
        $m = intval($m);

        $this->db->query("INSERT INTO `kcf_analytics` VALUES (DEFAULT, '$p', '$t', $u, $s, $m, '$map', -1, '$i');");

        if ($this->db->affected_rows > 0) {

            return array (
                'pid' => $p,
                'tid' => intval($this->db->insert_id)
            );
        }

        _log("Stats_Analytics: " . $this->db->error);

        return array (
            'pid' => $p,
            'tid' => -1
        );
    }

    public function Stats_Update($t, $p, $d, $o, $s, $a, $c) {

        $o = intval($o);
        $p = intval($p);
        $t = intval($t);
        $d = intval($d);
        $s = intval($s);
        $a = intval($a);
        $c = intval($c);

        if ($t <= 0) {

            if ($r = $this->db->query("SELECT `aid` FROM `kcf_analytics` WHERE `pid` = $p AND `connect_time` = $c AND `duration` = 0 ORDER BY `aid` DESC LIMIT 1;")) {

                if ($row = $r->fetch_array(MYSQLI_ASSOC)) {

                    $t = intval($row['aid']);
                    $r->free();
                }
            } else {
                _log("Failed to retirve tid from db -> $p : $c -> \n```sql\n" . $this->db->error . "\n```");
            }
        }

        if ($t > 0) {

            if (!$this->db->query("UPDATE `kcf_analytics` SET `duration` = $d WHERE `aid` = $t AND `pid` = $p;") || $this->db->affected_rows == 0) {
                _log("Stats_Update: Failed to update kcf_analytics -> $t:$p:$d -> \n```sql\n" . $this->db->error . "\n```");
            }
        }

        if ($o > 0 || $s > 0 || $a > 0) {
            
            if (!$this->db->query("UPDATE `kcf_stats` SET `playtotal`=`playtotal`+$o, `spectotal`=`spectotal`+$s, `alivetime`=`alivetime`+$a WHERE `pid` = $p;") || $this->db->affected_rows == 0) {
                _log("Stats_Update: Failed to update kcf_stats -> $t:$p:$d -> \n```sql\n" . $this->db->error . "\n```");
            }
        }

        if (!$this->db->query("UPDATE `kcf_players` SET `connections`=`connections`+1, `onlinetimes`=`onlinetimes`+$d WHERE `pid` = $p;") || $this->db->affected_rows == 0) {
            _log("Stats_Update: Failed to update kcf_stats -> $p:$d -> \n```sql\n" . $this->db->error . "\n```");
        }
    }

    public function Stats_DailySignIn($p, $o) {

        $p = intval($p);
        $o = intval($o);

        $r = $this->fetchFirst('kcf_players', 'pid', $p);

        if (!$r) {

            return array (
                'pid'    => $p,
                'result' => false,
                'error'  => '找不到指定玩家的信息'
            );
        }

        $l = intval($r['signdate']);
        $y = intval(date("ymd"), strtotime("-1 day"));
        $d = intval(date("ymd"));

        if ($d <= $r['signdate']) {

            return array (
                'pid'    => $p,
                'result' => false,
                'error'  => '每天只能签到一次'
            );
        }

        //$t = strtotime("-1 day") + 86400;
        $t = strtotime("-1 day", strtotime(date('Y-m-d')));

        $this->clear();

        if ($result = $this->db->query("SELECT SUM(`duration`) as onlines FROM `kcf_analytics` WHERE `pid` = $p AND `connect_time` >= $t;")) {

            if ($row = $result->fetch_array(MYSQLI_ASSOC)) {
                
                $o += intval($row['onlines']);
            }

            $result->free();
        }

        if (1800 >= $o) {

            return array (
                'pid'    => $p,
                'result' => false,
                'error'  => '你还需要在服务器内游玩' . (1800 - $o) . '秒才能进行签到'
            );
        }

        $k = ($l == $y) ? "signkeep+1" : "0";

        $this->db->query("UPDATE `kcf_players` SET `signtimes`=`signtimes`+1, `signdate`=$d, `signkeep`=$k WHERE `pid`='$p';");

        if ($this->db->affected_rows == 0) {

            return array (
                'pid'    => $p,
                'result' => false,
                'error'  => '数据查询失败,请稍候再试...'
            );
        }

        return array (
            'pid'    => $p,
            'result'    => true,
            'signkeep'  => intval(($l == $y) ? $r['signkeep']+1 : 1),
            'signtimes' => intval($r['signtimes']+1)
        );
    }

    public function Stats_IS_LoadUser($p) {

        $p = intval($p);

        if ($p <= 0) {
            
            _log("Stats_IS_LoadUser -> PId in json is wrong: $p", false);
            return array('pid' => $p);
        }

        $r = $this->fetchFirst('kcf_ins_pvp_skill', 'pid', $p);

        if (!$r) {

            if (!$this->db->query("INSERT INTO `kcf_ins_pvp_skill` (`pid`) VALUES ($p);") || $this->db->affected_rows == 0) {

                _log("Failed to insert new INS PVP client: -> $p -> \n```sql\n" . $this->db->error . "\n```");
            }
        }

        return array('pid' => $p);
    }

    public function Stats_IS_LoadAll() {

        if ($result = $this->db->query("SELECT * FROM `kcf_ins_pvp_skill` ORDER BY `score` DESC")) {

            $ret = array();

            while ($row = $result->fetch_array(MYSQLI_ASSOC))
            {
                $ret[] = array(
                    'pid'       => intval($row['pid']),
                    'score'     => floatval($row['score']),
                    'record'    => floatval($row['record'])
                );
            }

            $result->free();

            return $ret;
        }

        _log("Stats_IS_LoadAll: " . $this->db->error);

        return array();
    }
}
