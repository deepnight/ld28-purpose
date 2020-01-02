import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

@:bitmap("assets/levels.png") class GfxLevel extends BitmapData {}

class Level {
	var lid		: Int;
	var map		: Array<Array<Bool>>;
	public var wid		: Int;
	public var hei		: Int;
	
	var source	: BitmapData;
	var spots	: Map<String, Array<{cx:Int, cy:Int}>>;
	
	public var wrapper	: Sprite;
	public var front	: Bitmap;
	public var bg		: Bitmap;
	
	public function new() {
		lid = 0;
		
		wid = hei = 20;
		spots = new Map();
		
		wrapper = new Sprite();
		Game.ME.buffer.dm.add(wrapper, Const.DP_BG);
		
		front = new Bitmap( new BitmapData(wid*Const.GRID, hei*Const.GRID, true, 0x0) );
		Game.ME.buffer.dm.add(front, Const.DP_FRONT);
		
		bg = new Bitmap( front.bitmapData.clone() );
		Game.ME.buffer.dm.add(bg, Const.DP_BG);
		
		source = new GfxLevel(0,0);
	}
	
	public function setLevel(n) {
		readLevel(n);
		render();
	}
	
	
	function addSpot(k:String, cx,cy) {
		if( spots[k]==null )
			spots[k] = [];
		spots[k].push({ cx:cx, cy:cy });
	}
	
	public function getSpots(k:String) {
		return spots[k]==null ? [] : spots[k];
	}
	public function getSpot(k:String) {
		return spots[k]==null ? null : spots[k][0];
	}
	
	function readLevel(n:Int) {
		spots = new Map();
		
		map = new Array();
		for(cx in 0...wid) {
			map[cx] = [];
			for(cy in 0...hei) {
				var p = source.getPixel(cx, cy+n*hei);
				if( p==0xFFFFFF )
					map[cx][cy] = true;
					
				if( p==0x007eff )
					addSpot("hero", cx,cy);
					
				if( p==0x00ff00 )
					addSpot("plant", cx,cy);
					
				if( p==0xFF0000 )
					addSpot("lava", cx,cy);
					
				if( p==0x00FFFF )
					addSpot("water", cx,cy);
					
				if( p==0x9a4800 )
					addSpot("crate", cx,cy);
					
			}
		}
		
		render();
	}
	
	public function render() {
		var pt0 = new flash.geom.Point();
		
		front.bitmapData.fillRect( front.bitmapData.rect, 0x0);
		bg.bitmapData.fillRect( bg.bitmapData.rect, 0x0);
		
		var m = new flash.geom.Matrix();
		m.createGradientBox(wid*Const.GRID, hei*Const.GRID, Math.PI);
		wrapper.graphics.beginGradientFill(flash.display.GradientType.LINEAR, [0x1E303E, 0x100f19], [1,1], [0,255], m);
		//wrapper.graphics.beginFill(0x100f19,1);
		wrapper.graphics.drawRect(0,0, wid*Const.GRID, hei*Const.GRID);
		
		var tiles = Game.ME.tiles;
		
		var fbd = front.bitmapData;
		var bbd = bg.bitmapData;
		
		for(cx in 0...wid)
			for(cy in 0...hei) {
				var x = Const.GRID*cx;
				var y = Const.GRID*cy;
				
				if( hasCollision(cx,cy) )
					tiles.drawIntoBitmapRandom(fbd, x-5,y-5, "ground");
				
				//if( hasCollision(cx,cy) ) {
					//wrapper.graphics.beginFill(0x000000,1);
					//wrapper.graphics.drawRect(x,y,Const.GRID, Const.GRID);
				//}
				
			}
			
		bbd.copyPixels(fbd, fbd.rect, pt0);
		bbd.applyFilter(bbd, bbd.rect, pt0, new flash.filters.GlowFilter(0x0,0.5, 8,8, 1, 2));
		bbd.applyFilter(bbd, bbd.rect, pt0, new flash.filters.GlowFilter(0x0,0.7, 32,32, 1, 2));
	}
	
	public function destroy() {
		wrapper.parent.removeChild(wrapper);
	}
	
	public function hasCollision(cx,cy) {
		return cx<0 || cy<0 || cx>=wid || cy>=hei ? true : map[cx][cy];
	}
}