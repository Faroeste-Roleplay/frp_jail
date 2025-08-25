CREATE TABLE `jail` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`charId` INT(11) NULL DEFAULT NULL,
	`jail_time` INT(11) NULL DEFAULT NULL,
	`date` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	PRIMARY KEY (`id`) USING BTREE,
	INDEX `charId` (`charId`) USING BTREE,
	CONSTRAINT `FK_jail_character` FOREIGN KEY (`charId`) REFERENCES `character` (`id`) ON UPDATE CASCADE ON DELETE CASCADE
)
COLLATE='latin1_swedish_ci'
ENGINE=InnoDB
AUTO_INCREMENT=0
;
