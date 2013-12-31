#include "Lua.h"
#include "Luna.h"

lua_State* LuaOpen() {
	auto state = luaL_newstate();

	static const luaL_Reg lualibs[] = {
		{ "base",     luaopen_base },
		{ "math",     luaopen_math },
		{ "os",         luaopen_os },
		{ "string", luaopen_string },
		{ "table",   luaopen_table },
		{ nullptr, nullptr },
	};

	for (auto lib = &lualibs[0]; lib->func; ++lib) {
		luaL_requiref(state, lib->name, lib->func, 1);
		lua_settop(state, 0);
	}
	
	return state;
}

int LuaRawCall(lua_State* L, int nargs, int nresults) {
	int r = lua_pcall(L, nargs, nresults, 0);
	if (r) {
		printf("%s\n", lua_tostring(L, -1));
		lua_pop(L, 1);
	}
	return r;
}

int LuaRunFile(lua_State* L, const char* file) {
	int r = luaL_loadfile(L, file);

	if (!r) {
		LuaRawCall(L, 0, 0);
	} else {
		printf("%s\n", lua_tostring(L, -1));
		lua_pop(L, 1);
	}

	return r;
}

void LuaClose(lua_State* L) {
	lua_close(L);
}
