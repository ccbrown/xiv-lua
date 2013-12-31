#pragma once

#include "Lua.h"

#include <vector>

void PlatformInit(lua_State* L);

template <typename... Args>
void PlatformEvent(lua_State* L, const char* event, Args&&... args) {
	extern std::vector<int> gEventCallbacks;
	for (auto callback : gEventCallbacks) {
		LuaCall(L, callback, event, args...);
	}
}