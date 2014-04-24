#include "View.h"

#include <cmath>
#include <cstring>

#ifdef _WIN32
#include <windows.h>
#endif

View::View(lua_State* L) {
	_init<QWidget>(L, &_impl);
}

View::~View() {
	if (_super) {
		_super->removeSubview(this);
	}
	if (_impl) {
		delete _impl;
	}
}

void View::setRef(lua_State* L, int ref) {
	luaL_unref(L, LUA_REGISTRYINDEX, _luaRef);
	_luaRef = ref;
}

int View::show(lua_State* L) {
	impl()->show();
#ifdef _WIN32
	if (!_super) {
		HWND hwnd = (HWND)impl()->winId();
		SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
	}
#endif
	return 0;
}

int View::hide(lua_State* L) {
	impl()->hide();
	return 0;
}

int View::setAnchor1(lua_State* L) {
	return setAnchor(L, &_anchor1);
}

int View::setAnchor2(lua_State* L) {
	return setAnchor(L, &_anchor2);
}

int View::setMovable(lua_State* L) {
	int n = lua_gettop(L) - 1;

	if (n == 1) {
		// TODO
	} else {
		return luaL_error(L, "invalid arguments");
	}
	
	return 0;
}

int View::setClickable(lua_State* L) {
	int n = lua_gettop(L) - 1;

	if (n == 1) {
#ifdef _WIN32
		bool clickable = lua_toboolean(L, 2);
		if (!_super) {
			HWND hwnd = (HWND)impl()->winId();
			LONG styles = GetWindowLong(hwnd, GWL_EXSTYLE);
			SetWindowLong(hwnd, GWL_EXSTYLE, clickable ? styles & ~WS_EX_TRANSPARENT : styles | WS_EX_TRANSPARENT);
		}
#endif
	} else {
		return luaL_error(L, "invalid arguments");
	}
	
	return 0;
}

int View::setBackgroundColor(lua_State* L) {
	int n = lua_gettop(L) - 1;

	double arg[4];

	for (int i = 0; i < n && i < 4; ++i) {
		arg[i] = luaL_checknumber(L, i + 2);
	}

	double red, green, blue, alpha;

	if (n == 1) {
		red = green = blue = arg[0];
		alpha = 1.0;
	} else if (n == 2) {
		red = green = blue = arg[0];
		alpha = arg[1];
	} else if (n == 3) {
		red   = arg[0];
		green = arg[1];
		blue  = arg[2];
		alpha = 1.0;
	} else if (n == 4) {
		red   = arg[0];
		green = arg[1];
		blue  = arg[2];
		alpha = arg[3];
	} else {
		return luaL_error(L, "invalid arguments");
	}
	
	QPalette p = impl()->palette();
	p.setColor(impl()->backgroundRole(), QColor(red * 255, green * 255, blue * 255, alpha * 255));
	impl()->setPalette(p);

	impl()->setAutoFillBackground(true);
	
	return 0;
}

int View::setOpacity(lua_State* L) {
	int n = lua_gettop(L) - 1;

	if (n == 1) {
		impl()->setWindowOpacity(luaL_checknumber(L, 2));
	} else {
		return luaL_error(L, "invalid arguments");
	}

	return 0;
}

int View::setScript(lua_State* L) {
	int n = lua_gettop(L) - 1;

	if (n == 2) {
		const char* name = luaL_checkstring(L, 2);
		Script* script = nullptr;
		if (!strcmp(name, "onMouseDown")) {
			script = &_scripts[ScriptOnMouseDown];
		} else if (!strcmp(name, "onMouseUp")) {
			script = &_scripts[ScriptOnMouseUp];
		}
		if (!script) {
			return luaL_error(L, "invalid script");
		}
		if (script->L) {
			luaL_unref(script->L, LUA_REGISTRYINDEX, script->function);
		}
		script->function = LUA_NOREF;
		script->L = L;
		if (!lua_isnil(L, 3)) {
			luaL_checktype(L, 3, LUA_TFUNCTION);
			script->function = luaL_ref(L, LUA_REGISTRYINDEX);
		}
	} else {
		return luaL_error(L, "invalid arguments");
	}
	
	return 0;
}

