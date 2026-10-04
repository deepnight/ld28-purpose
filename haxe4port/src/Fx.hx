import dn.heaps.HParticle;

class Fx {
	public static var ME : Fx;
	var game : Game;
	var pool : dn.heaps.HParticle.ParticlePool;
	var pixel : h2d.Tile;
	var rings : Map<Int,h2d.Tile> = [];
	var add : h2d.SpriteBatch;
	var normal : h2d.SpriteBatch;
	var background : h2d.SpriteBatch;
	var flashes : Array<h2d.Bitmap> = [];
	var glows : Map<String,h2d.SpriteBatch> = [];

	public function new() {
		ME = this;
		game = Game.ME;
		pixel = h2d.Tile.fromColor(0xFFFFFF,1,1);
		pool = new dn.heaps.HParticle.ParticlePool(pixel,512,Const.FPS);
		add = new h2d.SpriteBatch(pixel);
		add.blendMode = Add;
		game.root.add(add,Const.DP_FX);
		normal = new h2d.SpriteBatch(pixel);
		game.root.add(normal,Const.DP_FX);
		background = new h2d.SpriteBatch(pixel);
		background.filter = new render.SoftGlow(0,0.7,4);
		game.root.add(background,Const.DP_BG);
	}

	function glowBatch(col:Int, alpha:Float, radius:Float, strength=1.0) {
		var id = col+":"+alpha+":"+radius+":"+strength;
		if( !glows.exists(id) ) {
			var sb = new h2d.SpriteBatch(pixel);
			sb.blendMode = Add;
			sb.filter = new render.SoftGlow(col,alpha,radius,strength);
			game.root.add(sb,Const.DP_FX);
			glows[id] = sb;
		}
		return glows[id];
	}

	function box(x:Float,y:Float,w:Float,h:Float,col:Int,a=1.0,?batch:h2d.SpriteBatch) : HParticle {
		var p = pool.alloc(batch==null ? add : batch,pixel,x,y);
		p.setCenterRatio(0.5,0.5);
		p.scaleX = w;
		p.scaleY = h;
		p.colorize(col);
		p.alpha = a;
		p.frictX = Lib.rnd(0.95,0.99);
		p.frictY = 0.97;
		return p;
	}

	function ring(x:Float,y:Float,radius:Int,col:Int) {
		if( !rings.exists(radius) ) {
			var size = radius*2+2;
			var pixels = hxd.Pixels.alloc(size,size,RGBA);
			for(px in 0...size)
				for(py in 0...size) {
					var d = M.dist(px+0.5,py+0.5,size*0.5,size*0.5);
					pixels.setPixel(px,py,Math.abs(d-radius)<0.6 ? 0xFFFFFFFF : 0);
				}
			rings[radius] = h2d.Tile.fromPixels(pixels);
		}
		var p = pool.alloc(add,rings[radius],x,y);
		p.colorize(col);
		p.lifeF = 1;
		return p;
	}

	public function hit(x:Float,y:Float) {
		var p = ring(x,y,5,0xFF9300);
		p.ds = 0.1;
	}

	public function flashBang(col:Int,a=0.6,d=400) {
		var s = new h2d.Bitmap(h2d.Tile.fromColor(col,Const.WID,Const.HEI));
		flashes.push(s);
		s.alpha = a;
		s.blendMode = Add;
		game.root.add(s,Const.DP_FX);
		game.tw.createMs(s.alpha,0,TEaseIn,d).onEnd = function() {
			flashes.remove(s);
			s.tile.dispose();
			s.remove();
		}
	}

	public function leaves(x:Float,y:Float) {
		for(i in 0...15) {
			var p = box(x+Lib.rnd(0,5,true),y+Lib.rnd(0,5,true),Lib.irnd(1,2),1,0x68a218,Lib.rnd(0.1,0.8),normal);
			p.dr = M.toRad(Lib.rnd(0,5,true));
			p.moveAng(Lib.rnd(0,6.28),Lib.rnd(1,2));
			p.gx = Lib.rnd(0.02,0.06);
			p.gy = 0.03+Lib.rnd(0,0.03,true);
			p.lifeF = Lib.rnd(130,200);
			p.delayF = Lib.rnd(0,30);
			p.frict = 0.86;
		}
	}

	public function heroExplode(e:en.Hero) {
		var p = ring(e.xx,e.yy,6,e.color);
		p.ds = 0.2;
		p.lifeF = 1;
		for(i in 0...50) {
			var size = i<20 ? 2 : 1;
			var p = box(e.xx+Lib.rnd(0,i<20 ? 7 : 5,true),e.yy+Lib.rnd(0,i<20 ? 2 : 5,true),size,size,e.color,i<20 ? Lib.rnd(0.3,0.7) : 1,glowBatch(e.color,i<20 ? 0.7 : 0.3,i<20 ? 4 : 1,2));
			p.moveAng(Lib.rnd(0,6.28),i<20 ? Lib.rnd(0.4,0.7) : Lib.rnd(1,2));
			p.frict = Lib.rnd(0.9,i<20 ? 0.95 : 0.98);
			p.lifeF = i<20 ? Lib.rnd(5,15) : Lib.rnd(10,30);
		}
	}

	public function lava(x:Float,y:Float) {
		var w = Lib.irnd(1,2);
		var p = box(x+Lib.rnd(0,5,true),y+Lib.rnd(0,2),w,w,0xffc600,Lib.rnd(0.3,0.8),glowBatch(0xFF5300,0.9,4));
		p.dy = -Lib.rnd(0.05,0.2);
		p.frictY = Lib.rnd(0.85,0.99);
		p.lifeF = Lib.rnd(5,20);
	}

	public function water(x:Float,y:Float) {
		var p = box(x+Lib.rnd(0,3,true),y+Lib.rnd(0,2),1,1,0xAFB5EF,Lib.rnd(0.3,0.8),glowBatch(0x6c76e1,0.9,2,2));
		p.dy = -Lib.rnd(0.3,1);
		p.dx = Lib.rnd(0,0.5,true);
		p.gy = 0.05;
		p.groundY = p.y;
		p.frictX = 0.7;
		p.frictY = Lib.rnd(0.85,0.99);
		p.lifeF = Lib.rnd(5,10);
	}

	public function darkness() {
		var p = box(Lib.rnd(0,Const.WID),Lib.rnd(0,Const.HEI),2,3,0,0,background);
		p.dx = Lib.rnd(0.1,0.3,true);
		p.dy = -Lib.rnd(0.05,0.2);
		p.dr = M.toRad(Lib.rnd(2,7,true));
		p.da = Lib.rnd(0.01,0.03);
		p.lifeF = Lib.rnd(30,90);
	}

	public function clear() {
		pool.clear();
		for(b in flashes) {
			b.tile.dispose();
			b.remove();
		}
		flashes = [];
	}
	public function update() pool.update(1);
	public function destroy() {
		pool.dispose();
		add.remove();
		normal.remove();
		background.remove();
		for(sb in glows) sb.remove();
		for(t in rings) t.dispose();
		pixel.dispose();
	}
}
