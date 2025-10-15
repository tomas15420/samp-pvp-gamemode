/*
 GM: PVP/TDM
 Autor: DeLeTe
 Version: 1.0
 Development: 11/2020
 Web: delete.4fan.cz
*/


#include <a_samp>
#include <izcmd>
#include <sscanf>
#include <a_mysql>
#include <timestamp>
//#include <a_http>
//#include <dof2>

#file "pvp"

#define function%0(%1) forward%0(%1); public%0(%1)

#define GM_NAME         "PVP/TDM"
#define GM_VER          "1.0"
#define SRV_NAME        "[CZ/SK] Players vs. Players"

#define MAX_TEAMS 		2 //Maxim�ln� po�et team� (nem�nit, nefungovalo by spr�vn�)
#define MIN_PSW_LEN		3 //Minim�ln� d�lka hesla
#define MAX_PSW_LEN		40 //Maxim�ln� d�lka hesla
#define MAX_TEAM_PLRS   4 //Maxim�ln� po�et hr��� na team
#define ROUNDS   	   	10 //Po�et kol
#define VOTE_TIME       20 //�as na hlasov�n� (sekundy)
#define COUNTDOWN       5 //Odpo�et do startu (sekundy)

#define DIALOG_ID      	1

//#define USER_FOLDER     "Users"
//#define USER_FILE       ""USER_FOLDER"/%s.txt"

#define SPD             ShowPlayerDialog
#define SCM             SendClientMessage
#define SCMTA           SendClientMessageToAll
#define IPC             IsPlayerConnected
#define IPA             IsPlayerAdmin

#define cg              "{00FF00}"
#define cr              "{FF0000}"
#define cw              "{FFFFFF}"
#define cy              "{FFFF00}"

#define GREEN           0x00FF00FF
#define RED             0xFF0000FF
#define WHITE           0xFFFFFFFF
#define YELLOW          0xFFFF00FF

#define DB_SERVER       "X"
#define DB_USER         "X"
#define DB_NAME         "X"
#define DB_PASS         "X"

new MySQL:mysql;

enum ENUM_Team
{
	tName[24],tColor,tPlayers,tKills,tDeaths,tScore
}

new Team[MAX_TEAMS][ENUM_Team] =
{
	{"Blue",0x34B1EBFF},
	{"Red",0xFF0000FF}
};

enum ENUM_Mode
{
	mRound,
	mMap,
	mPlayers,
	mRoundTime,
	mCountdown,
	mVoteTimer,
	bool: mStarted,
	bool: mHeadshot
}

new Mode[ENUM_Mode];

enum ENUM_Player
{
	ORM:pOrmId,
	pId,
	pUsername[MAX_PLAYER_NAME+1],
	pPassword[64+1],
	pSalt[10+1],
	pIP[16],
	pExited,
	pRegister,
	pLogged,
	pPlayed,
	pTeam,
	pKills,
	pDeaths,
	pAdmin,
	pFPS,
	pSpecId,
	pSkinId,
	bool:pDead,
	bool:pHitSound,
	pAntiAFK
}

new Player[MAX_PLAYERS][ENUM_Player];

new Rules[][] =
{
	{"1. Pravidlo"},
	{"2. Pravidlo"},
	{"3. Pravidlo"},
	{"4. Pravidlo"},
	{"5. Pravidlo"},
	{"6. Pravidlo"},
	{"7. Pravidlo"},
	{"8. Pravidlo"},
	{"9. Pravidlo"},
	{"10. Pravidlo"}
};

enum ENUM_Map
{
	mName[24],
	mInt,
	mRadius,
	Float:mPos1[4],
	Float:mPos2[4],
	Float:mZoneMinX,Float:mZoneMinY,Float:mZoneMaxX,Float:mZoneMaxY,
	mVotes
}

new Map[][ENUM_Map] =
{
	//Nazev  			int	radius	Team1                            		Team 2                           		Hranice
	{"Factory",			0,	5,		{275.2805,1410.2042,10.4402,90.0},		{121.1464,1409.3212,10.6011,270.0},		104.0,1335.5,290.0,1487.5,},
	{"Warehouses",		0,	5,		{1591.6371,720.5959,10.8203,270.0},		{1742.9609,721.6742,10.8203,90.0},		1575.0,661.5,1758.0,782.5},
	{"Ship",			0,	4,		{-1468.4930,1489.4552,8.2578,270.0},	{-1368.4109,1489.7048,11.0391,90.0},    -1482.0, 1479.0, -1360.0, 1501.5},
	{"Police Station", 	3,  2,      {241.6231,174.6623,1003.0234,180.0},    {203.0453,174.9729,1003.0234,180.0},    0.0,0.0,0.0,0.0}
};

new Text:TextdrawPanel;
new PlayerText:TextdrawText[MAX_PLAYERS];
new PlayerText:TextdrawSpec[MAX_PLAYERS];

main(){}

function secondTimer()
{
	if(Mode[mStarted] == true)
	{
		Mode[mRoundTime] ++;
	}
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
	    if(IPC(i) && Player[i][pLogged])
		{
		    updatePlayerTextdraws(i);
			if(!IsPlayerNPC(i) && Player[i][pDead] == false && Mode[mStarted] == true)
		    {
		        new mapid = Mode[mMap];
		        if(Map[mapid][mZoneMinX] != 0 && Map[mapid][mZoneMinY] != 0 && Map[mapid][mZoneMaxX] != 0 && Map[mapid][mZoneMaxY] != 0)
		        {
					if(!IsPlayerInArea(i,Map[mapid][mZoneMinX],Map[mapid][mZoneMinY],Map[mapid][mZoneMaxX],Map[mapid][mZoneMaxY]))
					{
						Player[i][pExited] --;
						if(Player[i][pExited] <= 0)
						{
						    SCM(i,RED,"Opustil si zonu, byl si usmrcen");
						    CallLocalFunction("OnPlayerDeath","iii",i,INVALID_PLAYER_ID,1);
						}
						else
						{
						    new str[128];
						    format(str,sizeof(str),"~r~Vrat se zpet do hraci zony!~n~%d",Player[i][pExited]);
						    GameTextForPlayer(i,str,1200,3);
						}
					}
					else Player[i][pExited] = 6;
		        }
		        Player[i][pAntiAFK] ++;
				if(Player[i][pAntiAFK] > 20)
				{
					CallLocalFunction("OnPlayerDeath","iii",i,INVALID_PLAYER_ID,1);
					SCM(i,-1,"Bylo detekov�no, �e jste �el AFK, byl jste p�esunut do re�imu sledov�n�");
				    switchToSpectate(i);
				}
		    }
		}
	}
	return 1;
}

public OnGameModeInit()
{
	AddPlayerClass(0,0,0,0,0,0,0,0,0,0,0);

    mysql = mysql_connect(DB_SERVER,DB_USER,DB_PASS,DB_NAME);
	mysql_log(ALL);
	if(mysql_errno(mysql) != 0)
	{
	    printf("[ "GM_NAME" ] MySQL connection to "DB_NAME" failed, shutting down");
	    SendRconCommand("exit");
	}
	else
	{
	    printf("[ "GM_NAME" ] MySQL connection to "DB_NAME" successfully established");
	}
	SetTimer("secondTimer",1000,true);

	SetGameModeText(""GM_NAME" "GM_VER"");
	EnableStuntBonusForAll(false);
	AllowInteriorWeapons(true);
	ShowPlayerMarkers(true);
	UsePlayerPedAnims();
	ShowNameTags(true);
	DisableInteriorEnterExits();
	
	Mode[mRound] = 1;
	Mode[mMap] = random(sizeof(Map));
	updateServerName();

	TextdrawPanel = TextDrawCreate(650.000000, 436.000000, "  ");
	TextDrawBackgroundColor(TextdrawPanel, 255);
	TextDrawFont(TextdrawPanel, 1);
	TextDrawLetterSize(TextdrawPanel, 0.500000, 1.800000);
	TextDrawColor(TextdrawPanel, -1);
	TextDrawSetOutline(TextdrawPanel, 0);
	TextDrawSetProportional(TextdrawPanel, 1);
	TextDrawSetShadow(TextdrawPanel, 1);
	TextDrawUseBox(TextdrawPanel, 1);
	TextDrawBoxColor(TextdrawPanel, 100);
	TextDrawTextSize(TextdrawPanel, -3.000000, 4.000000);
	TextDrawSetSelectable(TextdrawPanel, 0);

	print("+----------------------------------------------------+");
	print("|"GM_NAME" "GM_VER" by DeLeTe successfully started |");
	print("+----------------------------------------------------+");
	return 1;
}

