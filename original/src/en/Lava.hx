package en;

import mt.deepnight.Lib;
import mt.deepnight.deprecated.SpriteLibBitmap;

class Lava extends Entity {
	public function new(x,y) {
		super();
		setPos(x,y);
		Game.ME.buffer.dm.add(spr, Const.DP_LAVA);
		spr.setGroup("lava");
		spr.setCenter(0.5, 0.5);
		spr.filters = [
			new flash.filters.DropShadowFilter(0, -90, 0xFF7900, 1, 0,8, 1),
			new flash.filters.DropShadowFilter(0, -90, 0xFF4D00, 0.4, 8,32, 1),
		];
		//spr.graphics.beginFill(0xFF4D00,1);
		//spr.graphics.drawRect(-radius, -radius, radius*2, radius*2);
	}

	override function update() {
		super.update();

		if( (Game.ME.time+uid)%3==0 )
			Fx.ME.lava(xx,yy-5);

		for(e in Hero.ALL)
			if( distance2(e) < dn.M.pow(radius, 2) )
				e.die();
	}
}