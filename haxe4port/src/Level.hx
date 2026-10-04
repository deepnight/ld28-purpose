class Level {
	var map : Array<Array<Bool>>;
	public var wid = 20;
	public var hei = 20;
	var source : hxd.Pixels;
	var spots : Map<String, Array<{cx:Int, cy:Int}>>;
	public var wrapper : h2d.Bitmap;
	public var front : h2d.TileGroup;
	public var bg : h2d.TileGroup;

	public function new() {
		source = hxd.Res.levels.getPixels();
		var gradient = hxd.Pixels.alloc(Const.WID, Const.HEI, RGBA);
		for(x in 0...Const.WID) {
			var col:dn.Col = 0x100f19;
			col = col.to(0x1E303E, x/(Const.WID-1));
			for(y in 0...Const.HEI) gradient.setPixel(x,y,col.withAlpha(1));
		}
		wrapper = new h2d.Bitmap(h2d.Tile.fromPixels(gradient));
		Game.ME.root.add(wrapper, Const.DP_BG);
		bg = new h2d.TileGroup(Game.ME.tiles.pages[0]);
		bg.filter = new h2d.filter.Group([
			new render.SoftGlow(0,0.5,4),
			new render.SoftGlow(0,0.7,16),
		]);
		Game.ME.root.add(bg, Const.DP_BG);
		front = new h2d.TileGroup(Game.ME.tiles.pages[0]);
		Game.ME.root.add(front, Const.DP_FRONT);
	}

	public function setLevel(n:Int) {
		spots = new Map();
		map = [];
		for(cx in 0...wid) {
			map[cx] = [];
			for(cy in 0...hei) {
				var p = source.getPixel(cx,cy+n*hei)&0xFFFFFF;
				map[cx][cy] = p==0xFFFFFF;
				switch(p) {
					case 0x007eff: addSpot("hero",cx,cy);
					case 0x00ff00: addSpot("plant",cx,cy);
					case 0xFF0000: addSpot("lava",cx,cy);
					case 0x00FFFF: addSpot("water",cx,cy);
					case 0x9a4800: addSpot("crate",cx,cy);
					default:
				}
			}
		}
		render();
	}

	function addSpot(k:String, cx:Int, cy:Int) {
		if( !spots.exists(k) ) spots[k] = [];
		spots[k].push({cx:cx, cy:cy});
	}

	public function getSpots(k:String) return spots.exists(k) ? spots[k] : [];
	public function getSpot(k:String) return getSpots(k)[0];

	public function render() {
		front.clear();
		bg.clear();
		for(cx in 0...wid)
			for(cy in 0...hei)
				if( hasCollision(cx,cy) ) {
					var tile = Game.ME.tiles.getRandomTile("ground");
					front.add(cx*Const.GRID-5,cy*Const.GRID-5,tile);
					bg.add(cx*Const.GRID-5,cy*Const.GRID-5,tile);
				}
	}

	public function destroy() {
		wrapper.tile.dispose();
		wrapper.remove();
		front.remove();
		bg.remove();
		source.dispose();
	}

	public function hasCollision(cx:Int,cy:Int) {
		return cx<0 || cy<0 || cx>=wid || cy>=hei || map[cx][cy];
	}
}