public OnGameModeExit()
{
	//DOF2_Exit();
	TextDrawDestroy(TextdrawPanel);
	return 1;
}

public OnPlayerConnect(playerid)
{
	new str[100];

	SetPlayerColor(playerid,WHITE);
	Mode[mPlayers]++;

	Player[playerid][pTeam] = -1;
	Player[playerid][pSpecId] = -1;
	Player[playerid][pDead] = true;

	format(str,sizeof(str),"Hr�� "cg"%s "cw"(%d) se p�ipojil na server.",Jmeno(playerid),playerid);
	SCMTA(WHITE,str);
	
	Player[playerid][pUsername] = Jmeno(playerid);
	Player[playerid][pIP] = getIP(playerid);
	new ORM:ormid = Player[playerid][pOrmId] = orm_create("users");
	orm_addvar_int(ormid,Player[playerid][pId],"userId");
	orm_addvar_string(ormid,Player[playerid][pUsername],MAX_PLAYER_NAME+1,"userName");
	orm_addvar_string(ormid,Player[playerid][pPassword],64,"userPass");
	orm_addvar_string(ormid,Player[playerid][pSalt],10,"userSalt");
	orm_addvar_string(ormid,Player[playerid][pIP],16,"userIP");
	orm_addvar_int(ormid,Player[playerid][pRegister],"userRegister");
	orm_addvar_int(ormid,Player[playerid][pKills],"userKills");
	orm_addvar_int(ormid,Player[playerid][pDeaths],"userDeaths");
	orm_addvar_int(ormid,Player[playerid][pPlayed],"userPlayed");
	orm_addvar_int(ormid,Player[playerid][pSkinId],"userSkin");
	orm_addvar_int(ormid,Player[playerid][pAdmin],"userAdmin");
	orm_setkey(ormid,"userName");
	orm_select(ormid,"checkUserRegistration","i",playerid);

	CreatePlayerTextdraws(playerid);
	TextDrawShowForPlayer(playerid,TextdrawPanel);
	PlayerTextDrawShow(playerid,TextdrawText[playerid]);

	if(IsPlayerNPC(playerid))
	{
	    Player[playerid][pLogged] = gettime();
	    setTeam(playerid,random(2));
	    new Text3D:label = Create3DTextLabel(Jmeno(playerid),GetPlayerColor(playerid), 0.0,0.0,0.0,0.0,-1,0);
		Attach3DTextLabelToPlayer(label,playerid,0,0,1.5);
	}
	return 1;
}

function checkUserRegistration(playerid)
{
	if(orm_errno(Player[playerid][pOrmId]) == ERROR_OK)
		SPD(playerid,DIALOG_ID+1,DIALOG_STYLE_PASSWORD,"P�ihl�en�","Zadejte heslo, kter� jste zadal p�i registraci","P�ihl�en�","Odej�t");
	else
		SPD(playerid,DIALOG_ID,DIALOG_STYLE_PASSWORD,"Registrace","Zadejte heslo, kter�m se pozd�ji budete p�ihla�ovat","Registrovat","Odej�t");
	orm_setkey(Player[playerid][pOrmId],"userId");
	return 1;
}

public OnPlayerDisconnect(playerid,reason)
{
	new str[100];

	TextDrawHideForPlayer(playerid,TextdrawPanel);

	Mode[mPlayers]--;

	if(Player[playerid][pLogged])
	{
	    if(Player[playerid][pOrmId])
	    {
			saveUser(playerid);
			orm_destroy(Player[playerid][pOrmId]);
		}
	}
	Player[playerid][pDead] = true;
	
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
		if(IPC(i))
		{
		    if(Player[i][pSpecId] == playerid)
		    {
		        if(Player[i][pTeam] == -1 && getPlayingPlayers() > 0)
		        {
		            spectateNextPlayer(i,-1,true);
		        }
		        else if(Player[i][pTeam] != -1 && getPlayingPlayers(Player[i][pTeam]) > 0)
		        {
		            spectateNextPlayer(i,Player[i][pTeam],true);
		        }
		        else if(Player[i][pTeam] != -1 && getPlayingPlayers(Player[i][pTeam]) <= 0)
		        {
					nextRound();
		        }
		        else
				{
				 	TogglePlayerSpectating(i,false);
					Player[i][pSpecId] = -1;
					PlayerTextDrawHide(i,TextdrawSpec[i]);
					if(Player[i][pTeam] == -1)
					    showPlayerTeams(i);
				}
			}
		}
	}

	
	if(Player[playerid][pTeam] != -1)
		Team[Player[playerid][pTeam]][tPlayers] --;
	
	for(new i; ENUM_Player:i < ENUM_Player; i ++)
	    Player[playerid][ENUM_Player:i] = 0;
	switch(reason)
	{
		case 0: format(str,sizeof(str),"Hr�� "cr"%s "cw"(%d) ode�el ze serveru. ("cr"P�d hry"cw")",Jmeno(playerid),playerid);
		case 1: format(str,sizeof(str),"Hr�� "cr"%s "cw"(%d) ode�el ze serveru.",Jmeno(playerid),playerid);
		case 2: format(str,sizeof(str),"Hr�� "cr"%s "cw"(%d) ode�el ze serveru ("cr"Kick/Ban"cw").",Jmeno(playerid),playerid);
	}
	SCMTA(WHITE,str);
	
	if(!checkPlayers())
	{
	    pauseMatch("Nedostatek hr���");
	}
	
	if(Mode[mPlayers] <= 0)
	{
	    resetMatch();
	}
	return 1;
}

public OnPlayerText(playerid,text[])
{
	new str[200];
	if(IsPlayerLogged(playerid))
	{
	    if(text[0] == '-')
	    {
	        for(new i; i <= GetPlayerPoolSize(); i ++)
	        {
				if(IPC(i) && Player[i][pTeam] == Player[playerid][pTeam])
				{
				    format(str,sizeof(str),"[-Team] %s(%d): %s",Jmeno(playerid),playerid,text[1]);
				    SendLongMessage(i,(Player[i][pTeam] != -1) ? (Team[Player[playerid][pTeam]][tColor]) : (WHITE),str);
				}
	        }
	    }
	    else
	    {
			format(str,sizeof(str),"{%06x}%s(%d): "cw"%s",GetPlayerColor(playerid)>>>8,Jmeno(playerid),playerid,text);
		    SendLongMessageToAll(WHITE,str);
		}
	}
	else
	{
	    SCM(playerid,-1,"Pro psan� do chatu je nutn� se p�ihl�sit");
	}
	return 0;
}

public OnPlayerRequestSpawn(playerid)
{
	if(!IsPlayerLogged(playerid))
	{
		SCM(playerid,-1,"Nejd��v se p�ihla�te");
		return 0;
	} 
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(Player[playerid][pDead] == true)
	{
		spectatePlayers(playerid,Player[playerid][pTeam]);
	}
	else
	{
	    SetPlayerSkin(playerid,Player[playerid][pSkinId]);
		respawnPlayer(playerid);

		if(Mode[mStarted] == true)
		    givePlayerWeapons(playerid);
		else if(Mode[mCountdown] > 0)
		    TogglePlayerControllable(playerid,false);
	}
	return 1;
}

