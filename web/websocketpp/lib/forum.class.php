<?php

class Forum
{
    protected $db = null;

    public function __construct() {

        $this->connect();
    }

    function connect() {

        if($this->db != null) {
            $this->db->close();
        }

        global $_config;
        $this->db = new \mysqli($_config['mysql']['host'], $_config['mysql']['user'], $_config['mysql']['pswd'], $_config['mysql']['db']['forum'], $_config['mysql']['port']);
    
        if($this->db->connect_errno) {
            throw new Exception("Failed to connect to database: " . $this->db->connect_error);
        }

        if(!$this->db->set_charset("utf8mb4")) {
            $this->db->Close();
            _log("duscuz: " . $this->db->error);
        }

        _sprintf("Connected to database: duscuz");
    }

    public function ping() {

        if(!$this->db->ping() || !($this->db->query("SELECT UNIX_TIMESTAMP();"))) {
            _log("Cannot ping MYSQL server.");
            $this->connect();
        }
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

    public function Forums_LoadUser($s) {

        $s = intval($s);

        if ($result = $this->db->query("SELECT a.uid, a.vipst, a.vipex, a.level, a.badges, b.username, a.signature FROM dxg_users a LEFT JOIN pre_common_member b ON a.uid = b.uid WHERE steamid='$steamid' LIMIT 1;")) {

            if ($row = $result->fetch_array(MYSQLI_ASSOC)) {

                $ret = array(
                    'username'  => $row['username'],
                    'uid'       => intval($row['uid']),
                    'level'     => intval($row['level']),
                    'badge'     => intval($row['badges']),
                    'signature' => $row['signature'],
                    'vipst'     => intval($row['vipst']),
                    'vipex'     => intval($row['vipex'])
                );

                $result->free();

                return $ret;
            }

            $result->free();

        } else {

            _log("Forums_LoadUser: $s ->" . $this->db->error);
        }

        return array(
            'username'  => 'UNKNOW NAME',
            'uid'       => -1,
            'level'     => -1,
            'badge'     => -1,
            'signature' => 'UNKNOW SIGNATURE',
            'vipst'     => -1,
            'vipex'     => -1
        );
    }

    public function Forums_LoadAll() {

        if ($result = $this->db->query("SELECT a.uid, a.vipst, a.vipex, a.level, a.badges, b.username, a.signature FROM dxg_users a LEFT JOIN pre_common_member b ON a.uid = b.uid")) {

            $ret = array();

            while ($row = $result->fetch_array(MYSQLI_ASSOC))
            {
                $ret[] = array(
                    'username'  => $row['username'],
                    'uid'       => intval($row['uid']),
                    'level'     => intval($row['level']),
                    'badge'     => intval($row['badges']),
                    'signature' => $row['signature'],
                    'vipst'     => intval($row['vipst']),
                    'vipex'     => intval($row['vipex'])
                );
            }

            $result->free();

            return $ret;

        } else {

            _log("Forums_LoadUser: $s ->" . $this->db->error);
        }

        return array();
    }
}
