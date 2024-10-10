#include <gba.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Main.h"
#include "FileHandling.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "cpu.h"
#include "ARM6502/Version.h"
#include "RenegadeVideo/Version.h"

#define EMUVERSION "V0.1.1 2024-10-10"

static void scalingSet(void);
static const char *getScalingText(void);
static void controllerSet(void);
static const char *getControllerText(void);
static void swapABSet(void);
static const char *getSwapABText(void);
static void fgrLayerSet(void);
static const char *getFgrLayerText(void);
static void bgrLayerSet(void);
static const char *getBgrLayerText(void);
static void sprLayerSet(void);
static const char *getSprLayerText(void);
static void coinASet(void);
static const char *getCoinAText(void);
static void coinBSet(void);
static const char *getCoinBText(void);
static void difficultSet(void);
static const char *getDifficultText(void);
static void livesSet(void);
static const char *getLivesText(void);
static void bonusSet(void);
static const char *getBonusText(void);
static void cabinetSet(void);
static const char *getCabinetText(void);
static void flipSet(void);
static const char *getFlipText(void);


const MItem dummyItems[] = {
	{"", uiDummy},
};
const MItem mainItems[] = {
	{"File->", ui2},
	{"Controller->", ui3},
	{"Display->", ui4},
	{"Settings->", ui5},
	{"Debug->", ui6},
	{"DipSwitches->", ui7},
	{"Help->", ui8},
	{"Sleep", gbaSleep},
	{"Restart", resetGame},
	{"Exit", ui10},
};
const MItem fileItems[] = {
	{"Load Game->", ui9},
	{"Load State", loadState},
	{"Save State", saveState},
	{"Save Settings", saveSettings},
	{"Reset Game", resetGame},
};
const MItem ctrlItems[] = {
	{"B Autofire: ", autoBSet, getAutoBText},
	{"A Autofire: ", autoASet, getAutoAText},
	{"Controller: ", controllerSet, getControllerText},
	{"Swap A-B:   ", swapABSet, getSwapABText},
};
const MItem displayItems[] = {
	{"Display: ", scalingSet, getScalingText},
	{"Scaling: ", flickSet, getFlickText},
	{"Gamma: ", gammaSet, getGammaText},
};
const MItem setItems[] = {
	{"Speed: ", speedSet, getSpeedText},
	{"Autoload State: ", autoStateSet, getAutoStateText},
	{"Autosave Settings: ", autoSettingsSet, getAutoSettingsText},
	{"Autopause Game: ", autoPauseGameSet, getAutoPauseGameText},
	{"EWRAM Overclock: ", ewramSet, getEWRAMText},
	{"Autosleep: ", sleepSet, getSleepText},
};
const MItem dipswitchItems[] = {
	{"Coin A: ", coinASet, getCoinAText},
	{"Coin B: ", coinBSet, getCoinBText},
	{"Difficulty: ", difficultSet, getDifficultText},
	{"Lives: ", livesSet, getLivesText},
	{"Bonus: ", bonusSet, getBonusText},
	{"Cabinet: ", cabinetSet, getCabinetText},
	{"Flip Screen: ", flipSet, getFlipText},
};
const MItem debugItems[] = {
	{"Debug Output:", debugTextSet, getDebugText},
	{"Disable Foreground:", fgrLayerSet, getFgrLayerText},
	{"Disable Background:", bgrLayerSet, getBgrLayerText},
	{"Disable Sprites:", sprLayerSet, getSprLayerText},
	{"Step Frame", stepFrame},
};
const MItem fnList9[] = {
	{"Renegade", quickSelectGame},
	{"Renegade (US bootleg)", quickSelectGame},
	{"Nekketsu Kouha Kunio-Kun (Japan)", quickSelectGame},
	{"Nekketsu Kouha Kunio-Kun (Japan bootleg)", quickSelectGame},
};
const MItem quitItems[] = {
	{"Yes", exitEmulator},
	{"No", backOutOfMenu},
};

const Menu menu0 = MENU_M("", uiNullNormal, dummyItems);
Menu menu1 = MENU_M("Main Menu", uiAuto, mainItems);
const Menu menu2 = MENU_M("File Handling", uiAuto, fileItems);
const Menu menu3 = MENU_M("Controller Settings", uiAuto, ctrlItems);
const Menu menu4 = MENU_M("Display Settings", uiAuto, displayItems);
const Menu menu5 = MENU_M("Other Settings", uiAuto, setItems);
const Menu menu6 = MENU_M("Debug", uiAuto, debugItems);
const Menu menu7 = MENU_M("Dipswitch Settings", uiDipswitches, dipswitchItems);
const Menu menu8 = MENU_M("Help", uiAbout, dummyItems);
const Menu menu9 = MENU_M("Load game", uiAuto, fnList9);
const Menu menu10 = MENU_M("Exit?", uiAuto, quitItems);

const Menu *const menus[] = {&menu0, &menu1, &menu2, &menu3, &menu4, &menu5, &menu6, &menu7, &menu8, &menu9, &menu10 };

