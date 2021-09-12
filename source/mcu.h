// Renegade MCU emulation

#ifndef MCU_HEADER
#define MCU_HEADER

#ifdef __cplusplus
extern "C" {
#endif

void mcuReset(int type);
int mcuSaveState(void *destination);
int mcuLoadState(const void *source);
int mcuGetStateSize(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // MCU_HEADER
