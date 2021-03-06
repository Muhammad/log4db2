@echo off
:: Copyright (c) 2012 - 2014, Andres Gomez Casanova (AngocA)
:: All rights reserved.
::
:: Redistribution and use in source and binary forms, with or without
:: modification, are permitted provided that the following conditions are met:
::
:: 1. Redistributions of source code must retain the above copyright notice,
::    this list of conditions and the following disclaimer.
:: 2. Redistributions in binary form must reproduce the above copyright notice,
::    this list of conditions and the following disclaimer in the documentation
::    and/or other materials provided with the distribution.
::
:: THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
:: AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
:: IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
:: ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
:: LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
:: CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
:: SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
:: INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
:: CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
:: ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
:: POSSIBILITY OF SUCH DAMAGE.

call init-dev.bat

db2 connect > NUL
if %ERRORLEVEL% NEQ 0 (
 echo Please connect to a database before the execution of the tests
) else (
 Setlocal EnableDelayedExpansion
 if "%1" == "-np" (
  set PAUSE=false
  set TIME_INI=echo !time!
 ) else (
  set PAUSE=true
 )
 if "!PAUSE!" == "true" (
  echo Executing all tests with pauses in between.
 ) else if "!PAUSE!" == "false" (
  echo Executing all test.
 ) else (
  echo Error expanding variable
  exit /B -1
 )
 call:executeTest TestsAppenders
 call:executeTest TestsCache
 call:executeTest TestsCascadeCallLimit
 call:executeTest TestsConfAppenders
 call:executeTest TestsConfiguration
 call:executeTest TestsConfLoggers
 call:executeTest TestsConfLoggersDelete
 call:executeTest TestsConfLoggersEffective
 set TEST=TestsFunctionGetDefinedParentLogger
 echo ====Next: !TEST!
 if "!PAUSE!" == "true" (
  pause
 )
 db2 -tf !SRC_MAIN_CODE_PATH!\CleanTriggers.sql +O
 call !SRC_TEST_SCRIPT_PATH!\test.bat !SRC_TEST_CODE_PATH!\!TEST!.sql
 db2 -tf !SRC_MAIN_CODE_PATH!\Trigger.sql +O
 call:executeTest TestsDynamicAppenders
 call:executeTest TestsGetLogger
 call:executeTest TestsGetLoggerName
 call:executeTest TestsHierarchy
 call:executeTest TestsLayout
 call:executeTest TestsLevels
 call:executeTest TestsLogs
 call:executeTest TestsMessages
 call:executeTest TestsReferences if not "!PAUSE!" == "true" (
  set TIME_END=echo !time!
  echo Difference:
  echo !TIME_INI! start
  echo !TIME_END! end
 )
 Setlocal DisableDelayedExpansion
 set PAUSE=
)
goto:eof

:: Execute a given test.
:executeTest
 set script=%~1
 echo ====Next: %script%
 if "!PAUSE!" == "true" (
  pause
 )
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\%script%.sql
goto:eof

