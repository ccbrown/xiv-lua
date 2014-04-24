#pragma once

#include "View.h"

class TextView : public View {
	public:
		TextView(lua_State* L);
		virtual ~TextView();

		int setText(lua_State* L);
		int setFont(lua_State* L);
		int setColor(lua_State* L);
		int setHorizontalAlignment(lua_State* L);
		
		int setAnchor(lua_State* L, Anchor* anchor);

		virtual QWidget* impl() { return textImpl(); }
		virtual QLabel* textImpl() { return _impl; }

		static const char ClassName[];
		static const Luna<TextView>::RegType Register[];
		
	private:
		QLabel* _impl;
};
