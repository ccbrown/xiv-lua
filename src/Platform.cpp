#include "Platform.h"

#include "Luna.h"
#include "View.h"
#include "TextView.h"

#include <chrono>

#include <QtMultimedia/QSound>
#include <QtCore/QTimer>

static QTimer* gAnimationTimer = nullptr; // long-lived

std::vector<int> gEventCallbacks;

static void AnimationTimerFire(lua_State* L) {
	PlatformEvent(L, "ANIMATION_FRAME");
}

static int SteadyTime(lua_State* L) {
	double time = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
	lua_pushnumber(L, time);
	return 1;
}

static int PlaySound(lua_State* L) {
	int n = lua_gettop(L);

	if (n == 1) {
		QSound::play(luaL_checkstring(L, 1));
	} else {
		return luaL_error(L, "invalid arguments");
	}

	return 0;
}

static int RegisterEventCallback(lua_State* L) {
	int n = lua_gettop(L);
	
	if (n != 1 || lua_isnil(L, 1)) {
		return luaL_error(L, "invalid arguments");
	}
	
	luaL_checktype(L, 1, LUA_TFUNCTION);
	gEventCallbacks.push_back(luaL_ref(L, LUA_REGISTRYINDEX));
	if (!gAnimationTimer) {
		gAnimationTimer = new QTimer();
		QObject::connect(gAnimationTimer, &QTimer::timeout, std::bind(&AnimationTimerFire, L));
		gAnimationTimer->start(50);
	}
	
	return 0;
}

void PlatformInit(lua_State* L) {
	Luna<View>::Register(L);
	Luna<TextView>::Register(L);

	lua_pushcfunction(L, &SteadyTime);
	lua_setglobal(L, "SteadyTime");

	lua_pushcfunction(L, &PlaySound);
	lua_setglobal(L, "PlaySound");

	lua_pushcfunction(L, &RegisterEventCallback);
	lua_setglobal(L, "RegisterEventCallback");
}
