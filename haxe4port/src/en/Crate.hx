package en;

class Crate extends Entity {
	public function new(x,y) {
		super();
		setPos(x,y);
		weight = 0.3;
		bumper = true;
		climbable = true;
		spr.set("crate");
		spr.setCenterRatio(0.5,0.5);
	}
	
}
