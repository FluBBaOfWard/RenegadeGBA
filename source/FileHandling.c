#include <gba.h>

//#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/dir.h>

#include "FileHandling.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Emubase.h"
#include "Main.h"
#include "GUI.h"
#include "Renegade.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"

static const char *const folderName = "acds";
static const char *const settingName = "settings.cfg";

ConfigData cfg;
static int selectedGame = 0;

static bool loadRoms(int gamenr, bool doLoad);

#define GAMECOUNT (3)
static const int gameCount = GAMECOUNT;
static const char *const gameNames[GAMECOUNT] = {"renegade","kuniokun","kuniokunb"};
static const char *const gameZipNames[GAMECOUNT] = {"renegade.zip","kuniokun.zip","kuniokunb.zip"};
static const int fileCount[GAMECOUNT] = {25,25,25};
static const char *const romFilenames[GAMECOUNT][25] = {
	{"na-5.ic52","nb-5.ic51",     "n0-5.ic13", "nc-5.bin",    "n1-5.ic1","n2-5.ic14","n6-5.ic28","n7-5.ic27","n8-5.ic26","n9-5.ic25",           "nh-5.bin","nn-5.bin","ni-5.bin","no-5.bin","nd-5.bin","nj-5.bin","ne-5.bin","nk-5.bin","nf-5.bin","nl-5.bin","ng-5.bin","nm-5.bin",                                     "n5-5.ic31","n4-5.ic32","n3-5.ic33"},
	{"ta18-11.bin","nb-01.bin",   "n0-5.bin",  "ta18-25.bin", "ta18-01.bin","ta18-06.bin","n7-5.bin","ta18-02.bin","ta18-04.bin","ta18-03.bin", "ta18-20.bin","ta18-14.bin","ta18-19.bin","ta18-13.bin","ta18-24.bin","ta18-18.bin","ta18-23.bin","ta18-17.bin","ta18-22.bin","ta18-16.bin","ta18-21.bin","ta18-15.bin", "ta18-07.bin","ta18-08.bin","ta18-09.bin"},
	{"ta18-11.bin","ta18-10.bin", "n0-5.bin",  "ta18-25.bin", "ta18-01.bin","ta18-06.bin","n7-5.bin","ta18-02.bin","ta18-04.bin","ta18-03.bin", "ta18-20.bin","ta18-14.bin","ta18-19.bin","ta18-13.bin","ta18-24.bin","ta18-18.bin","ta18-23.bin","ta18-17.bin","ta18-22.bin","ta18-16.bin","ta18-21.bin","ta18-15.bin", "ta18-07.bin","ta18-08.bin","ta18-09.bin"}
};
static const int romFilesizes[GAMECOUNT][25] = {
	{0x8000,0x8000, 0x8000, 0x8000, 0x8000,0x8000,0x8000,0x8000,0x8000,0x8000, 0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000, 0x8000,0x8000,0x8000},
	{0x8000,0x8000, 0x8000, 0x8000, 0x8000,0x8000,0x8000,0x8000,0x8000,0x8000, 0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000, 0x8000,0x8000,0x8000},
	{0x8000,0x8000, 0x8000, 0x8000, 0x8000,0x8000,0x8000,0x8000,0x8000,0x8000, 0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000,0x8000, 0x8000,0x8000,0x8000}
};

