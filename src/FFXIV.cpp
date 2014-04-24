#include "FFXIV.h"

#include "Platform.h"

#include <windows.h>
#include <psapi.h>
#include <tlhelp32.h>

#include <QtCore/QTimer>

static lua_State* gLuaState = nullptr;

struct FFXIVUnit {
	bool exists = false;
	char name[0x44]{};
	uint32_t id = 0;
	uint32_t currentHP = 0;
	uint32_t maxHP = 0;
	uint32_t currentMP = 0;
	uint32_t maxMP = 0;
	uint32_t currentTP = 0;
	uint32_t target = 0;
};

static FFXIVUnit gPlayer, gTarget, gFocus, gSearch, gSearchTarget;
static bool gIsInCombat = false;

static FFXIVUnit* FFXIVUnitForIdentifier(const char* identifier) {
	if (!strcmp(identifier, "target")) {
		return &gTarget;
	} else if (!strcmp(identifier, "player")) {
		return &gPlayer;
	} else if (!strcmp(identifier, "focus")) {
		return &gFocus;
	} else if (!strcmp(identifier, "search")) {
		return &gSearch;
	} else if (!strcmp(identifier, "searchtarget")) {
		return &gSearchTarget;
	}
	return nullptr;
}

static bool FFXIVUpdateUnit(HANDLE proc, BYTE* address, FFXIVUnit* unit) {
	unit->exists = false;

	if (false
	 || !ReadProcessMemory(proc, address + 0x0030, &unit->name, sizeof(unit->name), nullptr)
	 || !ReadProcessMemory(proc, address + 0x0074, &unit->id, 4, nullptr)
	 || !ReadProcessMemory(proc, address + 0x1838, &unit->currentHP, 4, nullptr)
	 || !ReadProcessMemory(proc, address + 0x183C, &unit->maxHP, 4, nullptr)
	 || !ReadProcessMemory(proc, address + 0x1840, &unit->currentMP, 4, nullptr)
	 || !ReadProcessMemory(proc, address + 0x1844, &unit->maxMP, 4, nullptr)
	 || !ReadProcessMemory(proc, address + 0x1848, &unit->currentTP, 4, nullptr)
	 || !ReadProcessMemory(proc, address + 0x01B0, &unit->target, 4, nullptr)
	) {
		return false;
	}
	
	unit->name[sizeof(unit->name) - 1] = '\0';
	
	unit->exists = true;
	return true;
}

static bool FFXIVUpdateUnitFromPointer(HANDLE proc, BYTE* pointer, FFXIVUnit* unit) {
	unit->exists = false;

	DWORD unitAddr;
	if (!ReadProcessMemory(proc, pointer, &unitAddr, sizeof(unitAddr), nullptr)) {
		return false;
	}

	if (!FFXIVUpdateUnit(proc, (BYTE*)unitAddr, unit)) {
		unit->exists = false;
		return true;
	}
	
	DWORD unitAddrDoubleCheck;
	if (!ReadProcessMemory(proc, pointer, &unitAddrDoubleCheck, sizeof(unitAddrDoubleCheck), nullptr) || unitAddrDoubleCheck != unitAddr) {
		unit->exists = false;
		return true;
	}
	
	unit->exists = true;
	return true;
}

static bool FFXIVUpdateCombatState(HANDLE proc, BYTE* baseAddr) {
	DWORD addr;
	if (!ReadProcessMemory(proc, baseAddr + 0x00f79210, &addr, sizeof(addr), nullptr)) {
		return false;
	}

	DWORD isInCombat;
	if (!ReadProcessMemory(proc, (BYTE*)addr + 0xc4, &isInCombat, sizeof(isInCombat), nullptr)) {
		return false;
	}
	
	if (gIsInCombat && !isInCombat) {
		gIsInCombat = isInCombat;
		PlatformEvent(gLuaState, "LEFT_COMBAT");
	} else if (!gIsInCombat && isInCombat) {
		gIsInCombat = isInCombat;
		PlatformEvent(gLuaState, "ENTERED_COMBAT");
	}
	
	return true;
}

struct FFXIVLogContainer {
	char unknown1[0x10];
	uint32_t indexRollover; // the number of times the container has rolled over
	uint32_t entries = 0; // entries currently in the container (cleared on rollover)
	char unknown2[0x1c];
	uint32_t indexStart; // pointer to a list of buffer offsets
	uint32_t indexNext;
	uint32_t indexEnd;
	char unknown3[0x04];
	uint32_t entriesStart; // pointer to the buffer
	uint32_t entriesNext; // pointer to the next place in the buffer that an entry will be written
	uint32_t entriesEnd;
};

