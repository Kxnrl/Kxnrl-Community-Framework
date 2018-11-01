--
-- Admin & operator lsit
--
CREATE TABLE `kcf_admins` (
  `aid` smallint(6) NOT NULL AUTO_INCREMENT,
  `adminName` varchar(32) DEFAULT NULL,
  `steamid` varchar(32) NOT NULL DEFAULT 'STEAM_ID_INVALID',
  `flags` varchar(32) DEFAULT NULL,
  `immunity` tinyint(3) unsigned NOT NULL DEFAULT '20',
  `lastseen` int(11) unsigned DEFAULT '0',
  `idname` varchar(10) DEFAULT NULL,
  `identity` varchar(32) DEFAULT NULL,
  `hide` tinyint(2) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`aid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
--  authorization of admin & operator
-- 
CREATE TABLE `kcf_admsrv` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `aid` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `srv_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `mod_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
--  player analytics system
-- 
CREATE TABLE `kcf_analytics` (
  `tid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `connect_time` int(11) unsigned NOT NULL DEFAULT '0',
  `connect_date` int(11) unsigned NOT NULL DEFAULT '0',
  `server_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `mod_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `map` varchar(128) DEFAULT NULL,
  `duration` smallint(5) unsigned NOT NULL DEFAULT '0',
  `ip` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`tid`),
  UNIQUE KEY `uk_connections` (`uid`,`connect_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Anit-proxy/vpn plugin
--
CREATE TABLE `kcf_antiproxy` (
  `steamid` int(11) unsigned NOT NULL DEFAULT '0',
  `ip` varchar(24) NOT NULL DEFAULT '0.0.0.0',
  `retry` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `result` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- banning
--
CREATE TABLE `kcf_bans` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `steamid` varchar(32) NOT NULL DEFAULT '0',
  `ip` varchar(24) DEFAULT NULL,
  `nickname` varchar(64) DEFAULT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

--
-- block players log
--
CREATE TABLE `kcf_blocks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bid` int(11) unsigned NOT NULL DEFAULT '0',
  `ip` varchar(32) DEFAULT NULL,
  `date` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

--
-- players list
--
CREATE TABLE `kcf_players` (
  `uid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `steamid` varchar(20) NOT NULL DEFAULT 'STEAMID_INVALID',
  `firstjoin` int(11) NOT NULL DEFAULT '-1',
  `lastseen` int(11) NOT NULL DEFAULT '-1',
  `connections` int(11) unsigned NOT NULL DEFAULT '0',
  `onlinetimes` int(11) unsigned NOT NULL DEFAULT '0',
  `signtimes` int(11) unsigned NOT NULL DEFAULT '0',
  `signdate` int(11) NOT NULL DEFAULT '-1',
  PRIMARY KEY (`uid`),
  UNIQUE KEY `uk_steamid` (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- servers list
--
CREATE TABLE `kcf_servers` (
  `sid` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `mod` smallint(5) unsigned NOT NULL DEFAULT '0',
  `hostname` varchar(128) NOT NULL DEFAULT 'Server Hostname',
  `ip` varchar(24) NOT NULL DEFAULT 'Server IP',
  `port` smallint(5) unsigned NOT NULL DEFAULT '27015',
  `rcon` varchar(32) NOT NULL DEFAULT 'Rcon Password',
  `display` tinyint(3) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`sid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- stats & analytics
--
CREATE TABLE `kcf_stats` (
  `sid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `playtotal` int(11) unsigned NOT NULL DEFAULT '0',
  `spectotal` int(11) unsigned NOT NULL DEFAULT '0',
  `playonct` int(11) unsigned NOT NULL DEFAULT '0',
  `playonte` int(11) unsigned NOT NULL DEFAULT '0',
  `aliveonct` int(11) unsigned NOT NULL DEFAULT '0',
  `aliveonte` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`sid`),
  UNIQUE KEY `uk_uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