public OnPlayerDeath(playerid,killerid,reason)
{
	if(Mode[mStarted] == true)
	{
		if(IsPlayerLogged(playerid))
		{
		    Player[playerid][pDeaths] ++;
		    if(Player[playerid][pTeam] != -1)
		    {
		        Team[(Player[playerid][pTeam]+1)%2][tKills] ++;
		        Player[playerid][pDead] = true;
		        if(getPlayingPlayers(Player[playerid][pTeam]) > 0)
		        {
					spectatePlayers(playerid,Player[playerid][pTeam]);
				}
				else
				{
				    nextRound();
				}
			}
		}
		if(killerid != INVALID_PLAYER_ID && IsPlayerLogged(killerid))
		{
			SendDeathMessage(killerid,playerid,reason);
		    Player[killerid][pKills] ++;
			writeInKillList(killerid,playerid,GetPlayerWeapon(killerid));
		    updatePlayerTextdraws(killerid);
		}
		else if(killerid == INVALID_PLAYER_ID)
		{
		    writeInKillList(-1,playerid);
		}
	    updatePlayerTextdraws(playerid);
	}
 	return 1;
}

public OnPlayerUpdate(playerid)
{
	SetPlayerScore(playerid,Player[playerid][pKills]);

	Player[playerid][pAntiAFK] = 0;

	new drunk = GetPlayerDrunkLevel(playerid);
	if(drunk < 100)
	    SetPlayerDrunkLevel(playerid,2000);
	else
	{
	    new drunkOld = GetPVarInt(playerid,"DrunkLevel");
	    if(drunk != drunkOld)
	    {
			new fps = drunkOld-drunk;
			if(fps > 0 && fps < 256)
			    Player[playerid][pFPS] = fps;
	    }
		SetPVarInt(playerid,"DrunkLevel",drunk);
	}
	return 1;
}

function onUserRegister(playerid)
{
	Player[playerid][pLogged] = gettime();
	showPlayerTeams(playerid);
	SCM(playerid,-1,"Registrace prob�hla �sp�n�");
	return 1;
}

function checkPlayerLogin(playerid,pass[])
{
	new nHash[65];
	SHA256_PassHash(pass,Player[playerid][pSalt],nHash,64-1);
	if(strcmp(Player[playerid][pPassword],nHash,false) != 0) return SPD(playerid,DIALOG_ID+1,DIALOG_STYLE_PASSWORD,"P�ihl�en�","Zadejte heslo, kter� jste zadal p�i registraci\n\n"cr"�patn� heslo, zkuste to znovu","P�ihl�en�","Odej�t");
	Player[playerid][pLogged] = gettime();
	Player[playerid][pIP] = getIP(playerid);
	showInfo(playerid,playerid,true);
	SCM(playerid,-1,"P�ihl�en� prob�hlo �sp�n�");
	return 1;
}

public OnDialogResponse(playerid,dialogid,response,listitem,inputtext[])
{
	switch(dialogid)
	{
	    case DIALOG_ID:
	    {
	        if(response)
	        {
				if(!strlen(inputtext)) return SPD(playerid,DIALOG_ID,DIALOG_STYLE_PASSWORD,"Registrace","Zadejte heslo, kter�m se pozd�ji budete p�ihla�ovat","Registrovat","Odej�t");
				if(strlen(inputtext) < MIN_PSW_LEN) return SPD(playerid,DIALOG_ID,DIALOG_STYLE_PASSWORD,"Registrace","Zadejte heslo, kter�m se pozd�ji budete p�ihla�ovat\n\n"cr"Heslo je p��li� kr�tk�","Registrovat","Odej�t");
				if(strlen(inputtext) > MAX_PSW_LEN) return SPD(playerid,DIALOG_ID,DIALOG_STYLE_PASSWORD,"Registrace","Zadejte heslo, kter�m se pozd�ji budete p�ihla�ovat\n\n"cr"Heslo je p��li� dlouh�","Registrovat","Odej�t");
				new pass[64],salt[10];
				generatePassword(inputtext,pass,salt);
				format(Player[playerid][pPassword],64,pass);
				format(Player[playerid][pSalt],10,salt);
				Player[playerid][pRegister] = gettime();
				//loadUser(playerid);
				orm_insert(Player[playerid][pOrmId],"onUserRegister","i",playerid);
			}
	        else Kick(playerid);
	        return 1;
	    }
	    case DIALOG_ID+1:
	    {
	        if(response)
	        {
				if(!strlen(inputtext)) return SPD(playerid,DIALOG_ID+1,DIALOG_STYLE_PASSWORD,"P�ihl�en�","Zadejte heslo, kter� jste zadal p�i registraci","P�ihl�en�","Odej�t");
				orm_select(Player[playerid][pOrmId],"checkPlayerLogin","is",playerid,inputtext);
  			}
			else Kick(playerid);
			return 1;
		}
		case DIALOG_ID+2:
		{
		    if(response)
		    {
		        if(listitem < MAX_TEAMS)
		        {
		            if(Player[playerid][pTeam] == listitem) return SCM(playerid,-1,"U� jsi v tomto teamu");
		            if(!setTeam(playerid,listitem))
		                if(Player[playerid][pTeam] == -1)
							showPlayerTeams(playerid);
		        }
		        else
		        {
					switchToSpectate(playerid);
		        }
		    }
		    else
		    {
		        if(Player[playerid][pTeam] == -1)
		            showPlayerTeams(playerid);
		    }
		    return 1;
		}
		case DIALOG_ID+3:
		{
		    if(response && listitem < sizeof(Map))
		    {
		        new str[144],team = Player[playerid][pTeam];
		        if(Mode[mStarted] == false)
		        {
		        	Map[listitem][mVotes] ++;
		        	format(str,sizeof(str),"Hr�� {%06x}%s "cw"hlasoval pro mapu "cg"%s "cw"(%d hlas�)",(team != -1) ? (Team[team][tColor]>>>8) : (WHITE>>>8),Jmeno(playerid),Map[listitem][mName],Map[listitem][mVotes]);
					SCMTA(WHITE,str);
				}
			}
		    return 1;
		}
		case DIALOG_ID+4:
		{
			showPlayerTeams(playerid);
		}
	}
	return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	#define PRESSED(%0) \
	(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))

	if(Player[playerid][pSpecId] != -1)
	{
	    if(PRESSED(KEY_SPRINT))
	    {
	        spectateNextPlayer(playerid,Player[playerid][pTeam],true);
		}
		else if(PRESSED(KEY_JUMP))
		{
	        spectateNextPlayer(playerid,Player[playerid][pTeam],false);
		}
	}
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
	if(IPC(playerid) && IPC(damagedid) && Player[damagedid][pTeam] != Player[playerid][pTeam])
	{
	    if(Mode[mHeadshot] == true && bodypart == 9)
	    {
	        SetPlayerHealth(damagedid,0);
	    }
	    if(Player[playerid][pHitSound] == false)
	    {
	        PlayerPlaySound(playerid,17802,0,0,0);
	    }
	}
	return 1;
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
	if(!IsPlayerLogged(playerid))
	{
	    SCM(playerid,-1,"Nejd��v se p�ihlaste");
	    return 0;
	}
	return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	new str[144];
	if(!success)
	{
	    format(str,sizeof(str),"ERROR: P��kaz %s neexistuje -> "cg"/cmds",cmdtext);
		SCM(playerid,-1,str);
	}
	if(Player[playerid][pAdmin] == 0)
	{
		for(new i; i <= GetPlayerPoolSize(); i ++)
		{
		    if(IPC(i) && Player[i][pAdmin] > 0)
		    {
		        format(str,sizeof(str),"%s(%d) cmd: %s",Jmeno(playerid),playerid,cmdtext);
		        SCM(i,0x0FFE796FF,str);
		    }
		}
	}
	return 1;
}
//-debug cmds
CMD:kill(playerid,params[])
{
	if(!IPA(playerid)) return SCM(playerid,-1,"Nem�te povolen� pro pou�it� tohoto p��kazu");
	SetPlayerHealth(playerid,0);
	return 1;
}

CMD:warp(playerid,params[])
{
	if(!IPA(playerid)) return SCM(playerid,-1,"Nem�te povolen� pro pou�it� tohoto p��kazu");
	new Float:Pos[3];
	if(sscanf(params,"fff",Pos[0],Pos[1],Pos[2])) return SCM(playerid,-1,"/warp [ X ] [ Y ] [ Z ]");
	SetPlayerPos(playerid,Pos[0],Pos[1],Pos[2]);
	return 1;
}

