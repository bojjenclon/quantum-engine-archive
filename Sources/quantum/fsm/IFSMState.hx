package quantum.fsm;

@:allow(FSM)
interface IFSMState<T>
{
	public final name : String;

	private var _fsm : FSM<T>;
	private var _owner : T;

	public function update(dt : Float) : Void;

	private function onEnterState(from : IFSMState<T>) : Void;

	private function onExitState(to : IFSMState<T>) : Void;
}
