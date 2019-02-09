#
# Structure for table "kcf_admins"
#

CREATE TABLE `kcf_admins` (
  `aid` smallint(5) NOT NULL AUTO_INCREMENT,
  `adminName` varchar(32) DEFAULT NULL,
  `steamid` bigint(20) unsigned NOT NULL DEFAULT '0',
  `flags` char(26) DEFAULT NULL,
  `authSrv` char(64) NOT NULL DEFAULT 'none',
  `authMod` char(64) NOT NULL DEFAULT 'none',
  `immunity` tinyint(3) unsigned NOT NULL DEFAULT '20',
  `idname` varchar(10) DEFAULT NULL,
  `identity` char(20) DEFAULT NULL,
  `hide` tinyint(2) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`aid`),
  UNIQUE KEY `uk_steamid` (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_adminlog"
#

CREATE TABLE `kcf_adminlog` (
  `id` int(11) unsigned NOT NULL DEFAULT '0',
  `aid` smallint(6) NOT NULL DEFAULT '0',
  `sid` smallint(5) unsigned NOT NULL DEFAULT '0',
  `action` varchar(32) DEFAULT NULL,
  `message` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_aid` (`aid`),
  CONSTRAINT `fk_aid` FOREIGN KEY (`aid`) REFERENCES `kcf_admins` (`aid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_ins_pvp_skill"
#

CREATE TABLE `kcf_ins_pvp_skill` (
  `pid` int(11) unsigned NOT NULL DEFAULT '0',
  `score` double(10,6) NOT NULL DEFAULT '0.000000',
  `record` double(10,6) NOT NULL DEFAULT '0.000000',
  `totalplay` int(11) unsigned NOT NULL DEFAULT '0',
  `lastseen` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_players"
#

CREATE TABLE `kcf_players` (
  `pid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `steamid` bigint(20) unsigned NOT NULL DEFAULT '0',
  `name` varchar(32) DEFAULT NULL,
  `firstjoin` int(11) NOT NULL DEFAULT '-1',
  `lastseen` int(11) NOT NULL DEFAULT '-1',
  `connections` int(11) unsigned NOT NULL DEFAULT '0',
  `onlinetimes` int(11) unsigned NOT NULL DEFAULT '0',
  `signtimes` int(11) unsigned NOT NULL DEFAULT '0',
  `signdate` int(11) NOT NULL DEFAULT '-1',
  `signkeep` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`pid`),
  UNIQUE KEY `uk_steamid` (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

#
# Structure for table "kcf_divorce"
#

CREATE TABLE `kcf_divorce` (
  `did` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `source` int(11) unsigned NOT NULL DEFAULT '0',
  `target` int(11) unsigned NOT NULL DEFAULT '0',
  `time` int(11) NOT NULL DEFAULT '0',
  `exp` int(11) NOT NULL DEFAULT '0',
  `lily` tinyint(3) NOT NULL DEFAULT '0',
  `date` int(11) NOT NULL DEFAULT '0',
  `divorce_time` int(11) NOT NULL DEFAULT '0',
  `divorce_source` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`did`),
  KEY `fk_uid_ds` (`source`),
  KEY `fk_uid_dt` (`target`),
  CONSTRAINT `fk_uid_ds` FOREIGN KEY (`source`) REFERENCES `kcf_players` (`pid`),
  CONSTRAINT `fk_uid_dt` FOREIGN KEY (`target`) REFERENCES `kcf_players` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_couples"
#

CREATE TABLE `kcf_couples` (
  `cpid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `source` int(11) unsigned NOT NULL DEFAULT '0',
  `target` int(11) unsigned NOT NULL DEFAULT '0',
  `time` int(11) NOT NULL DEFAULT '0',
  `exp` int(11) NOT NULL DEFAULT '0',
  `lily` tinyint(3) NOT NULL DEFAULT '0',
  `date` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`cpid`),
  KEY `fk_uid_s` (`source`),
  KEY `fk_uid_t` (`target`),
  CONSTRAINT `fk_uid_s` FOREIGN KEY (`source`) REFERENCES `kcf_players` (`pid`),
  CONSTRAINT `fk_uid_t` FOREIGN KEY (`target`) REFERENCES `kcf_players` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_analytics"
#

CREATE TABLE `kcf_analytics` (
  `aid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pid` int(11) unsigned NOT NULL DEFAULT '0',
  `ticket` char(36) NOT NULL DEFAULT 'INVALID_TICKET',
  `connect_time` int(11) unsigned NOT NULL DEFAULT '0',
  `server_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `mod_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `map` char(128) DEFAULT NULL,
  `duration` smallint(4) unsigned NOT NULL DEFAULT '0',
  `ip` char(20) DEFAULT NULL,
  PRIMARY KEY (`aid`),
  UNIQUE KEY `uk_connections` (`pid`,`connect_time`),
  KEY `uk_ticket` (`ticket`),
  CONSTRAINT `fk_uid_analytics` FOREIGN KEY (`pid`) REFERENCES `kcf_players` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_serverlog"
#

CREATE TABLE `kcf_serverlog` (
  `tid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `sid` smallint(5) unsigned NOT NULL DEFAULT '0',
  `map` varchar(128) DEFAULT NULL,
  `start` int(11) unsigned NOT NULL DEFAULT '0',
  `end` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`tid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_servers"
#

CREATE TABLE `kcf_servers` (
  `sid` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `mod` smallint(5) unsigned NOT NULL DEFAULT '0',
  `hostname` varchar(128) NOT NULL DEFAULT 'Server Hostname',
  `ip` varchar(24) NOT NULL DEFAULT 'Server IP',
  `port` smallint(5) unsigned NOT NULL DEFAULT '27015',
  `display` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `shortname` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`sid`),
  KEY `index_srv` (`ip`,`port`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_chat"
#

CREATE TABLE `kcf_chat` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `srvid` smallint(5) unsigned NOT NULL DEFAULT '0',
  `pid` int(11) unsigned NOT NULL DEFAULT '0',
  `message` varchar(255) DEFAULT NULL,
  `time` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_srvid` (`srvid`),
  KEY `fk_uid_c` (`pid`),
  CONSTRAINT `fk_srvid` FOREIGN KEY (`srvid`) REFERENCES `kcf_servers` (`sid`),
  CONSTRAINT `fk_uid_c` FOREIGN KEY (`pid`) REFERENCES `kcf_players` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_bans"
#

CREATE TABLE `kcf_bans` (
  `bid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `steamid` bigint(20) NOT NULL DEFAULT '0',
  `bCreated` int(11) unsigned NOT NULL DEFAULT '0',
  `bLength` int(11) unsigned NOT NULL DEFAULT '0',
  `bType` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `bSrv` smallint(3) unsigned NOT NULL DEFAULT '0',
  `bMod` smallint(5) unsigned NOT NULL DEFAULT '0',
  `bAdminId` tinyint(3) NOT NULL DEFAULT '0',
  `bReason` varchar(128) DEFAULT NULL,
  `bRemovedBy` tinyint(3) NOT NULL DEFAULT '-1',
  PRIMARY KEY (`bid`),
  KEY `index_steamid` (`steamid`),
  KEY `fk_srvid_ban` (`bSrv`),
  CONSTRAINT `fk_srvid_ban` FOREIGN KEY (`bSrv`) REFERENCES `kcf_servers` (`sid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_blocks"
#

CREATE TABLE `kcf_blocks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bid` int(11) unsigned NOT NULL DEFAULT '0',
  `ip` char(20) DEFAULT NULL,
  `date` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_bid` (`bid`),
  CONSTRAINT `fk_bid` FOREIGN KEY (`bid`) REFERENCES `kcf_bans` (`bid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

#
# Structure for table "kcf_stats"
#

CREATE TABLE `kcf_stats` (
  `sid` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pid` int(11) unsigned NOT NULL DEFAULT '0',
  `playtotal` int(11) unsigned NOT NULL DEFAULT '0',
  `spectotal` int(11) unsigned NOT NULL DEFAULT '0',
  `alivetime` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`sid`),
  UNIQUE KEY `uk_uid` (`pid`),
  CONSTRAINT `fk_uid_stats` FOREIGN KEY (`pid`) REFERENCES `kcf_players` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