CMD:interier(playerid,params[])
{
	if(!IPA(playerid)) return SCM(playerid,-1,"Nem�te povolen� pro pou�it� tohoto p��kazu");
	new str[128];
	format(str,sizeof(str),"Interi�r: %d",GetPlayerInterior(playerid));
	SCM(playerid,-1,str);
	return 1;
}

CMD:writeinkilllist(playerid,params[])
{
	if(!IPA(playerid)) return SCM(playerid,-1,"Nem�te povolen� pro pou�it� tohoto p��kazu");
	writeInKillList(playerid,playerid,GetPlayerWeapon(playerid));
	return 1;
}

CMD:test(playerid,params[])
{
	if(!IPA(playerid)) return SCM(playerid,-1,"Nem�te povolen� pro pou�it� tohoto p��kazu");
	if(strlen(params))
	{
	    new num = random(99);
	    for(new i; i < strval(params); i ++)
	    {
	        new name[50];
	        format(name,sizeof(name),"bot%02d_%02d",num,i);
	        ConnectNPC(name,"dgbot");
			strcat(name," connected");
			SCM(playerid,-1,name);
	    }
	}
	return 1;
}
//-----------------
CMD:cmds(playerid,params[])
{
	new DIALOG[500];
	strcat(DIALOG,""cg"[ Hr��sk� p��kazy ]\n");
	strcat(DIALOG,""cw"/teams, /pm, /time, /weather, /fps, /skin, /info, /admins, /hitsound, /rules");
	if(Player[playerid][pAdmin])
	{
	    strcat(DIALOG,"\n\n"cr"[ Administr�torsk� p��kazy ]\n");
	    strcat(DIALOG,""cw"/kick, /ban, /setskin, /hs");
	}
	if(IPA(playerid))
	{
	    strcat(DIALOG,"\n\n"cr"[ RCON p��kazy ]\n");
	    strcat(DIALOG,""cw"/setlvl, /gmx");
	}
	SPD(playerid,0,DIALOG_STYLE_MSGBOX,"P��kazy",DIALOG,"Zav��t","");
	return 1;
}

CMD:admins(playerid,params[])
{
	new admins,str[50],DIALOG[500];
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
		if(IPC(i) && Player[i][pAdmin] > 0)
		{
		    format(str,sizeof(str),"{%06x}%s(%d)\t"cg"[ ONLINE ]\n",GetPlayerColor(playerid)>>>8,Jmeno(i),i);
		    strcat(DIALOG,str);
		    admins ++;
		}
	}
	if(admins)
	    SPD(playerid,0,DIALOG_STYLE_TABLIST,"Online Administr�to�i",DIALOG,"Zav��t","");
	else
	    SPD(playerid,0,DIALOG_STYLE_TABLIST,"Online Administr�to�i","Na serveru aktu�lne nen� p�ipojen� ��dn� administr�tor","Zav��t","");

	return 1;
}

CMD:gmx(playerid,params[])
{
	if(!IPA(playerid)) return SCM(playerid,-1,"Mus�te b�t p�ihl�en� p�es "cr"RCON");
	SendRconCommand("gmx");
	return 1;
}

CMD:hs(playerid,params[])
{
	new str[144];
	if(Player[playerid][pAdmin] == 0) return SCM(playerid,-1,"Nem�te dostate�n� admin pr�va");
	if(Mode[mHeadshot] == false)
	    Mode[mHeadshot] = true;
	else
	    Mode[mHeadshot] = false;
	format(str,sizeof(str),"Administr�tor %s %s headshoty",Jmeno(playerid),(Mode[mHeadshot] != false) ? ("povolil") : ("zak�zal"));
	SCMTA(RED,str);
	return 1;
}

CMD:fps(playerid,params[])
{
	new str[144];
	format(str,sizeof(str),"Aktu�ln� hra b�� na: "cg"%d FPS",Player[playerid][pFPS]);
	SCM(playerid,-1,str);
	return 1;
}

CMD:skin(playerid,params[])
{
	new skin,str[200];
	if(Mode[mCountdown] > 0) return SCM(playerid,-1,"Te� nen� mo�n� nastavovat skin");
	if(sscanf(params,"i",skin)) return SCM(playerid,-1,"Pou�it�: "cr"/skin [ ID skinu ]");
	if(skin < 0 || skin > 311) return SCM(playerid,-1,"Rozmez� skin� je 0 - 311");
	switch(GetPlayerState(playerid))
	{
		case 0,7,9: SCM(playerid,-1,"Nejste spawnut�");
		default:
		{
		    SetPlayerSkinEx(playerid,skin);
		    format(str,sizeof(str),"Nastavil jste si skinid "cg"%d",skin);
		    SCM(playerid,-1,str);
		}
	}
	return 1;
}

CMD:setskin(playerid,params[])
{
	new id,skin,str[200];
	if(Player[playerid][pAdmin] == 0) return SCM(playerid,-1,"Nem�te dostate�n� admin pr�va");
	if(Mode[mCountdown] > 0) return SCM(playerid,-1,"Te� nen� mo�n� nastavovat skin");
	if(sscanf(params,"ii",id,skin)) return SCM(playerid,-1,"Pou�it�: "cr"/setskin [ ID ] [ ID skinu ]");
	if(!IPC(id)) return SCM(playerid,-1,"Hr�� s t�mto ID nen� p�ipojen");
	if(!IsPlayerLogged(id)) return SCM(playerid,-1,"Hr�� nen� p�ihl�en�");
	if(skin < 0 || skin > 311) return SCM(playerid,-1,"Rozmez� skin� je 0 - 311");
	switch(GetPlayerState(id))
	{
		case 0,7,9: SCM(playerid,-1,"Hr�� nen� spawnut�");
		default:
		{
		    SetPlayerSkinEx(id,skin);
		    TogglePlayerControllable(id,true);
		    if(id != playerid)
		    {
			    format(str,sizeof(str),"Nastavil si hr��i "cg"%s "cw"skinid "cg"%d",Jmeno(id),skin);
			    SCM(playerid,-1,str);
			    format(str,sizeof(str),"Administr�tor "cg"%s "cw"v�m nastavil skinid "cg"%d",Jmeno(playerid),skin);
			    SCM(id,-1,str);
			}
			else
			{
			    format(str,sizeof(str),"Nastavil jste si skinid "cg"%d",skin);
			    SCM(playerid,-1,str);
			}
		}
	}
	return 1;
}

CMD:hitsound(playerid,params[])
{
	new str[144];
	Player[playerid][pHitSound] = !Player[playerid][pHitSound];
	format(str,sizeof(str),"Hitsound: %s",(Player[playerid][pHitSound] != false) ? (""cr"Vypnut") : (""cg"Zapnut"));
	SCM(playerid,-1,str);
	return 1;
}

CMD:ban(playerid,params[])
{
	new id,reason[144],str[144];
	if(Player[playerid][pAdmin] == 0) return SCM(playerid,-1,"Nem�te dostate�n� admin pr�va");
	if(sscanf(params,"iz",id,reason) || !strlen(reason)) return SCM(playerid,-1,"Pou�it�: "cr"/ban [ ID ] [ D�vod ]");
	if(!IPC(id)) return SCM(playerid,-1,"Hr�� s t�mto ID nen� p�ipojen");
	if(id == playerid) return SCM(playerid,-1,"Nem��ete zabanovat s�m sebe");
	if(Player[id][pAdmin] > 0) return SCM(playerid,-1,"Nem��ete zabanovat administr�tora");
	format(str,sizeof(str),"Administr�tor %s zabanoval hr��e %s z d�vodu %s",Jmeno(playerid),Jmeno(id),reason);
	SendLongMessageToAll(RED,str);
	nBan(id,reason);
	return 1;
}

