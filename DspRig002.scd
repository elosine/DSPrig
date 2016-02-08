SerialPort.listDevices;
(
s.waitForBoot{
	fork{
		//VARIABLES//////////////////////////////////////
		////General
		var nb = 15;
		////Busses
		var kbs = {Bus.control(s)}!nb;
		var normkbs = {Bus.control(s)}!nb;
		var abs = {Bus.audio(s)}!nb;
		var fxabs = {Bus.audio(s)}!nb;
		////Arduino
		var ino = ArduinoSMS("/dev/tty.usbmodem1a131", 9600);
		////Groups
		var gr = Array.newClear[5];
		////Buffers
		var bf = SoundFile.collectIntoBuffers("/Users/jyang/GitHub/DSPrig/samples/*", s);
		var freezebuf = Buffer.alloc(s, s.sampleRate*2); //buffer for freeze effect
		var envbuf = SoundFile.collectIntoBuffers("/Users/jyang/GitHub/DSPrig/grainEnv/*");
		////Data
		var hdr = ["fsr0", "fsr1"];
		var inlohi = [ [250,900], [80,900] ];
		var crv = [11, 1];
		var outlohi = [ [0.0,1.0], [13.0,(1/3)]  ];

		//SETUP//////////////////////////////////////////
		////Groups
		gr = gr.add(Group.new(s));
		4.do{|ix| gr = gr.add(Group.after(gr[ix]))};
		//ARDUINO
		ino.action = { |msg|
			var sm = msg.split($:);
			hdr.do{|it ix|
				if(sm[0]==hdr[ix],{
					var vnorm = sm[1].asFloat.linlin( inlohi[ix][0], inlohi[ix][1], 0.0, 1.0 );
					var vcrv = pow(vnorm, crv[ix]);
					var val = vcrv.linlin(0.0, 1.0, outlohi[ix][0], outlohi[ix][1]);
					//if(ix==1,{val.postln});
					normkbs[ix].setSynchronous(vnorm);
					kbs[ix].setSynchronous(val);
				});
			};
		};//end ARDUINO
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
		//LANGUAGE MUSICS GRANULIZATION
		////Short Attacks
		SynthDef(\shortAttacks, {
			arg ibs, obs=0, amp=1, pan=0, dcrv=1,
			mindurL=0.02, mindurH=0.04, maxdurL=(1/7), maxdurH=0.5,
			minrateL=1.85, minrateH=4.0, maxrateL=9.0, maxrateH=15.0,
			ebf= -1;
			var sig, env, gtr, mtrig, dur, rcrv;
			var mindur, maxdur, minrate, maxrate;
			rcrv = \rcrv.kr(9, 0.05);
			mtrig = Impulse.kr(maxrateH);
			mindur = TRand.kr(mindurL, mindurH, mtrig);
			maxdur = TRand.kr(maxdurL, maxdurH, mtrig);
			minrate = TRand.kr(minrateL, minrateH, mtrig);
			maxrate = TRand.kr(maxrateL, maxrateH, mtrig);
			dur = pow( TRand.kr( 0.0, 1.0, mtrig), dcrv ).linlin(0.0, 1.0, mindur, maxdur);
			gtr = Impulse.kr( pow( TRand.kr( 0.0, 1.0, mtrig), rcrv ).linlin(0.0, 1.0, minrate, maxrate));
			sig = In.ar(ibs);
			sig = GrainIn.ar(1, gtr,dur,sig,pan,ebf);
			Out.ar(1, sig*amp);
		}).add;
		//OSC DEFS///////////////////////////////////////////////////
		////Send Control Bus Value to Processing
		OSCdef(\sendkval, {
			arg msg;
			var ip = msg[1].asString;
			var port = msg[2].asInteger;
			var netadr = NetAddr(ip, port);
			var bus = msg[3].asInteger;
			var val = normkbs[bus].getSynchronous.asFloat;
			netadr.sendMsg("/kval", bus, val);
		}, "/getkval" );
		0.2.wait;
		//START SYNTHS///////////////////////////////////////////////
		////Sample Player Synth
		s.sendMsg( \s_new, \playsamp, 3000, 0, gr[1].nodeID, \obs, abs[0].index,\buf, bf[0].bufnum );
		////Freeze Effect Synth
		s.sendMsg( \s_new, \icy, 3100, 0, gr[2].nodeID, \ibs, abs[0].index, \obs, fxabs[0].index,
			\buf, freezebuf.bufnum, \winsz, 0.6, \overlaps, 27, \rand, 0.5,
			\envbuf, envbuf[3].bufnum, \indur, 2, \rel, 3, \crv, -3, \ratemax, 30, \ratemin, 0.000001 );
		s.sendMsg(\n_map, 3100, \rate, kbs[0].index);
		//LANGUAGE MUSIC GRANULATION
		////Short Attacks Synth
		s.sendMsg( \s_new, \shortAttacks, 7000, 0, gr[3].nodeID, \ibs, fxabs[0].index, \obs, 0,
			\rcrv, 12, \dcrv, 2, \minrateL, 0.001, \minrateH, 0.003, \maxrateL, 21, \maxrateH, 33,\mindurL, 0.03, \mindurH, 0.1, \maxdurL, 0.3, \maxdurH, 0.7, \ebf, envbuf[3].bufnum );
		s.sendMsg(\n_map, 7000, \rcrv, kbs[1].index);

	}//end fork
}// end waitForBoot
)