static bool FFXIVReadLog(HANDLE proc, BYTE* baseAddr) {
	static bool discardRead = true;
	static FFXIVLogContainer logContainer;

	auto prevEntries = logContainer.entries;
	
	DWORD address;

	if (false
	  || !ReadProcessMemory(proc, baseAddr + 0x00e38420, &address, 4, nullptr)
	  || !ReadProcessMemory(proc, (BYTE*)address + 0x18, &address, 4, nullptr)
	  || !ReadProcessMemory(proc, (BYTE*)address + 0x1ec, &logContainer, sizeof(logContainer), nullptr)
	) {
		return false;
	}
	
	if (discardRead) {
		discardRead = false;
		return true;
	}

	if (logContainer.entries < prevEntries) {
		prevEntries = 0;
	}

	DWORD indexFirst = logContainer.indexRollover * 1000;
	
	for (auto i = prevEntries; i < logContainer.entries; ++i) {
		DWORD start, end;

		if (i) {
			if (!ReadProcessMemory(proc, (BYTE*)logContainer.indexStart + (i - indexFirst - 1) * 4, &start, 4, nullptr)) {
				return true;
			}
		} else {
			start = 0;
		}

		if (!ReadProcessMemory(proc, (BYTE*)logContainer.indexStart + (i - indexFirst) * 4, &end, 4, nullptr)) {
			return true;
		}
		
		static char entry[2000];

		if (end - start > sizeof(entry)) {
			return true;
		}
		
		if (!ReadProcessMemory(proc, (BYTE*)logContainer.entriesStart + start, entry, end - start, nullptr)) {
			return true;
		}
		
		static char processed[2001];
		char* ptr = processed;

		for (size_t i = 0; i < end - start;) {
			if (entry[i] == 0x02) {
				i += 3 + entry[i + 2];
			} else if ((entry[i] & 0xE0) == 0xE0) {
				i += 3;
			} else {
				*(ptr++) = entry[i];
				++i;
			}
		}
		
		*ptr = '\0';
		PlatformEvent(gLuaState, "LOG_ENTRY", (const char*)processed);
	}
	
	return true;
}

static QTimer* gPollTimer = nullptr; // long-lived

static HANDLE gProcess = nullptr;
static BYTE* gBaseAddr = nullptr;

static void DisconnectProcess() {
	if (gProcess) {
		CloseHandle(gProcess);
		gProcess = nullptr;
	}
	gBaseAddr = nullptr;
}

static bool ConnectProcess() {
	DisconnectProcess();

	DWORD processId = 0;
	
	PROCESSENTRY32 entry;
	entry.dwSize = sizeof(PROCESSENTRY32);

	HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	
	if (Process32First(snapshot, &entry)) {
		do {
			if (!strcmp(entry.szExeFile, "ffxiv.exe")) {
				processId = entry.th32ProcessID;
				break;
			}
		} while (Process32Next(snapshot, &entry));
	}

	CloseHandle(snapshot);
	
	if (!processId) { return false; }
	
	HANDLE proc = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, false, processId);
	
	if (!proc) { return false; }

	static HMODULE modules[200];
	DWORD needed;
	if (!EnumProcessModules(proc, modules, sizeof(modules), &needed) || needed > sizeof(modules)) {
		CloseHandle(proc);
		return false;
	}
	
	BYTE* baseAddr = nullptr;
	
	for (unsigned int i = 0; i < needed / sizeof(*modules); ++i) {
		static char fileName[300];
		if (!GetModuleFileNameEx(proc, modules[i], fileName, sizeof(fileName))) {
			CloseHandle(proc);
			return false;
		}
		if (strstr(fileName, "ffxiv.exe")) {
			baseAddr = (BYTE*)modules[i];
			break;
		}
	}
	
	if (!baseAddr) {
		CloseHandle(proc);
		return false;
	}
	
	printf("connected to process (base = %p)\n", baseAddr);

	gProcess = proc;
	gBaseAddr = baseAddr;
	return true;
}

static void PollTimerFire(lua_State* L) {
	if (!gProcess || !gBaseAddr) {
		if (!ConnectProcess()) { return; }
	}

	if (false
		|| !FFXIVUpdateUnitFromPointer(gProcess, gBaseAddr + 0x00e3c048, &gTarget) 
		|| !FFXIVUpdateUnitFromPointer(gProcess, gBaseAddr + 0x00e3d080, &gPlayer) 
		|| !FFXIVUpdateUnitFromPointer(gProcess, gBaseAddr + 0x00e3c080, &gFocus)
		|| !FFXIVUpdateCombatState(gProcess, gBaseAddr)
		|| !FFXIVReadLog(gProcess, gBaseAddr)
	) {
		DisconnectProcess();
	}
}