CMD:kick(playerid,params[])
{
	new id,reason[144],str[144];
	if(Player[playerid][pAdmin] == 0) return SCM(playerid,-1,"Nem�te dostate�n� admin pr�va");
	if(sscanf(params,"iz",id,reason) || !strlen(reason)) return SCM(playerid,-1,"Pou�it�: "cr"/kick [ ID ] [ D�vod ]");
	if(!IPC(id)) return SCM(playerid,-1,"Hr�� s t�mto ID nen� p�ipojen");
	if(id == playerid) return SCM(playerid,-1,"Nem��ete vyhodit s�m sebe");
	if(Player[id][pAdmin] > 0) return SCM(playerid,-1,"Nem��ete vyhodit administr�tora");
	format(str,sizeof(str),"Administr�tor %s vyhodil hr��e %s z d�vodu %s",Jmeno(playerid),Jmeno(id),reason);
	SendLongMessageToAll(RED,str);
	nKick(id);
	return 1;
}

CMD:specoff(playerid,params[])
{
	if(Player[playerid][pDead] == true && Player[playerid][pTeam] != -1) return SCM(playerid,-1,"Ve spectatu nem��e� zm�nit team");
	showPlayerTeams(playerid);
	return 1;
}

CMD:teams(playerid,params[])
{
	if(Player[playerid][pDead] == true && Player[playerid][pTeam] != -1) return SCM(playerid,-1,"Ve spectatu nem��e� zm�nit team");
	showPlayerTeams(playerid);
	return 1;
}

CMD:rules(playerid,parmas[])
{
	new DIALOG[sizeof(Rules)*128];
	for(new i; i < sizeof(Rules); i ++)
	{
	    strcat(DIALOG,Rules[i]);
	    strcat(DIALOG,"\n");
	}
	SPD(playerid,0,DIALOG_STYLE_MSGBOX,"Pravidla",DIALOG,"Zav��t","");
	return 1;
}

CMD:pm(playerid,params[])
{
	new id,text[144],str[200];
	if(sscanf(params,"iz",id,text)) return SCM(playerid,-1,"Pou�it�: "cr"/pm [ ID ] [ Text ]");
	if(!IPC(id)) return SCM(playerid,-1,"Hr�� s t�mto ID nen� p�ipojen");
	if(!IsPlayerLogged(id)) return SCM(playerid,-1,"Hr�� nen� p�ihl�en�");
	if(id == playerid) return SCM(playerid,-1,"S�m sob� si nem��ete poslat soukromou zpr�vu");
	format(str,sizeof(str),"[ PM ] Pro %s(%d): %s",Jmeno(id),id,text);
	SendLongMessage(id,YELLOW,str);
	format(str,sizeof(str),"[ PM ] Od %s(%d): %s",Jmeno(playerid),playerid,text);
	SendLongMessage(playerid,YELLOW,str);
	return 1;
}

CMD:info(playerid,params[])
{
	showInfo(playerid,playerid);
	return 1;
}

CMD:time(playerid,params[])
{
	new time,str[144];
	if(sscanf(params,"i",time)) return SCM(playerid,-1,"Pou�it�: "cr"/time [ 0-23 ]");
	if(time < 0 || time > 23) return SCM(playerid,-1,"Chybn� zadan� �as (0-23)");
	SetPlayerTime(playerid,time,0);
	format(str,sizeof(str),"�as nastaven na "cg"%02d:00",time);
	SCM(playerid,-1,str);
	return 1;
}

CMD:weather(playerid,params[])
{
	new weather,str[144];
	if(sscanf(params,"i",weather)) return SCM(playerid,-1,"Pou�it�: "cr"/weather [ ID Po�as� ]");
	switch(weather)
	{
	    case 0..50,100,250,2009:
	    {
			SetPlayerWeather(playerid,weather);
			format(str,sizeof(str),"Po�as� zm�n�no na ID "cg"%d",weather);
			SCM(playerid,-1,str);
	    }
	    default: SCM(playerid,-1,"Chybn� zadan� ID po�as� (0-50,100,250,2009)");
	}
	return 1;
}

CMD:setlvl(playerid,params[])
{
	new id,lvl,str[144];
	if(!IPA(playerid)) return SCM(playerid,-1,"Mus�te b�t p�ihl�en� p�es "cr"RCON");
	if(sscanf(params,"ii",id,lvl)) return SCM(playerid,-1,"Pou�it�: "cr"/setlvl [ ID ] [ 0-1 ]");
	if(!IPC(id)) return SCM(playerid,-1,"Hr�� s t�mto ID nen� p�ipojen");
	if(!IsPlayerLogged(id)) return SCM(playerid,-1,"Hr�� nen� p�ihl�en�");
	if(lvl < 0 || lvl > 1) return SCM(playerid,-1,"Chybn� zadan� admin level (0-1)");
	Player[id][pAdmin] = lvl;
	saveUser(playerid);
	format(str,sizeof(str),"Spr�vce %s %s hr��i %s admin pr�va",Jmeno(playerid),(lvl == 1) ? ("nastavil") : ("odebral"),Jmeno(id));
	SCMTA(RED,str);
	return 1;
}

function mapTimer()
{
	new map = random(sizeof(Map)),votes = Map[map][mVotes],str[144];
	for(new i; i < sizeof(Map); i ++)
	{
	    if(Map[i][mVotes] > votes)
	        map = i;
	}
	format(str,sizeof(str),"N�sleduj�c� mapa "cg"%s "cw"z�skala "cg"%d hlas�",Map[map][mName],Map[map][mVotes]);
	SCMTA(WHITE,str);
	Mode[mMap] = map;
	updateServerName();
	Mode[mRound] = 1;
	resetScore();
	if(checkPlayers())
	    startMatch();
	else
	    respawnPlayers();
	updateTextdraws();
	return 1;
}

function Countdown()
{
	new str[128];
	if(Mode[mCountdown] > 0 && Mode[mStarted] == false)
	{
		SetTimer("Countdown",1000,false);
	    Mode[mCountdown] --;
	    if(Mode[mCountdown] <= 0)
		{
		    if(checkPlayers())
		    {
			    format(str,sizeof(str),"~r~START");
			    Mode[mStarted] = true;
			    givePlayersWeapons();
			}
			else
			{
			    format(str,sizeof(str),"~r~NEDOSTATEK HRACU");
			}
		    Mode[mCountdown] = 0;
		    for(new i; i <= GetPlayerPoolSize(); i ++)
		        if(IPC(i) && IsPlayerLogged(i))
		            TogglePlayerControllable(i,true);
		}
		else
		    format(str,sizeof(str),"~g~%d",Mode[mCountdown]);
	    GameTextForAll(str,1200,3);
	}
	else Mode[mCountdown] = 0;
	return 1;
}

stock writeInKillList(killerid,deathid,gun = -1)
{
	new query[200];
	if(killerid != -1)
		mysql_format(mysql,query,sizeof(query),"INSERT INTO `kill_list` (killerId,deathId,killTeam,killGun,killTime) VALUES(%d,%d,%d,%d,%d)",Player[killerid][pId],Player[deathid][pId],Player[killerid][pTeam],gun,gettime());
	else
		mysql_format(mysql,query,sizeof(query),"INSERT INTO `kill_list` (deathId,killTeam,killTime) VALUES(%d,%d,%d)",Player[deathid][pId],(Player[deathid][pTeam]+1)%2,gettime());
	mysql_tquery(mysql,query,"");
	return 1;
}

stock updateServerName()
{
	new str[128];
	format(str,sizeof(str),"hostname %s [ %s ]",SRV_NAME,Map[Mode[mMap]][mName]);
	SendRconCommand(str);
	return 1;
}

