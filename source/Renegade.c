#include <gba.h>

#include "Renegade.h"
#include "Gfx.h"
#include "mcu.h"
#include "cpu.h"
#include "RenegadeVideo/RenegadeVideo.h"
#include "ARM6502/M6502.h"
//#include "ARM6809/ARM6809.h"


int packState(void *statePtr) {
	int size = renegadeSaveState(statePtr, &reVideo_0);
	size += mcuSaveState(statePtr+size);
	size += m6502SaveState(statePtr+size, &m6502Base);
//	size += m6809SaveState(statePtr+size, &m6809CPU0);
	return size;
}

void unpackState(const void *statePtr) {
	int size = renegadeLoadState(&reVideo_0, statePtr);
	size += mcuLoadState(statePtr+size);
	m6502LoadState(&m6502Base, statePtr+size);
//	size += m6809LoadState(&m6809CPU0, statePtr+size);
}

int getStateSize() {
	int size = renegadeGetStateSize();
	size += mcuGetStateSize();
	size += m6502GetStateSize();
//	size += m6809GetStateSize();
	return size;
}