//---------------------------------------------------------------------------------
int loadSettings() {
//	FILE *file;
/*
	if (findFolder(folderName)) {
		return 1;
	}
	if ( (file = fopen(settingName, "r")) ) {
		fread(&cfg, 1, sizeof(ConfigData), file);
		fclose(file);
		if (!strstr(cfg.magic,"cfg")) {
			infoOutput("Error in settings file.");
			return 1;
		}
	} else {
		infoOutput("Couldn't open file:");
		infoOutput(settingName);
		return 1;
	}
*/
	g_dipSwitch0 = cfg.dipSwitch0;
	g_dipSwitch1 = cfg.dipSwitch1;
	g_dipSwitch2 = cfg.dipSwitch2;
	g_scaling    = cfg.scaling & 1;
	g_flicker    = cfg.flicker & 1;
	g_gammaValue = cfg.gammaValue;
	emuSettings  = cfg.emuSettings &~ EMUSPEED_MASK; // Clear speed setting.
	sleepTime    = cfg.sleepTime;
	joyCfg       = (joyCfg & ~0x400)|((cfg.controller&1)<<10);
//	strlcpy(currentDir, cfg.currentPath, sizeof(currentDir));

	infoOutput("Settings loaded.");
	return 0;
}
void saveSettings() {
//	FILE *file;

	strcpy(cfg.magic,"cfg");
	cfg.dipSwitch0  = g_dipSwitch0;
	cfg.dipSwitch1  = g_dipSwitch1;
	cfg.dipSwitch2  = g_dipSwitch2;
	cfg.scaling     = g_scaling & 1;
	cfg.flicker     = g_flicker & 1;
	cfg.gammaValue  = g_gammaValue;
	cfg.emuSettings = emuSettings & ~EMUSPEED_MASK; // Clear speed setting.
	cfg.sleepTime   = sleepTime;
	cfg.controller  = (joyCfg>>10)&1;
//	strlcpy(cfg.currentPath, currentDir, sizeof(currentDir));
/*
	if (findFolder(folderName)) {
		return;
	}
	if ( (file = fopen(settingName, "w")) ) {
		fwrite(&cfg, 1, sizeof(ConfigData), file);
		fclose(file);
		infoOutput("Settings saved.");
	} else {
		infoOutput("Couldn't open file:");
		infoOutput(settingName);
	}*/
	infoOutput("Settings saved.");
}

int loadNVRAM() {
	return 0;
}

void saveNVRAM() {
}
void loadState(void) {
	unpackState(testState);
	infoOutput("Loaded state.");
}
void saveState(void) {
	packState(testState);
	infoOutput("Saved state.");
}
/*
void loadState(void) {
	u32 *statePtr;
//	FILE *file;
	char stateName[32];

	if (findFolder(folderName)) {
		return;
	}
	strlcpy(stateName, gameNames[selectedGame], sizeof(stateName));
	strlcat(stateName, ".sta", sizeof(stateName));
	int stateSize = getStateSize();
	if ( (file = fopen(stateName, "r")) ) {
		if ( (statePtr = malloc(stateSize)) ) {
			fread(statePtr, 1, stateSize, file);
			unpackState(statePtr);
			free(statePtr);
			infoOutput("Loaded state.");
		} else {
			infoOutput("Couldn't alloc mem for state.");
		}
		fclose(file);
	}
}

void saveState(void) {
	u32 *statePtr;
//	FILE *file;
	char stateName[32];

	if (findFolder(folderName)) {
		return;
	}
	strlcpy(stateName, gameNames[selectedGame], sizeof(stateName));
	strlcat(stateName, ".sta", sizeof(stateName));
	int stateSize = getStateSize();
	if ( (file = fopen(stateName, "w")) ) {
		if ( (statePtr = malloc(stateSize)) ) {
			packState(statePtr);
			fwrite(statePtr, 1, stateSize, file);
			free(statePtr);
			infoOutput("Saved state.");
		} else {
			infoOutput("Couldn't alloc mem for state.");
		}
		fclose(file);
	}
}
*/
//---------------------------------------------------------------------------------
bool loadGame() {
	if (loadRoms(selected, false)) {
		return true;
	}
	selectedGame = selected;
	loadRoms(selectedGame, true);
	setEmuSpeed(0);
	loadCart(selectedGame,0);
	if (emuSettings & 4) {
		loadState();
	}
	return false;
}

bool loadRoms(int game, bool doLoad) {
//	int i, j, count;
//	bool found;
//	u8 *romArea = ROM_Space;
//	FILE *file;

//	count = fileCount[game];
/*
	chdir("/");			// Stupid workaround.
	if (chdir(currentDir) == -1) {
		return true;
	}

	for (i=0; i<count; i++) {
		found = false;
		if ( (file = fopen(romFilenames[game][i], "r")) ) {
			if (doLoad) {
				fread(romArea, 1, romFilesizes[game][i], file);
				romArea += romFilesizes[game][i];
			}
			fclose(file);
			found = true;
		} else {
			for (j=0; j<GAMECOUNT; j++) {
				if ( !(findFileInZip(gameZipNames[j], romFilenames[game][i])) ) {
					if (doLoad) {
						loadFileInZip(romArea, gameZipNames[j], romFilenames[game][i], romFilesizes[game][i]);
						romArea += romFilesizes[game][i];
					}
					found = true;
					break;
				}
			}
		}
		if (!found) {
			infoOutput("Couldn't open file:");
			infoOutput(romFilenames[game][i]);
			return true;
		}
	}
*/
	return false;
}