stock switchToSpectate(playerid)
{
	new playingPlrs = getPlayingPlayers(),str[144];
    if(playingPlrs == 0 || (Player[playerid][pTeam] != -1 && playingPlrs == 1))
	{
		SCM(playerid,-1,"Aktu�ln� nikdo nehraje");
		showPlayerTeams(playerid);
		return 0;
	}
	if(Player[playerid][pTeam] != -1)
    {
        Team[Player[playerid][pTeam]][tPlayers] --;
        Player[playerid][pTeam] = -1;
    }
	if(!spectatePlayers(playerid,-1))
	{
	    SCM(playerid,-1,"Nepoda�ilo se sledovat hr��e, zkuste to znovu");
	    showPlayerTeams(playerid);
	}
	else Player[playerid][pDead] = true;
	updatePlayerTextdraws(playerid);
	format(str,sizeof(str),"Hr�� "cg"%s "cw"p�e�el do re�imu sledov�n�",Jmeno(playerid));
	SCMTA(WHITE,str);
	SCM(playerid,-1,"Re�im opust�te zm�nou teamu "cg"/teams");

	SetPlayerColor(playerid,WHITE);

	if(!checkPlayers())
	{
		pauseMatch("Nedostatek hr���");
	}
	return 1;
}

stock SetPlayerSkinEx(playerid,skinid)
{
	SetPlayerSkin(playerid,skinid);
	if(Mode[mCountdown] <= 0)
	    TogglePlayerControllable(playerid,true);
	Player[playerid][pSkinId] = skinid;
	return 1;
}

stock resetScore()
{
	for(new i; i < MAX_TEAMS; i ++)
		Team[i][tScore] = 0;
	return 1;
}

stock startMatch()
{
	if(Mode[mCountdown] <= 0)
	{
		new str[144];
	    Mode[mStarted] = false;
	    Mode[mCountdown] = COUNTDOWN;
	    resetRound();
	    format(str,sizeof(str),"Kolo %d odstartov�no",Mode[mRound]);
	    SCMTA(RED,str);
	    respawnPlayers();
		for(new i; i <= GetPlayerPoolSize(); i ++)
		{
		    if(IPC(i) && IsPlayerLogged(i))
		    {
		        TogglePlayerControllable(i,false);
		    }
		}
	    format(str,sizeof(str),"~g~%d",Mode[mCountdown]);
	    GameTextForAll(str,1200,3);
		SetTimer("Countdown",1000,false);
	}
	return 1;
}


stock voteMaps()
{
	new DIALOG[sizeof(Map)*30],str[144];
	Mode[mVoteTimer] = SetTimer("mapTimer",VOTE_TIME*1000,false);
	
	format(str,sizeof(str),"Hlasujte pro dal�� mapu, hlasov�n� bude ukon�eno za "cg"%d sekund",VOTE_TIME);
	SCMTA(WHITE,str);

	respawnPlayers();

	for(new i; i < sizeof(Map); i ++)
	{
		Map[i][mVotes] = 0;
	    strcat(DIALOG,Map[i][mName]);
	    strcat(DIALOG,"\n");
	}
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
	    if(IPC(i))
		{
			SPD(i,DIALOG_ID+3,DIALOG_STYLE_LIST,"Hlasov�n�",DIALOG,"Vybrat","Nehlasovat");
		}
	}
	return 1;
}

stock respawnPlayers()
{
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
	    if(IPC(i))
	    {
	        respawnPlayer(i);
	    }
	}
	return 1;
}

stock respawnPlayer(playerid)
{
	new map = Mode[mMap],team = Player[playerid][pTeam];
	if(team != -1)
	{
		switch(team)
		{
		    case 0:
		    {
		    	SetPlayerPos(playerid,Map[map][mPos1][0]-Map[map][mRadius]+random(Map[map][mRadius]*2),Map[map][mPos1][1]-5+random(10),Map[map][mPos1][2]);
		    	SetPlayerFacingAngle(playerid,Map[map][mPos1][3]);
			}
		    case 1:
		    {
		    	SetPlayerPos(playerid,Map[map][mPos2][0]-Map[map][mRadius]+random(Map[map][mRadius]*2),Map[map][mPos2][1]-5+random(10),Map[map][mPos2][2]);
		    	SetPlayerFacingAngle(playerid,Map[map][mPos2][3]);
			}
		}
		SetPlayerInterior(playerid,Map[map][mInt]);
		ResetPlayerWeapons(playerid);
		SetCameraBehindPlayer(playerid);
		SetPlayerHealth(playerid,100);
		SetPlayerArmour(playerid,100);
		Player[playerid][pDead] = false;
	}
	return 1;
}

stock checkPlayers()
{
	for(new i; i < MAX_TEAMS; i ++)
	    if(Team[i][tPlayers] <= 0)
	        return 0;
	return 1;
}

stock ResetPlayersWeapons()
{
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
	    if(IPC(i) && IsPlayerLogged(i))
		    ResetPlayerWeapons(i);
	}
	return 1;
}

stock pauseMatch(reason[] = "")
{
	if(Mode[mStarted] == true)
	{
		new str[144];
		if(strlen(reason))
		{
			format(str,sizeof(str),"Z�pas byl pozastaven [ d�vod: %s ]",reason);
			SCMTA(RED,str);
		}
		Mode[mStarted] = false;
/*		for(new i; i <= GetPlayerPoolSize(); i ++)
		{
		    if(IPC(i) && IsPlayerLogged(i) && Player[i][pSpecId] != -1 && Player[i][pTeam] != -1)
		    {
		        TogglePlayerSpectating(i,false);
		        PlayerTextDrawHide(i,TextdrawSpec[i]);
		        Player[i][pSpecId] = -1;
			}
		}
*/		ResetPlayersWeapons();
		resetRound();
		return 1;
	}
	return 0;
}

stock resetMatch()
{
	Mode[mRound] = 1;
	Mode[mRoundTime] = 0;
	for(new i; i < MAX_TEAMS; i ++)
	    Team[i][tScore] = 0;
}

stock resetRound()
{
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
	    if(IPC(i))
	    {
	        if(Player[i][pSpecId] != -1)
			{
			    TogglePlayerSpectating(i,false);
			    PlayerTextDrawHide(i,TextdrawSpec[i]);
			    Player[i][pSpecId] = -1;
			}
	        Player[i][pDead] = false;
	        //respawnPlayer(i);
	    }
	}
	return 1;
}

stock nextRound()
{
	new str[144],winteam;

	if(Team[0][tKills] > Team[1][tKills])
	{
	    Team[0][tScore] ++;
	    format(str,sizeof(str),"[%d/%d] Team {%06x}%s "cw"vyhr�l nad teamem {%06x}%s "cw"o %d kill� (%d kill� celkem)",Mode[mRound],ROUNDS,Team[0][tColor]>>>8,Team[0][tName],Team[1][tColor]>>>8,Team[1][tName],Team[0][tKills]-Team[1][tKills],Team[0][tKills]);
		winteam = 0;
	}
	else if(Team[0][tKills] < Team[1][tKills])
	{
	    Team[1][tScore] ++;
	    format(str,sizeof(str),"[%d/%d] Team {%06x}%s "cw"vyhr�l nad teamem {%06x}%s "cw"o %d kill� (%d kill� celkem)",Mode[mRound],ROUNDS,Team[1][tColor]>>>8,Team[1][tName],Team[0][tColor]>>>8,Team[0][tName],Team[1][tKills]-Team[0][tKills],Team[1][tKills]);
		winteam = 1;
	}
	else
	{
	    Team[0][tScore] ++;
	    Team[1][tScore] ++;
	    format(str,sizeof(str),"[%d/%d] Z�pas skon�il rem�zou (%d kill�)",Mode[mRound],ROUNDS,Team[0][tKills]);
	}
	SCMTA(WHITE,str);
	if(Mode[mRound] >= ROUNDS)
	{
		format(str,sizeof(str),"V�sledn� score {%06x}%02d "cw": {%06x}%02d",Team[winteam][tColor]>>>8,Team[winteam][tScore],Team[(winteam+1)%2][tColor]>>>8,Team[(winteam+1)%2][tScore]);
		SCMTA(WHITE,str);
		pauseMatch();
        voteMaps();
	}
	else
 	{
		format(str,sizeof(str),"Aktu�ln� score {%06x}%02d "cw": {%06x}%02d",Team[winteam][tColor]>>>8,Team[winteam][tScore],Team[(winteam+1)%2][tColor]>>>8,Team[(winteam+1)%2][tScore]);
		SCMTA(WHITE,str);
		Mode[mRound] ++;
		startMatch();
  	}
  	Mode[mRoundTime]= 0;
	Team[0][tKills] = 0;
	Team[1][tKills] = 0;
	updateTextdraws();
	return 1;
}

