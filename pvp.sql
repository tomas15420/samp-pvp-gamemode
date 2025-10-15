SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Struktura tabulky `kill_list`
--

CREATE TABLE `kill_list` (
  `killId` int(10) UNSIGNED NOT NULL,
  `killerId` int(10) UNSIGNED DEFAULT NULL,
  `deathId` int(10) UNSIGNED NOT NULL,
  `killTeam` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `killGun` int(11) NOT NULL DEFAULT -1,
  `killTime` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktura tabulky `users`
--

CREATE TABLE `users` (
  `userId` int(10) UNSIGNED NOT NULL,
  `userName` varchar(25) NOT NULL,
  `userPass` varchar(64) NOT NULL,
  `userSalt` varchar(10) NOT NULL,
  `userIP` varchar(16) NOT NULL,
  `userRegister` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `userKills` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `userDeaths` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `userPlayed` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `userSkin` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `userAdmin` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexy pro exportované tabulky
--

--
-- Indexy pro tabulku `kill_list`
--
ALTER TABLE `kill_list`
  ADD PRIMARY KEY (`killId`),
  ADD KEY `idx_killer` (`killerId`),
  ADD KEY `idx_death` (`deathId`);

--
-- Indexy pro tabulku `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`userId`),
  ADD UNIQUE KEY `userName` (`userName`);

--
-- AUTO_INCREMENT pro tabulky
--

--
-- AUTO_INCREMENT pro tabulku `kill_list`
--
ALTER TABLE `kill_list`
  MODIFY `killId` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pro tabulku `users`
--
ALTER TABLE `users`
  MODIFY `userId` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Omezení pro exportované tabulky
--

--
-- Omezení pro tabulku `kill_list`
--
ALTER TABLE `kill_list`
  ADD CONSTRAINT `fk_kill_death` FOREIGN KEY (`deathId`) REFERENCES `users` (`userId`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_kill_killer` FOREIGN KEY (`killerId`) REFERENCES `users` (`userId`) ON DELETE SET NULL;
COMMIT;