#define RESOLVE_UNIT_ARG(var) \
	int n = lua_gettop(L); \
	if (n != 1) { return luaL_error(L, "invalid arguments"); } \
	FFXIVUnit* var = FFXIVUnitForIdentifier(luaL_checkstring(L, 1)); \
	if (!var) { return luaL_error(L, "invalid arguments"); } \
	do {} while(false)
	
static int FFXIVUnitName(lua_State* L) {
	RESOLVE_UNIT_ARG(unit);

	if (unit->exists) {
		lua_pushstring(L, unit->name);
	} else {
		lua_pushstring(L, "");
	}

	return 1;
}

static int FFXIVUnitVitals(lua_State* L) {
	RESOLVE_UNIT_ARG(unit);
	
	if (unit->exists) {
		lua_pushnumber(L, unit->currentHP);
		lua_pushnumber(L, unit->maxHP);
		lua_pushnumber(L, unit->currentMP);
		lua_pushnumber(L, unit->maxMP);
		lua_pushnumber(L, unit->currentTP);
	} else {
		lua_pushnumber(L, 0);
		lua_pushnumber(L, 0);
		lua_pushnumber(L, 0);
		lua_pushnumber(L, 0);
		lua_pushnumber(L, 0);
	}
	
	return 5;
}

static int FFXIVPlayerIsInCombat(lua_State* L) {
	int n = lua_gettop(L);
	
	if (n) {
		return luaL_error(L, "invalid arguments");
	}

	lua_pushnumber(L, gIsInCombat ? 1 : 0);

	return 1;
}

static int FFXIVSearchEntities(lua_State* L) {
	int n = lua_gettop(L);

	gSearch.exists = gSearchTarget.exists = false;
	
	if (n != 1) {
		return luaL_error(L, "invalid arguments");
	}
	
	auto search = luaL_checkstring(L, 1);

	if (!gProcess || !gBaseAddr) {
		lua_pushnumber(L, 0);
		return 1;
	}
	
	DWORD entityCount = 0;
	DWORD entities[256]; // first element is actually the entity count

	if (false
		|| !ReadProcessMemory(gProcess, gBaseAddr + 0xe3d07c, &entityCount, sizeof(entityCount), nullptr)
		|| !ReadProcessMemory(gProcess, gBaseAddr + 0xe3d07c, &entities, std::min<size_t>(sizeof(entities), 4 + entityCount * 4), nullptr)
		|| entityCount != entities[0]
	) {
		lua_pushnumber(L, 0);
		return 1;
	}

	for (DWORD i = 1; i <= entityCount && i <= sizeof(entities) / sizeof(*entities); ++i) {
		FFXIVUnit unit;
		if (!FFXIVUpdateUnit(gProcess, (BYTE*)entities[i], &unit)) {
			lua_pushnumber(L, 0);
			return 1;
		}
		if (unit.exists && !strcmp(unit.name, search)) {
			gSearch = unit;
			
			if (gSearch.target) {
				for (DWORD i = 1; i <= entityCount && i <= sizeof(entities) / sizeof(*entities); ++i) {
					FFXIVUnit unit;
					if (!FFXIVUpdateUnit(gProcess, (BYTE*)entities[i], &unit)) {
						lua_pushnumber(L, 0);
						return 1;
					}
					if (unit.exists && unit.id == gSearch.target) {
						gSearchTarget = unit;
						break;
					}
				}
			}
	
			lua_pushnumber(L, 1);
			return 1;
		}
	}

	lua_pushnumber(L, 0);
	return 1;
}

void FFXIVInit(lua_State* L) {
	gLuaState = L;
	
	gPollTimer = new QTimer();
	QObject::connect(gPollTimer, &QTimer::timeout, std::bind(&PollTimerFire, L));
	gPollTimer->start(50);

	lua_pushcfunction(L, &FFXIVUnitName);
	lua_setglobal(L, "UnitName");

	lua_pushcfunction(L, &FFXIVUnitVitals);
	lua_setglobal(L, "UnitVitals");

	lua_pushcfunction(L, &FFXIVPlayerIsInCombat);
	lua_setglobal(L, "PlayerIsInCombat");

	lua_pushcfunction(L, &FFXIVSearchEntities);
	lua_setglobal(L, "SearchEntities");
}
