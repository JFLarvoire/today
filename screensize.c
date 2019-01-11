/*****************************************************************************\
*                                                                             *
*   Function	    GetScreenRows / GetScreenColumns			      *
*                                                                             *
*   Description	    Get the number of rows or columns in the text screen      *
*                                                                             *
*   Notes	    							      *
*                                                                             *
*   History                                                                   *
*    2019-01-11 JFL For Windows, query CONOUT$ instead of stdout, to avoid    *
*                   getting witdth 1 when the output is redirected to a pipe. *
*                                                                             *
*                                                                             *
\*****************************************************************************/

/******************************************************************************
*                                                                             *
*                               OS/2 Version                                  *
*                                                                             *
******************************************************************************/

#ifdef _OS2

/* Make sure to include os2.h at the beginning of this file, and before that
    to define the INCL_VIO constant to enable the necessary section */

int GetScreenRows(void) {
  VIOMODEINFO vmi;

  VioGetMode(&vmi, 0);

  return vmi.row;
}

#endif

/******************************************************************************
*                                                                             *
*                               WIN32 Version                                 *
*                                                                             *
******************************************************************************/

#ifdef _WIN32

#ifndef STD_OUTPUT_HANDLE
#include <windows.h>
#endif

BOOL GetMyConsoleScreenBufferInfo(CONSOLE_SCREEN_BUFFER_INFO *pCsbi) {
  HANDLE hConsole;
  HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE);
  BOOL bDone;

  hConsole = CreateFile("CONOUT$", GENERIC_READ | GENERIC_WRITE, FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, 0);
  if (hConsole == INVALID_HANDLE_VALUE) hConsole = hStdout;

  bDone = GetConsoleScreenBufferInfo(hConsole, pCsbi);

  if (hConsole != hStdout) CloseHandle(hConsole);

  return bDone;
}

int GetScreenRows(void) {
  CONSOLE_SCREEN_BUFFER_INFO csbi;

  if (!GetMyConsoleScreenBufferInfo(&csbi))
    return 0;   /* Console size unknown */

  return csbi.srWindow.Bottom + 1 - csbi.srWindow.Top;
}

int GetScreenColumns(void) {
  CONSOLE_SCREEN_BUFFER_INFO csbi;

  if (!GetMyConsoleScreenBufferInfo(&csbi))
    return 0;   /* Console size unknown */

  return csbi.srWindow.Right + 1 - csbi.srWindow.Left;
}

#endif

/******************************************************************************
*                                                                             *
*                               MS_DOS Version                                *
*                                                                             *
******************************************************************************/

#ifdef _MSDOS

int GetScreenRows(void) {
  unsigned char far *fpc;

  fpc = (unsigned char far *)0x00400084L;   /* *fpc = Index of the last row */
  return *fpc + 1;               	    /* Number of rows */
}

int GetScreenColumns(void) {
  return *(int far *)0x0040004AL;
}

#endif

/*****************************************************************************\
*									      *
*				 Unix Version				      *
*									      *
\*****************************************************************************/

/* Requires linking with the  -ltermcap option */

#ifdef __unix__

#include <unistd.h>

#if defined(USE_TERMCAP) && USE_TERMCAP

#include <termcap.h>

static char term_buffer[2048];
static int tbInitDone = FALSE;

int init_terminal_data() {
  char *termtype;
  int success;

  if (tbInitDone) return 0;

  termtype = getenv ("TERM");
  if (termtype == 0) {
    printf("Specify a terminal type with `setenv TERM <yourtype>'.\n");
    exit(1);
  }

  success = tgetent (term_buffer, termtype);
  if (success < 0) {
    printf("Could not access the termcap data base.\n");
    exit(1);
  }
  if (success == 0) {
    printf("Terminal type `%s' is not defined.\n", termtype);
    exit(1);
  }

  tbInitDone = TRUE;
  return 0;
}

int GetScreenRows(void) {
  init_terminal_data();
  return tgetnum("li");
}

int GetScreenColumns(void) {
  init_terminal_data();
  return tgetnum("co");
}

#else

extern int errno;

/* Execute a command, and capture its output */
#define TEMP_BLOCK_SIZE 1024
char *Exec(char *pszCmd) {
  size_t nBufSize = 0;
  char *pszBuf = malloc(0);
  size_t nRead = 0;
  int iPid = getpid();
  char szTempFile[32];
  char *pszCmd2 = malloc(strlen(pszCmd) + 32);
  int iErr;
  FILE *hFile;
  sprintf(szTempFile, "/tmp/RowCols.%d", iPid);
  sprintf(pszCmd2, "%s >%s", pszCmd, szTempFile);
  iErr = system(pszCmd2);
  if (iErr) {
    free(pszBuf);
    return NULL;
  }
  /* Read the temp file contents */
  hFile = fopen(szTempFile, "r");
  while (1) {
    char *pszBuf2 = realloc(pszBuf, nBufSize + TEMP_BLOCK_SIZE);
    if (!pszBuf2) break;
    pszBuf = pszBuf2;
    nRead = fread(pszBuf+nBufSize, 1, TEMP_BLOCK_SIZE, hFile);
    nBufSize += TEMP_BLOCK_SIZE;
    if (nRead < TEMP_BLOCK_SIZE) break;
    if (feof(hFile)) break;
  }
  fclose(hFile);
  /* Cleanup */
  remove(szTempFile);
  free(pszCmd2);
  return pszBuf; /* Must be freed by the caller */
}

int GetScreenRows(void) {
  int nRows = 25; /* Default for VGA screens */
  /* char *pszRows = getenv("LINES"); */
  /* if (pszRows) nRows = atoi(pszRows); */
  char *pszBuf = Exec("tput lines");
  if (pszBuf) {
    nRows = atoi(pszBuf);
    free(pszBuf);
  }
  return nRows;
}

int GetScreenColumns(void) {
  int nCols = 80; /* Default for VGA screens */
  /* char *pszCols = getenv("COLUMNS"); */
  /* if (pszCols) nCols = atoi(pszCols); */
  char *pszBuf = Exec("tput cols");
  if (pszBuf) {
    nCols = atoi(pszBuf);
    free(pszBuf);
  }
  return nCols;
}

#endif

#endif

/******************************************************************************
*                                                                             *
*                         End of OS-specific routines                         *
*                                                                             *
******************************************************************************/

