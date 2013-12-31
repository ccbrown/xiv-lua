#include "TextView.h"

#include <cmath>

TextView::TextView(lua_State* L) {
	_init<QLabel>(L, &_impl);
}

TextView::~TextView() {
	if (_impl) {
		delete _impl;
	}
}

int TextView::setText(lua_State* L) {
	int n = lua_gettop(L) - 1;
	if (n == 1) {
		textImpl()->setText(luaL_checkstring(L, 2));
	} else {
		return luaL_error(L, "invalid arguments");
	}

	return 0;
}

int TextView::setColor(lua_State* L) {
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
	
	QPalette p = textImpl()->palette();
	p.setColor(textImpl()->foregroundRole(), QColor(red * 255, green * 255, blue * 255, alpha * 255));
	textImpl()->setPalette(p);
	
	return 0;
}

int TextView::setHorizontalAlignment(lua_State* L) {
	int n = lua_gettop(L) - 1;

	if (n == 1) {
		const char* alignment = luaL_checkstring(L, 2);
		
		if (!strcmp(alignment, "left")) {
			textImpl()->setAlignment((textImpl()->alignment() & ~Qt::AlignHorizontal_Mask) | Qt::AlignLeft);
		} else if (!strcmp(alignment, "right")) {
			textImpl()->setAlignment((textImpl()->alignment() & ~Qt::AlignHorizontal_Mask) | Qt::AlignRight);
		} else if (!strcmp(alignment, "center")) {
			textImpl()->setAlignment((textImpl()->alignment() & ~Qt::AlignHorizontal_Mask) | Qt::AlignCenter);
		} else if (!strcmp(alignment, "justify")) {
			textImpl()->setAlignment((textImpl()->alignment() & ~Qt::AlignHorizontal_Mask) | Qt::AlignJustify);
		} else {
			return luaL_error(L, "invalid arguments");
		}
	} else {
		return luaL_error(L, "invalid arguments");
	}
	
	return 0;
}

const char TextView::ClassName[] = "TextView";
const Luna<TextView>::RegType TextView::Register[] = {
	{ "show", &TextView::show },
	{ "hide", &TextView::hide },
	{ "setText", &TextView::setText },
	{ "setBackgroundColor", &TextView::setBackgroundColor },
	{ "setColor", &TextView::setColor },
	{ "setAnchor1", &TextView::setAnchor1 },
	{ "setAnchor2", &TextView::setAnchor2 },
	{ "setHorizontalAlignment", &TextView::setHorizontalAlignment },
	{ 0 }
};