int View::setAnchor(lua_State* L, Anchor* anchor) {
	int n = lua_gettop(L) - 1;

	if (n == 4) {
		anchor->x       = luaL_checknumber(L, 2);
		anchor->y       = luaL_checknumber(L, 3);
		anchor->superX  = luaL_checknumber(L, 4);
		anchor->superY  = luaL_checknumber(L, 5);
		anchor->xOffset = anchor->yOffset = 0.0;
	} else if (n == 6) {
		anchor->x       = luaL_checknumber(L, 2);
		anchor->y       = luaL_checknumber(L, 3);
		anchor->superX  = luaL_checknumber(L, 4);
		anchor->superY  = luaL_checknumber(L, 5);
		anchor->xOffset = luaL_checknumber(L, 6);
		anchor->yOffset = luaL_checknumber(L, 7);
	} else {
		return luaL_error(L, "invalid arguments");
	}
	
	layout();

	return 0;
}

void View::layout() {
	double parentWidth  = (_super ? impl()->parentWidget()->geometry() : QApplication::desktop()->screenGeometry(_screen)).width();
	double parentHeight = (_super ? impl()->parentWidget()->geometry() : QApplication::desktop()->screenGeometry(_screen)).height();

	double a1RealX = parentWidth  * _anchor1.superX + _anchor1.xOffset;
	double a1RealY = parentHeight * _anchor1.superY + _anchor1.yOffset;
	double a2RealX = parentWidth  * _anchor2.superX + _anchor2.xOffset;
	double a2RealY = parentHeight * _anchor2.superY + _anchor2.yOffset;

	double width   = _anchor1.x != _anchor2.x ? fabs((a1RealX - a2RealX) / (_anchor1.x - _anchor2.x)) : 0.0; 
	double height  = _anchor1.y != _anchor2.y ? fabs((a1RealY - a2RealY) / (_anchor1.y - _anchor2.y)) : 0.0; 

	if (!_super && QApplication::desktop()->isVirtualDesktop()) {
		impl()->setGeometry(QApplication::desktop()->screenGeometry(_screen).left() + a1RealX - _anchor1.x * width, QApplication::desktop()->screenGeometry(_screen).top() + a1RealY - _anchor1.y * height, width, height);
	} else {
		impl()->setGeometry(a1RealX - _anchor1.x * width, a1RealY - _anchor1.y * height, width, height);
	}
	
	for (auto subview : _subviews) {
		subview->layout();
	}
}

void View::addSubview(View* view) {
	_subviews.push_back(view);
	view->layout();
}

void View::removeSubview(View* view) {
	_subviews.remove(view);
}

void View::mouseDown(int button, double x, double y, bool shift, bool control, bool alt, bool command) {
	if (_scripts[ScriptOnMouseDown].L) {
		LuaCall(_scripts[ScriptOnMouseDown].L, _scripts[ScriptOnMouseDown].function, _luaRef, button, x, y, shift, control, alt, command);
	}
}

void View::mouseUp(int button, double x, double y, bool shift, bool control, bool alt, bool command) {
	if (_scripts[ScriptOnMouseUp].L) {
		LuaCall(_scripts[ScriptOnMouseUp].L, _scripts[ScriptOnMouseUp].function, _luaRef, button, x, y, shift, control, alt, command);
	}
}

const char View::ClassName[] = "View";
const Luna<View>::RegType View::Register[] = {
	{ "show", &View::show },
	{ "hide", &View::hide },
	{ "setAnchor1", &View::setAnchor1 },
	{ "setAnchor2", &View::setAnchor2 },
	{ "setMovable", &View::setMovable },
	{ "setClickable", &View::setClickable },
	{ "setBackgroundColor", &View::setBackgroundColor },
	{ "setOpacity", &View::setOpacity },
	{ "setScript", &View::setScript },
	{ 0 }
};