#ifndef GUI_HEADER
#define GUI_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u8 gGammaValue;

void setupGUI(void);
void enterGUI(void);
void exitGUI(void);
void quickSelectGame(void);
void nullUINormal(int key);
void nullUIDebug(int key);
void resetGame(void);

void uiNullNormal(void);
void uiMainMenu(void);
void uiFile(void);
void uiAbout(void);
void uiController(void);
void uiDisplay(void);
void uiSettings(void);
void uiDipswitches(void);
void uiLoadGame(void);


#ifdef __cplusplus
} // extern "C"
#endif

#endif // GUI_HEADER
