package en;

import mt.deepnight.Lib;
import mt.deepnight.deprecated.SpriteLibBitmap;

class Water extends Entity {
	public function new(x,y) {
		super();
		setPos(x,y);
		Game.ME.buffer.dm.add(spr, Const.DP_LAVA);
		spr.setGroup("water");
		spr.setCenter(0.5, 0.5);
		spr.blendMode = ADD;
		spr.filters = [
			new flash.filters.DropShadowFilter(0, -90, 0x8C96E8, 0.4, 0,8, 1),
		];
	}

	override function update() {
		super.update();

		for(e in Hero.ALL)
			if( e.isActive && distance2(e) < dn.M.pow(radius, 2) )
				Fx.ME.water(e.xx, e.yy);
	}
}