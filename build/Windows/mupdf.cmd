@echo off
call %~dp0/wdk/setup %~n0 %*
setlocal
pushd %LB_PROJECT_ROOT%
git clean -fdx
call win32\generate.bat
pushd %LB_PROJECT_ROOT%\win32
set NAME=%LB_PROJECT_NAME%

if "%LB_TARGET_BITS%"=="32" set CUTSYMPOS=12
if "%LB_TARGET_BITS%"=="64" set CUTSYMPOS=11

echo.>sources.tmp
(for /f "usebackq tokens=1,2,3* delims==" %%i in (`findstr \thirdparty\jbig2dec libthirdparty.vcproj`) do if /I "%%~xj"==".c" echo %%j) >> sources.tmp
(for /f "usebackq tokens=1,2,3* delims==" %%i in (`findstr \thirdparty\openjpeg libthirdparty.vcproj`) do if /I "%%~xj"==".c" echo %%j) >> sources.tmp
(for /f "usebackq tokens=1,2,3* delims==" %%i in (`findstr \thirdparty\jpeg-8d libthirdparty.vcproj`) do if /I "%%~xj"==".c" echo %%j) >> sources.tmp
(for /f "usebackq tokens=1,2,3* delims==" %%i in (`findstr RelativePath lib%NAME%.vcproj`) do if /I "%%~xj"==".c" if /I NOT "%%~nj"=="memento" echo %%j) >> sources.tmp

cl -c %LB_CL_OPTS% -Fe%NAME%.dll -LD -I..\fitz -I..\thirdparty\jbig2dec -Dvsnprintf=_vsnprintf^
    -I..\thirdparty\jpeg-8d -DOPJ_STATIC=1 -I..\scripts -I..\thirdparty\openjpeg-1.5.0\libopenjpeg^
    -I"%~dp0\include" -I"%LB_PROJECT_ROOT%\..\freetype2\include" -I"%LB_PROJECT_ROOT%\..\zlib"^
    @sources.tmp

echo EXPORTS>%NAME%.def
link /LIB /OUT:%NAME%_static.lib *.obj
link /DUMP /LINKERMEMBER:1 %NAME%_static.lib | grep -E " [ 0-9A-Z]{7}[0-9A-Z] [A-Za-z_]+" | cut -b%CUTSYMPOS%- | sort | uniq >> %NAME%.def
link /DEF:%NAME%.def /OUT:%NAME%.dll %LB_LINK_OPTS% %NAME%_static.lib "%~dp0msvcrt_compat_%LB_TARGET_ARCH%.lib" %LB_ROOT%\bin\Windows\%LB_TARGET_ARCH%\freetype2.lib %LB_ROOT%\bin\Windows\%LB_TARGET_ARCH%\z.lib

call %~dp0/wdk/install %LB_PROJECT_NAME%.dll
call %~dp0/wdk/install %LB_PROJECT_NAME%.lib
call %~dp0/wdk/install %LB_PROJECT_NAME%.pdb
endlocal
popd
popd