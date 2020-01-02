package en;

class Crate extends Entity {
	public function new(x,y) {
		super();
		setPos(x,y);
		weight = 0.3;
		bumper = true;
		climbable = true;
		spr.setGroup("crate");
		spr.setCenter(0.5,0.5);
		//spr.filters = [ new flash.filters.GlowFilter(0x0, 0.5, 2,2,4) ];
	}
	
}