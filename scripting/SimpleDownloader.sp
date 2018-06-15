#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "[Any] Simple Downloader"
#define PLUGIN_VERSION "1.0.0"

ConVar hConVars[3];

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Keith Warren (Shaders Allen)",
	description = "Allows server operators to create/setup custom files for the server to download & precache.",
	version = PLUGIN_VERSION,
	url = "http://www.shadersallen.com/"
};

public void OnPluginStart()
{
	hConVars[0] = CreateConVar("simpledownloader_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hConVars[1] = CreateConVar("sm_simpledownloader_status", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hConVars[2] = CreateConVar("sm_simpledownloader_config", "configs/simpledownloader.cfg", "Full path of the configuration file to load: (IE: configs/simpledownloader.cfg)", FCVAR_NOTIFY);
	
	AutoExecConfig();
}

public void OnMapStart()
{
	if (!GetConVarBool(hConVars[1]))
	{
		return;
	}
	
	char sConVarPath[PLATFORM_MAX_PATH];
	GetConVarString(hConVars[2], sConVarPath, sizeof(sConVarPath));
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), sConVarPath);
	
	Handle hKV = CreateKeyValues("SimpleDownloader");
	
	if (FileToKeyValues(hKV, sPath))
	{
		if (KvJumpToKey(hKV, "Precache and Download"))
		{
			HandleFiles(hKV, true, true);
		}
		
		if (KvJumpToKey(hKV, "Precache"))
		{
			HandleFiles(hKV, true, false);
		}
		
		if (KvJumpToKey(hKV, "Download"))
		{
			HandleFiles(hKV, false, true);
		}
	}
	
	CloseHandle(hKV);
	LogMessage("Simple Downloader has successfully parsed the configuration file.");
}

void HandleFiles(Handle hKV, bool bPrecache, bool bDownload)
{
	if (KvJumpToKey(hKV, "materials") && KvGotoFirstSubKey(hKV, false))
	{
		char sMaterialTypes[2][8] = {"vtf", "vmt"};
		
		do {
			char sSectionName[64];
			KvGetSectionName(hKV, sSectionName, sizeof(sSectionName));
			
			char sValue[PLATFORM_MAX_PATH];
			KvGetString(hKV, NULL_STRING, sValue, sizeof(sValue));
			
			char sPath[PLATFORM_MAX_PATH];
			Format(sPath, sizeof(sPath), "materials/%s", sValue);
			
			if (!FileExists(sPath))
			{
				LogError("File '%s' doesn't exist, please verify its integrity.");
				continue;
			}
			
			char sFinalPath[PLATFORM_MAX_PATH];
			
			if (StrEqual(sSectionName, "both"))
			{
				for (int i = 0; i < 2; i++)
				{
					Format(sFinalPath, sizeof(sFinalPath), "%s.%s", sValue, sMaterialTypes[i]);
					
					if (bPrecache) PrecacheGeneric(sFinalPath, true);
					if (bDownload) AddFileToDownloadsTable(sPath);
				}
				
				continue;
			}
			
			int total;
			for (int i = 0; i < 2; i++)
			{
				if (StrEqual(sSectionName, sMaterialTypes[i]))
				{
					Format(sFinalPath, sizeof(sFinalPath), "%s.%s", sValue, sMaterialTypes[i]);
					
					if (bPrecache) PrecacheGeneric(sFinalPath, true);
					if (bDownload) AddFileToDownloadsTable(sPath);
					total++;
				}
			}
			
			if (total < 1)
			{
				LogError("Invalid file type requested for material '%s'. Possible Values: both, vtf, vmt", sValue);
			}
			
		} while KvGotoNextKey(hKV, false);
		
		KvGoBack(hKV);
	}
	
	if (KvJumpToKey(hKV, "models") && KvGotoFirstSubKey(hKV, false))
	{
		char sModelTypes[6][12] = {"dx80.vtx", "dx90.vtx", "mdl", "phy", "sw.vtx", "vvd"};
		
		do {
			char sSectionName[64];
			KvGetSectionName(hKV, sSectionName, sizeof(sSectionName));
			
			char sValue[PLATFORM_MAX_PATH];
			KvGetString(hKV, NULL_STRING, sValue, sizeof(sValue));
			
			char sPath[PLATFORM_MAX_PATH];
			Format(sPath, sizeof(sPath), "models/%s", sValue);
			
			if (!FileExists(sPath))
			{
				LogError("File '%s' doesn't exist, please verify its integrity.");
				continue;
			}
			
			char sFinalPath[PLATFORM_MAX_PATH];
			
			if (StrEqual(sSectionName, "all"))
			{
				for (int i = 0; i < 6; i++)
				{
					Format(sFinalPath, sizeof(sFinalPath), "%s.%s", sValue, sModelTypes[i]);
					
					if (bPrecache) PrecacheModel(sFinalPath, true);
					if (bDownload) AddFileToDownloadsTable(sPath);
				}
				
				continue;
			}
			
			int total;
			for (int i = 0; i < 6; i++)
			{
				if (StrEqual(sSectionName, sModelTypes[i]))
				{
					Format(sFinalPath, sizeof(sFinalPath), "%s.%s", sValue, sModelTypes[i]);
					
					if (bPrecache) PrecacheModel(sFinalPath, true);
					if (bDownload) AddFileToDownloadsTable(sPath);
					total++;
				}
			}
			
			if (total < 1)
			{
				LogError("Invalid file type requested for model '%s'. Possible Values: all, dx80.vtx, dx90.vtx, mdl, phy, sw.vtx, vvd", sValue);
			}
			
		} while KvGotoNextKey(hKV, false);
		
		KvGoBack(hKV);
	}
	
	if (KvJumpToKey(hKV, "sounds") && KvGotoFirstSubKey(hKV, false))
	{
		char sSoundTypes[2][12] = {"mp3", "wav"};
		
		do {
			char sSectionName[64];
			KvGetSectionName(hKV, sSectionName, sizeof(sSectionName));
			
			char sValue[PLATFORM_MAX_PATH];
			KvGetString(hKV, NULL_STRING, sValue, sizeof(sValue));
			
			char sPath[PLATFORM_MAX_PATH];
			Format(sPath, sizeof(sPath), "sound/%s", sValue);
			
			if (!FileExists(sPath))
			{
				LogError("File '%s' doesn't exist, please verify its integrity.");
				continue;
			}
			
			char sFinalPath[PLATFORM_MAX_PATH];
			
			int total;
			for (int i = 0; i < 2; i++)
			{
				if (StrEqual(sSectionName, sSoundTypes[i]))
				{
					Format(sFinalPath, sizeof(sFinalPath), "%s.%s", sValue, sSoundTypes[i]);
					
					if (bPrecache) PrecacheSound(sFinalPath, true);
					if (bDownload) AddFileToDownloadsTable(sPath);
					total++;
				}
			}
			
			if (total < 1)
			{
				LogError("Invalid file type requested for sound '%s'. Possible Values: mp3, wav", sValue);
			}
			
		} while KvGotoNextKey(hKV, false);
		
		KvGoBack(hKV);
	}
}