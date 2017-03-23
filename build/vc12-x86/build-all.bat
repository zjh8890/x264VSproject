@echo off
if "%VS120COMNTOOLS%" == "" (
  msg "%username%" "Visual Studio 12 not detected"
  exit 1
)
if not exist x264.sln (
  call make-solutions.bat
)
if exist x264.sln (
  call "%VS120COMNTOOLS%\..\..\VC\vcvarsall.bat"
  MSBuild /property:Configuration="Release" x264.sln
  MSBuild /property:Configuration="Debug" x264.sln
  MSBuild /property:Configuration="RelWithDebInfo" x264.sln
)
