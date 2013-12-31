#pragma once

#include "Lua.h"
#include "Luna.h"

#include <list>

#include <QtWidgets/QtWidgets>

struct Anchor {
	double x, y, superX, superY, xOffset, yOffset;
};

struct Script {
	lua_State* L;
	int function;
};

enum {
	ScriptOnMouseDown,
	ScriptOnMouseUp,
	ScriptCount
};

class View {
	public:
		View(lua_State* L);
		virtual ~View();

		void setRef(lua_State* L, int ref);

		int show(lua_State* L);
		int hide(lua_State* L);
		int setAnchor1(lua_State* L);
		int setAnchor2(lua_State* L);
		int setMovable(lua_State* L);
		int setClickable(lua_State* L);
		int setBackgroundColor(lua_State* L);
		int setScript(lua_State* L);

		int setAnchor(lua_State* L, Anchor* anchor);
		
		void layout();
		void addSubview(View* view);
		void removeSubview(View* view);
		
		void mouseDown(int button, double x, double y, bool shift, bool control, bool alt, bool command);
		void mouseUp(int button, double x, double y, bool shift, bool control, bool alt, bool command);

		virtual QWidget* impl() { return _impl; }

		static const char ClassName[];
		static const Luna<View>::RegType Register[];
		
	private:
		QWidget* _impl = nullptr;
	
	protected:
		View() {}
	
		template <typename T>
		void _init(lua_State* L, T** implPtr) {
			int n = lua_gettop(L);
		
			if (n == 0) {
				/* nop */
			} else if (n == 1) {
				if (lua_isnoneornil(L, -1)) {
					/* nop */
				} else if (lua_isnumber(L, -1)) {
					_screen = lua_tonumber(L, -1);
					if (_screen >= QApplication::desktop()->screenCount()) {
						_screen = -1;
					}
				} else {
					luaL_checktype(L, -1, LUA_TTABLE);
					lua_pushnumber(L, 0);
					lua_gettable(L, -2);
					_super = *static_cast<View**>(luaL_checkudata(L, -1, View::ClassName));
					lua_pop(L, 1);
					if (_super == this) {
						_super = nullptr;
					}
				}
			} else {
				luaL_error(L, "invalid arguments");
			}
		
			*implPtr = new T(_super ? _super->impl() : QApplication::desktop()->screen(_screen));
			
			if (_super) {
				_super->addSubview(this);
			} else {
				(*implPtr)->setAttribute(Qt::WA_TranslucentBackground);
				(*implPtr)->setWindowFlags(Qt::WindowStaysOnTopHint | Qt::FramelessWindowHint | Qt::Tool);
			}
		}
		
		int _screen = -1;

		LuaRef _luaRef = LUA_REFNIL;
		
		Anchor _anchor1{};
		Anchor _anchor2{};

		Script _scripts[ScriptCount]{};
			
		View* _super = nullptr;
		std::list<View*> _subviews;
};
