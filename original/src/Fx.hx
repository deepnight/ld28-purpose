import flash.display.BlendMode;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

import mt.deepnight.Particle;
import mt.deepnight.Lib;
import mt.deepnight.Color;

import Const;

class Fx {
	public static var ME : Fx;

	var game			: Game;
	var pt0				: flash.geom.Point;

	public function new() {
		ME = this;
		game = Game.ME;
		pt0 = new flash.geom.Point(0,0);
	}

	public function register(p:Particle, ?b:BlendMode, ?layer:Int) {
		game.buffer.dm.add(p, layer==null ? Const.DP_FX : layer);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}

	inline function rnd(min,max,?sign) { return Lib.rnd(min,max,sign); }
	inline function irnd(min,max,?sign) { return Lib.irnd(min,max,sign); }

	public function hit(x,y) {
		var p = new Particle(x,y);
		p.drawCircle(5, 0xFF9300, 1, false);
		p.ds = 0.1;
		p.life = 1;
		register(p);
	}

	public function flashBang(col:Int, ?a=0.6, ?d=400) {
		var s = new Sprite();
		game.buffer.dm.add(s, Const.DP_FX);
		s.graphics.beginFill(col, a);
		s.graphics.drawRect(0,0, game.buffer.width, game.buffer.height);
		s.blendMode = ADD;
		game.tw.create(s, "alpha", 0, TEaseIn, d).onEnd = function() {
			s.parent.removeChild(s);
		}
	}

	public function leaves(x,y) {
		for(i in 0...15) {
			var p = new Particle(x+rnd(0,5,true), y+rnd(0,5,true));
			p.drawBox(irnd(1,2), 1, 0x68a218, rnd(0.1, 0.8));
			p.dr = rnd(0, 5,true);
			p.moveAng( rnd(0, 6.28), rnd(1,2) );
			p.gx = rnd(0.02, 0.06);
			p.gy = 0.03 + rnd(0, 0.03, true);
			p.life = rnd(130, 200);
			p.delay = Lib.rnd(0,30);
			p.frictX = p.frictY = 0.86;
			register(p, NORMAL);
		}
	}

	public function heroExplode(e:en.Hero) {
		var p = new Particle(e.xx,e.yy);
		p.drawCircle(6, e.color, 1, false);
		p.ds = 0.2;
		p.life = 1;
		register(p);

		for(i in 0...20) {
			var p = new Particle(e.xx+rnd(0,7,true), e.yy+rnd(0,2,true));
			p.drawBox(2,2, e.color, rnd(0.3, 0.7));
			p.moveAng(rnd(0,6.28), rnd(0.4, 0.7));
			//var dir = Lib.sign();
			//p.dy = dir*rnd(1, 8);
			//p.gy = dir*rnd(0.05, 0.5);
			p.frictX = p.frictY = rnd(0.9, 0.95);
			p.life = rnd(5, 15);
			p.filters = [ new flash.filters.GlowFilter(e.color, 0.7, 8,8, 2) ];
			register(p);
		}

		for(i in 0...30) {
			var p = new Particle(e.xx+rnd(0,5,true), e.yy+rnd(0,5,true));
			p.drawBox(1,1, e.color, 1);
			var a = rnd(0,6.28);
			p.moveAng(a, rnd(1,2));
			p.pixel = true;
			//p.rotation = dn.M.toDeg(a);
			p.frictX = p.frictY = rnd(0.90, 0.98);
			p.life = rnd(10, 30);
			p.filters = [ new flash.filters.GlowFilter(e.color, 0.3, 2,2, 2) ];
			register(p);
		}
	}

	public function lava(x,y) {
		var w = irnd(1,2);
		var p = new Particle(x+rnd(0,5,true), y+rnd(0,2));
		p.drawBox(w, w, 0xffc600, rnd(0.3, 0.8));
		p.dy = -rnd(0.05, 0.2);
		p.frictY = rnd(0.85, 0.99);
		//p.dr = rnd(10, 20, true);
		//p.alpha = 0;
		//p.da = rnd(0.01, 0.03);
		p.life = rnd(5, 20);
		p.filters = [ new flash.filters.GlowFilter(0xFF5300,0.9, 8,8,1) ];
		register(p);
	}

	public function water(x,y) {
		//var w = irnd(1,2);
		var p = new Particle(x+rnd(0,3,true), y+rnd(0,2));
		p.drawBox(1, 1, 0xAFB5EF, rnd(0.3, 0.8));
		p.dy = -rnd(0.3, 1);
		p.dx = rnd(0, 0.5, true);
		p.gy = 0.05;
		p.groundY = p.y;
		p.frictX = 0.7;
		p.frictY = rnd(0.85, 0.99);
		//p.dr = rnd(10, 20, true);
		//p.alpha = 0;
		//p.da = rnd(0.01, 0.03);
		p.life = rnd(5, 10);
		p.filters = [ new flash.filters.GlowFilter(0x6c76e1,0.9, 4,4,2) ];
		register(p);
	}

	public function darkness() {
		var p = new Particle(rnd(0,game.buffer.width), rnd(0,game.buffer.height));
		p.drawBox(2,3, 0x0, rnd(0.1, 0.5));
		p.dx = rnd(0.1, 0.3, true);
		p.dy = -rnd(0.05, 0.2);
		p.dr = rnd(2, 7, true);
		p.alpha = 0;
		p.da = rnd(0.01, 0.03);
		p.life = rnd(30, 90);
		p.filters = [ new flash.filters.GlowFilter(0x0,0.7, 8,8,1) ];
		register(p, NORMAL, Const.DP_BG);
	}

	public function update() {
		Particle.update();
	}
}
