package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author flashisobar
	 */
	public class Main extends Sprite
	{
		
		public function Main():void
		{
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			var dice:Dice3D = new Dice3D();
			dice.x = -(stage.stageWidth - 800) >> 1;
			dice.y = -(stage.stageHeight - 600) >> 1;
			this.addChild(dice);
		}
	
	}

}