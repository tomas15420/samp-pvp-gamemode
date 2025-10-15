
# GM: PVP/TDM (Players vs. Players)

Jednoduchý herní mód **PVP/TDM** (Player vs. Player / Team Deathmatch) pro SA-MP 0.3.7 R2.
## Informace

* **Herní mód:** PVP/TDM
* **Autor:** DeLeTe
* **Verze:** 1.0
* **Vývoj:** 11/2020
* **Web:** [delete.4fan.cz](http://delete.4fan.cz)

---

## Instalace

Pro zprovoznění herního módu postupujte podle následujících kroků.

### 1. Import databáze

Importujte soubor `pvp.sql` do vaší MySQL databáze.

### 2. Konfigurace Gamemodu

Otevřete a upravte soubor `gamemodes/pvp.pwn`.

#### 2.1 Základní nastavení serveru

```pawn
#define GM_NAME         "PVP/TDM"
#define GM_VER          "1.0"
#define SRV_NAME        "[CZ/SK] Players vs. Players"
```
#### 2.2 Připojení k databázi
Nastavte vaše přihlašovací údaje k MySQL databázi.
```pawn
#define DB_SERVER "db_server"
#define DB_USER "db_uzivatel"
#define DB_NAME "nazev_db"
#define DB_PASS "heslo_db"
```
#### 2.2 Parametry serveru (Volitelné)
Můžete upravit další parametry hry
```pawn
#define MAX_TEAMS 		2   // Maximální počet teamů (neměnit, nefungovalo by správně)
#define MIN_PSW_LEN		3   // Minimální délka hesla
#define MAX_PSW_LEN		40  // Maximální délka hesla
#define MAX_TEAM_PLRS   4   // Maximální počet hráčů na team
#define ROUNDS   	   	10  // Počet kol
#define VOTE_TIME       20  // Čas na hlasování (sekundy)
#define COUNTDOWN       5   // Odpočet do startu (sekundy)
```
### 3. Stažení pluginů
Pro správnou funkci módu jsou potřeba následující pluginy.

* **MySQL R41-4:** [Stáhnout zde](https://github.com/pBlueG/SA-MP-MySQL/releases/tag/R41-4)
* **Crashdetect (Volitelné):** [Stáhnout zde](https://github.com/Y-Less/samp-plugin-crashdetect/releases/tag/v4.22)

### 4. Úprava `server.cfg`

Do souboru `server.cfg` přidejte nebo upravte následující řádky:
```
gamemode0 pvp 
plugins crashdetect mysql
```
*Poznámka: Pokud používáte Linux, nezapomeňte na příponu `.so` (např. `mysql.so`). Plugin `crashdetect` je volitelný.*

### 5. Spuštění serveru
Uložte všechny změny a spusťte server. 
## Licence 
Tento projekt je licencován pod **MIT licencí**. Znění licence naleznete v souboru [LICENSE](LICENSE).