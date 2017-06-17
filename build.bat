rmdir /S /Q build

mkdir build

xcopy zabbix build\zabbix /e /i
xcopy procexp build\procexp /e /i
xcopy gethostname build\gethostname /e /i

copy clever_install.nsi build

cd build

makensis clever_install.nsi

cd ..