stock spectateNextPlayer(playerid,team = -1,bool:next = true)
{
	if(Player[playerid][pSpecId] != -1)
	{
	    new id = Player[playerid][pSpecId];

		do
		{
		    if(next == true)
		    {
			    id++;
			    if(id > GetPlayerPoolSize())
			        id = 0;
			}
			else
			{
			    id--;
			    if(id < 0)
			        id = GetPlayerPoolSize();
			}
		}
  		while(!IPC(id) || (team == -1 && Player[id][pTeam] == -1) || (team != -1 && Player[id][pTeam] != team || playerid == id) || Player[id][pDead] == true);

		spectatePlayer(playerid,id);
		return 1;
	}
	return 0;
}

stock spectatePlayer(playerid,id)
{
	if(IPC(id))
	{
		new str[128],name[MAX_PLAYER_NAME+1];
		format(name,sizeof(name),Jmeno(id));
		for(new i; i < sizeof(name); i ++)
		{
		    switch(name[i])
		    {
		        case '[': name[i] = '(';
		        case ']': name[i] = ')';
		    }
		}
		if(Player[playerid][pSpecId] == -1)
		{
			PlayerTextDrawShow(playerid,TextdrawSpec[playerid]);
			TogglePlayerSpectating(playerid,true);
		}
		Player[playerid][pSpecId] = id;
		PlayerSpectatePlayer(playerid,id);
		format(str,sizeof(str),"~w~Sledujes hrace ~b~~h~~h~%s ~n~~r~~h~SPACE ~w~pro dalsiho ~r~~h~SHIFT ~w~pro predchoziho hrace",name);
		PlayerTextDrawSetString(playerid,TextdrawSpec[playerid],str);
		PlayerTextDrawShow(playerid,TextdrawSpec[playerid]);
	}
	return 1;
}

stock spectatePlayers(playerid,team)
{
	new id = findPlayingPlayer(team);
	if(IPC(id))
	{
		spectatePlayer(playerid,id);
		return 1;
	}
	return 0;
}

stock findPlayingPlayer(team = -1)
{
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
	    if(IPC(i))
	    {
	        if(team == -1)
	        {
	            if(Player[i][pTeam] != -1 && Player[i][pDead] == false)
					return i;
			}
			else
			{
			    if(Player[i][pTeam] == team && Player[i][pDead] == false)
					return i;
			}
		}
	}
	return -1;
}

stock getPlayingPlayers(team = -1)
{
	new players;
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
	    if(IPC(i))
	    {
		    if(team == -1)
		    {
				if(Player[i][pTeam] != -1 && Player[i][pDead] == false)
				    players ++;
		    }
		    else
		    {
		        if(Player[i][pTeam] == team && Player[i][pDead] == false)
		            players++;
		    }
		}
	}
	return players;
}

stock nKick(playerid)
{
	SetTimerEx("KickAfterTime",30,false,"i",playerid);
	return 1;
}

stock nBan(playerid,reason[])
{
	SetPVarString(playerid,"BanReason",reason);
	SetTimerEx("BanAfterTime",30,false,"i",playerid);
	return 1;
}

function KickAfterTime(playerid)
{
	if(IPC(playerid))
		Kick(playerid);
}

function BanAfterTime(playerid)
{
	if(IPC(playerid))
	{
	    new reason[144];
	    GetPVarString(playerid,"BanReason",reason,sizeof(reason));
	    BanEx(playerid,reason);
	}
	else
	    SCMTA(RED,"Hr��e se nepoda�ilo zabanovat");
	return 1;
}

stock saveUser(playerid)
{
	if(Player[playerid][pOrmId] && IsPlayerLogged(playerid))
	{
	    Player[playerid][pPlayed] += gettime()-Player[playerid][pLogged];
	    Player[playerid][pLogged] = gettime();
	 	orm_update(Player[playerid][pOrmId]);
 	}
	return 1;
}
/*
stock loadUser(playerid)
{
	if(fexist(userFile(playerid)))
	{
		Player[playerid][pPlayed] = DOF2_GetInt(userFile(playerid),"Played");
		Player[playerid][pKills] = DOF2_GetInt(userFile(playerid),"Kills");
		Player[playerid][pDeaths] = DOF2_GetInt(userFile(playerid),"Deaths");
		Player[playerid][pSkinId] = DOF2_GetInt(userFile(playerid),"Skin");
		Player[playerid][pAdmin] = DOF2_GetInt(userFile(playerid),"Admin");
		DOF2_RemoveFile(userFile(playerid));
	 	return 1;
	}
	return 0;
}
*/
stock showInfo(playerid,toplayerid,bool:teams = false)
{
	if(IsPlayerLogged(playerid))
	{
	    new str[128],DIALOG[1000];
		strcat(DIALOG,"{0077FF}Z�kladn� �daje\t\n");
	    format(str,sizeof(str),"Nick\t"cg"%s\n",Jmeno(playerid));
		strcat(DIALOG,str);
	    format(str,sizeof(str),"Unik�tn� ID\t"cg"%d\n",Player[playerid][pId]);
		strcat(DIALOG,str);
	    format(str,sizeof(str),"Datum registrace\t"cg"%s\n",DATE(Player[playerid][pRegister]));
		strcat(DIALOG,str);
	    format(str,sizeof(str),"Odehran� �as\t"cg"%02d:%02d\n",(Player[playerid][pPlayed]+gettime()-Player[playerid][pLogged])/60/60,(Player[playerid][pPlayed]+gettime()-Player[playerid][pLogged])/60%60);
		strcat(DIALOG,str);
		strcat(DIALOG,"{0077FF}Score\t\n");
	    format(str,sizeof(str),"Zabit�\t"cg"%d\n",Player[playerid][pKills]);
		strcat(DIALOG,str);
	    format(str,sizeof(str),"Smrti\t"cg"%d\n",Player[playerid][pDeaths]);
		strcat(DIALOG,str);
	    format(str,sizeof(str),"K/D\t"cg"%0.2f\n",float(Player[playerid][pKills]+1)/float(Player[playerid][pDeaths]+1));
		strcat(DIALOG,str);
		if(teams == true)
			SPD(toplayerid,DIALOG_ID+4,DIALOG_STYLE_TABLIST,Jmeno(playerid),DIALOG,"Zav��t","");
		else
			SPD(toplayerid,0,DIALOG_STYLE_TABLIST,Jmeno(playerid),DIALOG,"Zav��t","");
	    return 1;
	}
	return 0;
}

stock givePlayerWeapons(playerid)
{
	GivePlayerWeapon(playerid,24,15000);
	GivePlayerWeapon(playerid,25,15000);
	GivePlayerWeapon(playerid,34,15000);
	SetPlayerArmedWeapon(playerid,0);

	SetPlayerHealth(playerid,100);
	SetPlayerArmour(playerid,100);
	return 1;
}

stock givePlayersWeapons()
{
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
	    if(IPC(i) && Player[i][pTeam] != -1)
	        givePlayerWeapons(i);
	}
	return 1;
}

