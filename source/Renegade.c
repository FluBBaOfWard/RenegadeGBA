#include <gba.h>

#include "Renegade.h"
#include "Gfx.h"
#include "mcu.h"
#include "ARM6502/M6502.h"
#include "RenegadeVideo/RenegadeVideo.h"


int packState(void *statePtr) {
	int size = renegadeSaveState(statePtr, &reVideo_0);
	size += mcuSaveState(statePtr+size);
	size += m6502SaveState(statePtr+size, &m6502OpTable);
	return size;
}

void unpackState(const void *statePtr) {
	int size = renegadeLoadState(&reVideo_0, statePtr);
	size += mcuLoadState(statePtr+size);
	m6502LoadState(&m6502OpTable, statePtr+size);
}

int getStateSize() {
	int size = renegadeGetStateSize();
	size += mcuGetStateSize();
	size += m6502GetStateSize();
	return size;
}
