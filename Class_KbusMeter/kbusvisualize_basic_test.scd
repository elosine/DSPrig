(
~kb = Bus.control(s);
~proc = NetAddr("127.0.0.1", 12321);
SynthDef(\kbtest, {
	arg bus, freq=0.2;
	Out.kr( bus, SinOsc.kr(0.2).range(0.0, 1.0) )
}).add;

OSCdef(\sendkval, {
	arg msg;
	var val = ~kb.getSynchronous.asFloat;
	val.postln;
	~proc.sendMsg("/kval", val);
}, "/getkval" );
)

a = Synth(\kbtest, [\bus, ~kb]);