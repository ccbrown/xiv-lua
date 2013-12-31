#include "Lua.h"
#include "FFXIV.h"
#include "Platform.h"

#include <fstream>
#include <string>

#include <windows.h>

#include <QtWidgets/QApplication>

bool CheckPrivileges() {
	HANDLE token;
	
	if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ALL_ACCESS, &token)) {
		return false;
	}
	
    TOKEN_PRIVILEGES tp;
    LUID luid;

    if (!LookupPrivilegeValue(nullptr, "SeDebugPrivilege", &luid)) {
        return false; 
    }

    tp.PrivilegeCount = 1;
    tp.Privileges[0].Luid = luid;
    tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;

    if (!AdjustTokenPrivileges(token, false, &tp, sizeof(TOKEN_PRIVILEGES), nullptr, nullptr)) { 
          return false;
    } 

    if (GetLastError() == ERROR_NOT_ALL_ASSIGNED) {
          return false;
    } 

	return true;
}

int main(int argc, char* argv[]) {
	if (!CheckPrivileges()) {
		MessageBox(nullptr, "This program must be run as administrator.", "Error", MB_ICONERROR | MB_OK);
		return 1;
	}

    QApplication app(argc, argv);
	
	auto lua = LuaOpen();
	PlatformInit(lua);
	FFXIVInit(lua);
	
	std::ifstream toc("interface/scripts.toc");
	for (std::string line; std::getline(toc, line);) {
		if (!line.empty()) {
			auto file = std::string("interface/") + line;
			printf("running %s\n", file.c_str());
			LuaRunFile(lua, file.c_str());
		}
	}

    int ret = app.exec();

	LuaClose(lua);

	return ret;
}
