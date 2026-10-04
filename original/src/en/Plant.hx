package en;

import mt.deepnight.Lib;
import mt.deepnight.deprecated.SpriteLibBitmap;

class Plant extends Entity {
	var bad			: BSprite;
	var healed		: BSprite;

	public function new(x,y) {
		super();
		setPos(x,y);

		bad = spr.clone();
		bad.setGroup("plant");
		spr.addChild(bad);

		healed = bad.clone();
		healed.setFrame(1);
		healed.alpha = 0;
		spr.addChild(healed);

		//consume( Hero.ALL[0] );
		#if debug
		grow();
		#end
	}

	function consume(e:Hero) {
		Fx.ME.flashBang(0xFF7915, 0.3, 700);
		e.destroy();
		Fx.ME.heroExplode(e);
		Game.ME.levelComplete();

		Game.ME.delayer.addMs( grow, 600 );
	}

	function grow() {
		Game.ME.tw.create(healed,"alpha", 1, TEaseOut, 700);
		Game.ME.tw.create(bad,"alpha", 0, TEaseIn, 700);

		// Branches
		var angles = [];
		for( i in 0...3 ) {
			var s = Game.ME.tiles.getRandom("branch");
			s.setCenter(0.5,1);
			s.x = Lib.irnd(0,2,true);
			s.y = -Lib.irnd(5,10);
			s.rotation = -45 + i*45;
			angles.push( dn.M.toRad(s.rotation+90) );
			s.scaleX = s.scaleY = 0;
			s.filters = [ new flash.filters.GlowFilter(0x311200, 0.7, 2,2,4) ];
			Game.ME.tw.create(s, "scaleX", 1, Lib.rnd(600,2000)).onUpdate = function() {
				s.scaleY = s.scaleX;
			}
			spr.addChild(s);
		}

		Game.ME.delayer.addMs( function() {

		}, 1000);

		Game.ME.delayer.addMs( function() {
			Fx.ME.flashBang(0x97E133, 0.3, 1000);
		}, 1200);

		// Main leaves
		var i = 0;
		for( a in angles ) {
			var s = Game.ME.tiles.getRandom("leaf");
			s.setCenter(0.5, 0.5);
			var d = Lib.rnd(15,18);
			s.x = Math.cos(a)*d;
			s.y = -5 - Math.sin(a)*d;
			s.scaleX = s.scaleY = 0;
			Game.ME.delayer.addMs( function() {
				Fx.ME.leaves(xx+s.x, yy+s.y-5);
				Game.ME.tw.create(s, "y", s.y-5, Lib.rnd(200,400));
				Game.ME.tw.create(s, "scaleX", 1, Lib.rnd(200,400)).onUpdate = function() {
					s.scaleY = s.scaleX;
				}
			}, 1000+i*100);
			spr.addChild(s);
			i++;
		}

		// Extra leaves
		for( i in 0...5 ) {
			var a = angles[Std.random(angles.length)] + Lib.rnd(0, 0.2, true);
			var s = Game.ME.tiles.getRandom("leaf");
			s.setCenter(0.5, 0.5);
			var d = Lib.rnd(12,22);
			s.x = Math.cos(a)*d;
			s.y = -5 - Math.sin(a)*d;
			s.scaleX = s.scaleY = 0;
			Game.ME.delayer.addMs( function() {
				Game.ME.tw.create(s, "scaleX", 1, Lib.rnd(200,400)).onUpdate = function() {
					s.scaleY = s.scaleX;
				}
			}, 1000+i*250);
			spr.addChild(s);
		}

	}

	override function update() {
		super.update();

		for(e in Hero.ALL) {
			if( distance2(e) < dn.M.pow(radius, 2) ) {
				consume(e);
			}
		}
	}
}