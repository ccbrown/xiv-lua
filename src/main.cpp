#include "Lua.h"
#include "FFXIV.h"
#include "Platform.h"

#include <fstream>
#include <string>
#include <unordered_set>

#include <dirent.h>

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

void AttemptTOCLoad(lua_State* L, const char* directory, std::unordered_set<std::string>* loaded) {
	if (!loaded->insert(directory).second) { return; }

	std::ifstream toc(std::string(directory) + "/scripts.toc");
	for (std::string line; std::getline(toc, line);) {
		if (line.empty()) { continue; }

		if (line.find("#dependency ") == 0) {
			AttemptTOCLoad(L, (std::string("interface/") + line.substr(12)).c_str(), loaded);
			continue;
		}
		
		auto file = std::string(directory) + '/' + line;
		printf("running %s\n", file.c_str());
		LuaRunFile(L, file.c_str());
	}
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
	
	std::unordered_set<std::string> loaded;
	
	AttemptTOCLoad(lua, "interface", &loaded);
	
	if (auto dir = opendir("interface")) {
		while (auto ent = readdir(dir)) {
			if (*ent->d_name != '.') {
				AttemptTOCLoad(lua, (std::string("interface/") + ent->d_name).c_str(), &loaded);
			}
		}
		closedir(dir);
	}

    int ret = app.exec();

	LuaClose(lua);

	return ret;
}
