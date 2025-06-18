@del hello.o
@del hello.nes
@echo.
@echo Compiling...
ca65 hello.s -t nes -o hello.o
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Linking...
ld65 -o hello.nes -C hello.cfg hello.o
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Success!
@pause
@GOTO endbuild
:failure
@echo.
@echo Build error!
@pause
:endbuild
