#pragma once

#include <lua.hpp>

#include <functional>

lua_State* LuaOpen();
void LuaClose(lua_State* L);

struct LuaRef {
	LuaRef(int n) : n(n) {}
	operator int() const { return n; }
	int n;
};

inline void LuaPush(lua_State* L, int value) { lua_pushinteger(L, value); }
inline void LuaPush(lua_State* L, double value) { lua_pushnumber(L, value); }
inline void LuaPush(lua_State* L, const char* value) { lua_pushstring(L, value); }
inline void LuaPush(lua_State* L, bool value) { lua_pushboolean(L, value); }
inline void LuaPush(lua_State* L, LuaRef value) { lua_rawgeti(L, LUA_REGISTRYINDEX, value.n); }

template <typename Next, typename... Remaining>
void LuaPush(lua_State* L, Next&& next, Remaining&&... remaining) {
	LuaPush(L, std::forward<Next>(next));
	LuaPush(L, std::forward<Remaining>(remaining)...);
}

template <typename... Args>
int LuaCall(lua_State* L, int function, Args&&... args) {
	lua_rawgeti(L, LUA_REGISTRYINDEX, function);
	LuaPush(L, std::forward<Args>(args)...);
	int r = lua_pcall(L, sizeof...(Args), 0, 0);
	if (r) {
		printf("%s\n", lua_tostring(L, -1));
		lua_pop(L, 1);
	}
	return r;
}

int LuaRunFile(lua_State* L, const char* file);
