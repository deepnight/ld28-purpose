package en;


class Lava extends Entity {
	public function new(x,y) {
		super();
		setPos(x,y);
		Game.ME.root.add(spr, Const.DP_LAVA);
		spr.set("lava");
		spr.setCenterRatio(0.5, 0.5);
		spr.filter = new h2d.filter.Group([
			new render.SoftShadow(0xFF7900,1,0,8),
			new render.SoftShadow(0xFF4D00,0.4,8,32),
		]);
	}

	override function update() {
		super.update();

		if( (Game.ME.tick+uid)%3==0 )
			Fx.ME.lava(xx,yy-5);

		for(e in Hero.ALL)
			if( distance2(e) < dn.M.pow(radius, 2) )
				e.die();
	}
}
