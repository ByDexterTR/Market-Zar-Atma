#include <sourcemod>
#include <emitsoundany>
#include <store>

#pragma semicolon 1
#pragma newdecls required

ConVar g_minvalue = null, g_maxvalue = null, g_kredikati = null;

int deger[MAXPLAYERS + 1] = 0;
int miktar[MAXPLAYERS + 1] = 0;
bool oynadi[MAXPLAYERS + 1] = false, komutkapat = false;

public Plugin myinfo = 
{
	name = "[Market] Zar Atma!", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_zar", Command_Zar);
	HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd, EventHookMode_PostNoCopy);
	g_kredikati = CreateConVar("sm_zar_odul", "2", "Oyunu kazanan kişiye yatırdığı kredinin kaç katı gitsin!", FCVAR_NOTIFY, true, 0.0, false);
	g_minvalue = CreateConVar("sm_zar_min_miktar", "50", "Zar oynunda en az girilecek değer!", FCVAR_NOTIFY, true, 0.0, false);
	g_maxvalue = CreateConVar("sm_zar_max_miktar", "1000", "Zar oynunda en fazla girilecek değer!", FCVAR_NOTIFY, true, 0.0, false);
	AutoExecConfig(true, "Zar-Atma", "ByDexter");
}

public void OnMapStart()
{
	PrecacheSoundAny("ByDexter/zar/lose.mp3");
	AddFileToDownloadsTable("sound/ByDexter/zar/lose.mp3");
	PrecacheSoundAny("ByDexter/zar/win.mp3");
	AddFileToDownloadsTable("sound/ByDexter/zar/win.mp3");
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (deger[i] > 0)
		{
			deger[i] = 0;
			miktar[i] = 0;
			oynadi[i] = false;
		}
	}
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (deger[i] > 0)
		{
			deger[i] = 0;
			miktar[i] = 0;
			oynadi[i] = false;
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (deger[client] > 0)
	{
		deger[client] = 0;
		miktar[client] = 0;
		oynadi[client] = false;
	}
}

public Action Command_Zar(int client, int args)
{
	if (!komutkapat)
	{
		if (!oynadi[client])
		{
			char arg1[32];
			char arg2[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			if (args != 2 || StringToInt(arg1) < 1 || StringToInt(arg1) > 6 || StringToInt(arg2) < g_minvalue.IntValue || StringToInt(arg2) > g_maxvalue.IntValue)
			{
				ReplyToCommand(client, "[SM] Kullanım: sm_zar (1-6) (%d - %d)", g_minvalue.IntValue, g_maxvalue.IntValue);
				return Plugin_Handled;
			}
			else
			{
				if (Store_GetClientCredits(client) >= StringToInt(arg2))
				{
					deger[client] = StringToInt(arg1);
					miktar[client] = StringToInt(arg2);
					oynadi[client] = true;
					ReplyToCommand(client, "[SM] Bol şans umarım kazanırsın çünkü ben seni tutuyorum :)");
					return Plugin_Handled;
				}
				else
				{
					ReplyToCommand(client, "[SM] Cebinizde yeterli kredi yok!");
					return Plugin_Handled;
				}
			}
		}
		else
		{
			ReplyToCommand(client, "[SM] Bu el zaten %d zarına %d kredi yatırmışsın!", deger[client], miktar[client]);
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Zar oynamak için diğer turu beklemelisin!");
		return Plugin_Handled;
	}
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (komutkapat)
		komutkapat = false;
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	komutkapat = true;
	int sonuc = GetRandomInt(1, 6);
	PrintToChatAll("[SM] Çıkan zar: \x04%d", sonuc);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && oynadi[i])
		{
			if (deger[i] == sonuc)
			{
				EmitSoundToClientAny(i, "ByDexter/zar/win.mp3", SOUND_FROM_PLAYER, 1, 100);
				Give_Effect(i, { 0, 255, 0, 120 } );
				Store_SetClientCredits(i, Store_GetClientCredits(i) + miktar[i] * g_kredikati.IntValue);
				PrintToChat(i, "[SM] Zar çevirmede %d kredi kazandın! ^-^", miktar[i] * g_kredikati.IntValue);
			}
			else
			{
				EmitSoundToClientAny(i, "ByDexter/zar/lose.mp3", SOUND_FROM_PLAYER, 1, 100);
				Give_Effect(i, { 255, 0, 0, 120 } );
				Store_SetClientCredits(i, Store_GetClientCredits(i) - miktar[i]);
				PrintToChat(i, "[SM] Zar çevirmede %d kredi kaybettin! -_-", miktar[i]);
			}
			oynadi[i] = false;
		}
	}
}

void Give_Effect(int client, int Renk[4])
{
	int clients[1];
	clients[0] = client;
	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1, 0);
	Protobuf pb = UserMessageToProtobuf(message);
	pb.SetInt("duration", 200);
	pb.SetInt("hold_time", 40);
	pb.SetInt("flags", 17);
	pb.SetColor("clr", Renk);
	EndMessage();
} 