stock setTeam(playerid,team)
{
	new str[128];
	if(Team[team][tPlayers] < MAX_TEAM_PLRS)
	{
		if(Player[playerid][pTeam] != -1)
	 	{
			Team[Player[playerid][pTeam]][tPlayers] --;
		}
		else
		{
		    if(Player[playerid][pSpecId] != -1)
		    {
		    	TogglePlayerSpectating(playerid,false);
				PlayerTextDrawHide(playerid,TextdrawSpec[playerid]);
				Player[playerid][pSpecId] = -1;
			}
		}
		Player[playerid][pTeam] = team;
		Team[team][tPlayers] ++;
		SetPlayerTeam(playerid,team);
		SetPlayerColor(playerid,Team[team][tColor]);
		format(str,sizeof(str),"Hr�� {%06x}%s"cw" (%d) se p�idal do teamu {%06x}%s",Team[team][tColor]>>>8,Jmeno(playerid),playerid,Team[team][tColor]>>>8,Team[team][tName]);
		SCMTA(WHITE,str);
		if(Mode[mStarted] == false)
		{
		    Player[playerid][pDead] = false;
			SpawnPlayer(playerid);
			if(checkPlayers())
			{
				startMatch();
			}
			else
			{
			    SCMTA(RED,"Aby mohl b�t z�pas odstartov�n, je t�eba alespo� jeden hr�� z druh�ho teamu");
			}
		}
		else
		{
		    if(checkPlayers())
		    {
			    Player[playerid][pDead] = true;
			    spectatePlayers(playerid,team);
			}
			else pauseMatch("Nedostatek hr���");
		}
		updatePlayerTextdraws(playerid);
	}
	else
	{
		SCM(playerid,-1,"Tento t�m je ji� pln�");
		return 0;
	}
	return 1;
}

stock showPlayerTeams(playerid)
{
	new DIALOG[(MAX_TEAMS+1)*50],str[50];
	for(new i; i < MAX_TEAMS; i ++)
	{
	    format(str,sizeof(str),"{%06x}%s\t[ Hr��i "cg"%d/%d "cw"]\n",Team[i][tColor] >>> 8,Team[i][tName],Team[i][tPlayers],MAX_TEAM_PLRS);
	    strcat(DIALOG,str);
	}
	strcat(DIALOG,"Spectator");
	SPD(playerid,DIALOG_ID+2,DIALOG_STYLE_TABLIST,"V�b�r teamu",DIALOG,"Vybrat","Zav��t");
	return 1;
}

stock IsPlayerLogged(playerid)
{
	if(Player[playerid][pLogged]) return 1;
	return 0;
}

stock generatePassword(psw[],hash[64],salt[10])
{
	for(new i; i < sizeof(salt); i ++)
	{
		salt[i] = random(79) + 47;
	}
	salt[sizeof(salt)-1] = 0;
	SHA256_PassHash(psw,salt,hash,64);
	return 1;
}

stock SendLongMessage(playerid,color,str[])
{
	new text[2][144];
	strmid(text[0],str,0,143);
	strmid(text[1],str,143,143*2);
	SCM(playerid,color,text[0]);
	if(strlen(text[1]))
	    SCM(playerid,color,text[1]);
	return 1;
}

stock SendLongMessageToAll(color,str[])
{
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
	    if(IPC(i))
	    {
	        SendLongMessage(i,color,str);
	    }
	}
	return 1;
}

stock userFile(playerid)
{
	new file[50];
	format(file,sizeof(file),USER_FILE,Jmeno(playerid));
	return file;
}

stock getIP(playerid)
{
	new IP[16];
	GetPlayerIp(playerid,IP,sizeof(IP));
	return IP;
}

stock Jmeno(playerid)
{
	new pName[MAX_PLAYER_NAME+1];
	GetPlayerName(playerid,pName,sizeof(pName));
	return pName;
}

stock updateTextdraws()
{
	for(new i; i <= GetPlayerPoolSize(); i ++)
	{
	    if(IPC(i))
	    {
	        updatePlayerTextdraws(i);
	    }
	}
	return 1;
}

stock updatePlayerTextdraws(playerid)
{
	new str[7*42];
	if(IsPlayerLogged(playerid))
	{
	    new team = Player[playerid][pTeam];
	    new score[40],kills[40],deaths[40],ratio[40],round[40],time[50],players[40],fps[40];
	    if(team != -1)
			format(score,sizeof(score),"score: ~r~%02d~w~:~b~~h~~h~%02d",Team[team][tScore],Team[(team+1)%2][tScore]);
		else
		{
		    new specId = Player[playerid][pSpecId];
		    if(specId != -1){
			    new specTeam = Player[specId][pTeam];
				format(score,sizeof(score),"score: ~r~%02d~w~:~b~~h~~h~%02d",Team[specTeam][tScore],Team[(specTeam+1)%2][tScore]);
			}
			else
				format(score,sizeof(score),"score: ~b~~h~~h~NaN");
		}
		format(kills,sizeof(kills),"kills: ~b~~h~~h~%02d",Player[playerid][pKills]);
		format(deaths,sizeof(deaths),"deaths: ~b~~h~~h~%02d",Player[playerid][pDeaths]);
		format(ratio,sizeof(ratio),"ratio: ~b~~h~~h~%0.2f",float(Player[playerid][pKills]+1)/float(Player[playerid][pDeaths]+1));
		format(round,sizeof(round),"kolo: ~b~~h~~h~%d~w~/~r~%d",Mode[mRound],ROUNDS);
		format(time,sizeof(time),"cas kola: ~b~~h~~h~%02d~w~:~b~~h~~h~%02d",Mode[mRoundTime]/60,Mode[mRoundTime]%60);
		format(players,sizeof(players),"hraci: ~b~~h~~h~%d",Mode[mPlayers]);
		format(fps,sizeof(fps),"FPS: ~b~~h~~h~%d",Player[playerid][pFPS]);

		format(str,sizeof(str),"~w~.:  %s  ~w~I  %s  ~w~I  %s  ~w~I  %s  ~w~I  %s  ~w~I  %s  ~w~I  %s  ~w~I  %s  ~w~:.",score,kills,deaths,ratio,round,time,players,fps);
		//print(str);
   		PlayerTextDrawSetString(playerid,TextdrawText[playerid],str);

	}
	return 1;
}

stock IsPlayerInArea(playerid, Float:MinX, Float:MinY, Float:MaxX, Float:MaxY)
{
    new Float:X, Float:Y, Float:Z;

    GetPlayerPos(playerid, X, Y, Z);
    if(X >= MinX && X <= MaxX && Y >= MinY && Y <= MaxY) {
        return 1;
    }
    return 0;
}

stock DATE(timestamp,type = -1)
{
	new str[32],year,month,day,hour,minute,second;
	TimestampToDate(timestamp, year, month, day, hour, minute, second, 2);
	switch(type)
	{
	    case 0: format(str,sizeof(str),"%02d.%02d.%d %02d:%02d",day,month,year,hour,minute);
	    case 1: format(str,sizeof(str),"%02d.%02d.%d %02d:%02d:%02d",day,month,year,hour,minute,second);
	    default: format(str,sizeof(str),"%02d.%02d.%d",day,month,year);
	}
	return str;
}

stock CreatePlayerTextdraws(playerid)
{
	TextdrawText[playerid] = CreatePlayerTextDraw(playerid,316.000000, 436.000000, "_");
	PlayerTextDrawAlignment(playerid,TextdrawText[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid,TextdrawText[playerid], 255);
	PlayerTextDrawFont(playerid,TextdrawText[playerid], 2);
	PlayerTextDrawLetterSize(playerid,TextdrawText[playerid], 0.239997, 1.000000);
	PlayerTextDrawColor(playerid,TextdrawText[playerid], -1);
	PlayerTextDrawSetOutline(playerid,TextdrawText[playerid], 1);
	PlayerTextDrawSetProportional(playerid,TextdrawText[playerid], 1);
	PlayerTextDrawSetSelectable(playerid,TextdrawText[playerid], 0);
	
	TextdrawSpec[playerid] = CreatePlayerTextDraw(playerid,630.000000, 380.000000, "");
	PlayerTextDrawAlignment(playerid,TextdrawSpec[playerid], 3);
	PlayerTextDrawBackgroundColor(playerid,TextdrawSpec[playerid], 255);
	PlayerTextDrawFont(playerid,TextdrawSpec[playerid], 2);
	PlayerTextDrawLetterSize(playerid,TextdrawSpec[playerid], 0.319999, 1.300000);
	PlayerTextDrawColor(playerid,TextdrawSpec[playerid], -1);
	PlayerTextDrawSetOutline(playerid,TextdrawSpec[playerid], 1);
	PlayerTextDrawSetProportional(playerid,TextdrawSpec[playerid], 1);
	PlayerTextDrawSetSelectable(playerid,TextdrawSpec[playerid], 0);
	return 1;
}
