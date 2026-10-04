package en;


class Water extends Entity {
	public function new(x,y) {
		super();
		setPos(x,y);
		Game.ME.root.add(spr, Const.DP_LAVA);
		spr.set("water");
		spr.setCenterRatio(0.5, 0.5);
		spr.blendMode = Add;
		spr.filter = new render.SoftShadow(0x8C96E8,0.4,0,8);
	}

	override function update() {
		super.update();

		for(e in Hero.ALL)
			if( e.isActive && distance2(e) < dn.M.pow(radius, 2) )
				Fx.ME.water(e.xx, e.yy);
	}
}
