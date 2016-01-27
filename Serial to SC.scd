SerialPort.listDevices;
(
s.waitForBoot{
	fork{
		//VARIABLES//////////////////////////////////////
		////Busses
		var kbs = {Bus.control(s)}!15;
		var abs = {Bus.audio(s)}!15;
		////Arduino
		var ino = ArduinoSMS("/dev/tty.usbmodem1a131", 9600);
		////Groups
		var gr = Array.newClear[4];
		////Buffers
		var bf = SoundFile.collectIntoBuffers("/Users/jyang/GitHub/DSPrig/samples/*", s);
		var freezebuf = Buffer.alloc(s, s.sampleRate*2); //buffer for freeze effect
		var envbuf = SoundFile.collectIntoBuffers("/Users/jyang/GitHub/DSPrig/grainEnv/*");
		////Data
		var hdr = ["fsr0"];
		var inlohi = [ [35,900] ];
		var crv = [20];
		var outlohi = [ [0.0,1.0] ];

		//SETUP//////////////////////////////////////////
		////Groups
		gr = gr.add(Group.new(s));
		3.do{|ix| gr = gr.add(Group.after(gr[ix]))};
		//Arduino Action Function
		ino.action = { |msg|
			var sm = msg.split($:);
			if(sm[0]==hdr[0],{
				var vnorm = sm[1].asFloat.linlin( inlohi[0][0], inlohi[0][1], 0.0, 1.0 );
				var vcrv = pow(vnorm, crv[0]);
				var val = vcrv.linlin(0.0, 1.0, outlohi[0][0], outlohi[0][1]);
				//val.postln;
				kbs[0].setSynchronous(val);
			});
		};//end arduino action function
		//SYNTH DEFS/////////////////////////////////////
		////Sample Player
		SynthDef(\playsamp, {
			arg obs, buf, rate=1, loop=1, amp=1;
			var sig;
			sig = PlayBuf.ar(1, buf, rate, \t_tr.kr(1, 0), 0, loop);
			Out.ar(obs, sig*amp);
		}).add;
		////Freeze Effect
		SynthDef(\icy, {
			arg ibs, obs=0, buf=0, envbuf = -1, pitchshift=1, winsz=0.8, overlaps=40,
			resettrig=0, startpos=0.0, endpos=1.0, rand=0.1, ratemax=0.4, ratemin=0.000001,
			indur=2, t_tr=1, rel=1.2, crv = -6, gate=1, amp=1;
			var sig, ix, krate, in, writehead, whenv, durenv, sig2;
			durenv = EnvGen.ar(Env.asr(0.01, 1, rel, curve: crv),gate,doneAction:2);
			writehead = Phasor.ar(0, BufRateScale.kr(buf), 0, BufFrames.kr(buf));
			whenv = EnvGen.ar(Env.linen(0.0, indur, 0.0), t_tr);
			in = BufWr.ar(In.ar(ibs), buf, writehead*whenv);
			krate = \rate.kr(1, 0.05).linlin(0.0, 1.0, ratemin, ratemax );
			ix = Phasor.kr(resettrig, ((1.0/ControlRate.ir)/(BufFrames.kr(buf)/SampleRate.ir))*krate, startpos, endpos);
			sig = Warp1.ar(1, buf, ix, pitchshift, winsz, envbuf, overlaps,rand);
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(obs, [sig, sig2]*durenv*amp);
		}).add;

		0.2.wait;
		//START SYNTHS///////////////////////////////////////////////
		////Sample Player Synth
		s.sendMsg( \s_new, \playsamp, 3000, 0, gr[1].nodeID, \obs, abs[0].index,\buf, bf[0].bufnum );
		////Freeze Effect Synth
		s.sendMsg( \s_new, \icy, 3100, 0, gr[2].nodeID, \ibs, abs[0].index, \obs, 0,
			\buf, freezebuf.bufnum, \winsz, 0.6, \overlaps, 27, \rand, 0.5,
			\envbuf, envbuf[3].bufnum, \indur, 2, \rel, 3, \crv, -3, \ratemax, 30, \ratemin, 0.000001 );
		s.sendMsg(\n_map, 3100, \rate, kbs[0].index);

	}//end fork
}// end waitForBoot
)

~ebf = SoundFile.collectIntoBuffers("/Users/jyang/GitHub/DSPrig/grainEnv/*");

SynthDef(\shortAttacks, {
	arg ibs, obs=0, amp=1, pan=0, dcrv=1,
	mindur=0.03, maxdur=0.5, minrate=0.2, maxrate=5.0, rcrv=4, ebf= -1;
	var sig, env, gtr, mtrig, dur;
	mtrig = Impulse.kr(maxrate);
	dur = pow( TRand.kr( 0.0, 1.0, mtrig), dcrv ).linlin(0.0, 1.0, mindur, maxdur);
	//dur = TRand.kr( mindur, maxdur, mtrig );
	gtr = Impulse.kr( pow( TRand.kr( 0.0, 1.0, mtrig), rcrv ).linlin(0.0, 1.0, minrate, maxrate) );
	//sig = In.ar(ibs);
	sig = Saw.ar(330);
	sig = GrainIn.ar(1, gtr,dur,sig,pan,ebf);
	//env = EnvGen.ar(Env.perc(atk, TRand.kr( minrel, maxrel, mtrig ), 1, crv), etrig);
	Out.ar(1, sig*amp);
}).add;

a = Synth(\shortAttacks);
a.set(\maxrate, 33, \minrate, 3, \mindur, 0.04, \maxdur, 0.2, \rcrv, 9, \dcrv, 8, \ebf, ~ebf[0]);



	{TChoose.kr(Impulse.kr(1), [0,5,7,9,13]).poll}.play