u8 gGammaValue;

static char *const ctrlTxt[]   = {"1P","2P"};
static char *const dispTxt[]   = {"Unscaled","Scaled"};

static char *const coinTxt[]   = {"1 Coin - 1 Credit","1 Coin - 2 Credits","1 Coin - 3 Credits","2 Coins - 1 Credit"};
static char *const diffTxt[]   = {"Easy","Normal","Hard","Very Hard"};
static char *const livesTxt[]  = {"1","2"};
static char *const bonusTxt[]  = {"30K","None"};
static char *const cabTxt[]    = {"Cocktail","Upright"};


/// This is called at the start of the emulator
void setupGUI() {
	emuSettings = AUTOPAUSE_EMULATION;
//	keysSetRepeat(25, 4);	// Delay, repeat.
	menu1.itemCount = ARRSIZE(mainItems) - (enableExit?0:1);
	closeMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
}

/// This is called going from ui to emu.
void exitGUI() {
}

void quickSelectGame(void) {
	while (loadGame()) {
		redrawUI();
		return;
	}
	closeMenu();
}

void uiNullNormal() {
	uiNullDefault();
}

void uiAbout() {
	setupSubMenu("Help");
	drawText("Select: Insert coin",3);
	drawText("Start:  Start button",4);
	drawText("DPad:   Move character",5);
	drawText("R:      Jump",6);
	drawText("B:      Left attack",7);
	drawText("A:      Right attack",8);

	drawText("RenegadeGBA " EMUVERSION, 17);
	drawText("ARM6502     " ARM6502VERSION, 18);
	drawText("RenegadeVid " RENEGADEVERSION, 19);
}

void uiDipswitches() {
	char s[10];
	uiAuto();

	setMenuItemRow(15);
	int2Str(coinCounter0, s);
	drawSubItem("CoinCounter1:       ", s);
	int2Str(coinCounter1, s);
	drawSubItem("CoinCounter2:       ", s);
}

void nullUINormal(int key) {
}

void nullUIDebug(int key) {
}

void resetGame() {
	loadCart(0,0);
}


//---------------------------------------------------------------------------------
/// Switch between Player 1 & Player 2 controls
void controllerSet() {				// See io.s: refreshEMUjoypads
	joyCfg ^= 0x20000000;
}
const char *getControllerText() {
	return ctrlTxt[(joyCfg>>29)&1];
}


/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}
const char *getSwapABText() {
	return autoTxt[(joyCfg>>10)&1];
}

/// Turn on/off scaling
void scalingSet(){
	gScaling ^= 0x01;
	refreshGfx();
}
const char *getScalingText() {
	return dispTxt[gScaling];
}

/// Turn on/off rendering of foreground
void fgrLayerSet(){
	gGfxMask ^= 0x01;
}
const char *getFgrLayerText() {
	return autoTxt[gGfxMask&1];
}
/// Turn on/off rendering of background
void bgrLayerSet(){
	gGfxMask ^= 0x02;
}
const char *getBgrLayerText() {
	return autoTxt[(gGfxMask>>1)&1];
}
/// Turn on/off rendering of sprites
void sprLayerSet(){
	gGfxMask ^= 0x10;
}
const char *getSprLayerText() {
	return autoTxt[(gGfxMask>>4)&1];
}

/// Number of coins for credits
void coinASet() {
	int i = (gDipSwitch1+1) & 0x3;
	gDipSwitch1 = (gDipSwitch1 & ~0x3) | i;
}
const char *getCoinAText() {
	return coinTxt[gDipSwitch1 & 0x3];
}
/// Number of coins for credits
void coinBSet() {
	int i = (gDipSwitch1+4) & 0xC;
	gDipSwitch1 = (gDipSwitch1 & ~0xC) | i;
}
const char *getCoinBText() {
	return coinTxt[(gDipSwitch1>>2) & 0x3];
}
/// Game difficulty
void difficultSet() {
	int i = (gDipSwitch2+0x01) & 0x03;
	gDipSwitch2 = (gDipSwitch2 & ~0x03) | i;
}
const char *getDifficultText() {
	return diffTxt[gDipSwitch2 & 3];
}
/// Number of lifes to start with
void livesSet() {
	gDipSwitch1 ^= 0x10;
}
const char *getLivesText() {
	return livesTxt[(gDipSwitch1>>4) & 1];
}
/// At which score you get bonus lifes
void bonusSet() {
	gDipSwitch1 ^= 0x20;
}
const char *getBonusText() {
	return bonusTxt[(gDipSwitch1>>5) & 1];
}
/// Cocktail/upright
void cabinetSet() {
	gDipSwitch1 ^= 0x40;
}
const char *getCabinetText() {
	return cabTxt[(gDipSwitch1>>6) & 1];
}
/// Flip screen
void flipSet() {
	gDipSwitch1 ^= 0x80;
}
const char *getFlipText() {
	return autoTxt[(gDipSwitch1>>7) & 1];
}
