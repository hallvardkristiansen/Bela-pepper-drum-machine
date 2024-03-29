s = Server.default;

s.options.memSize = 8192 * 16; // the default is 8192 which is quite little

s.options.numAnalogInChannels = 8; // can only be 2, 4 or 8
s.options.numAnalogOutChannels = 8;
s.options.numDigitalChannels = 16;
s.options.maxLogins = 8;  	   // set max number of clients
s.options.headphoneLevel = 0; // sets the headphone level to -14 dB: it might get loud

s.options.blockSize = 128;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;


s.waitForBoot{
	"Server Booted".postln;

	~modes = 9;
	~mode = 0;
	~leds = [6,7,10,2,3,0,1,4,5,8];

	~cv1_out=0;
	~cv2_out=1;
	~cv3_out=2;
	~cv4_out=3;
	~t1_out=4;
	~t2_out=5;
	~t3_out=6;
	~t4_out=7;

	~knob1 = 0.5;
	~knob2 = 0.5;
	~knob3 = 0.5;
	~knob4 = 0.5;
	~knob5 = 0.5;
	~knob6 = 0.5;
	~knob7 = 0.5;
	~knob8 = 0.5;
	~trg0 = 0;
	~trg1 = 0;
	~trg2 = 0;
	~trg3 = 0;
	~trg4 = 0;
	~trg5 = 0;
	~trg6 = 0;
	~trg7 = 0;


	MIDIClient.init;
	MIDIIn.connectAll;


	SynthDef(\ledblink, {
		|ledpin|
		var ledEnv, ledMux;
		ledEnv = EnvGen.kr(Env.linen(0.005, 0.1, 0.2), doneAction: 2);
		ledMux = Pulse.kr(freq: 50.0, width: ledEnv, mul: 2.0, add: 0.0);
		DigitalOut.kr(ledpin, ledMux);
	}).send(s);


	SynthDef(\kick, {
		|out = 0, pan = 0, amp = 0.8|
		var body, bodyFreq, bodyAmp;
		var pop, popFreq, popAmp;
		var click, clickAmp;
		var snd;

		// body starts midrange, quickly drops down to low freqs, and trails off
		bodyFreq = EnvGen.ar(Env([261, 120, 51], [0.035, 0.08], curve: \exp));
		bodyAmp = EnvGen.ar(Env.linen(0.005, 0.1, 0.3), doneAction: 2);
		body = SinOsc.ar(bodyFreq) * bodyAmp;
		// pop sweeps over the midrange
		popFreq = XLine.kr(750, 261, 0.02);
		popAmp = EnvGen.ar(Env.linen(0.001, 0.02, 0.001)) * 0.15;
		pop = SinOsc.ar(popFreq) * popAmp;
		// click is spectrally rich, covering the high-freq range
		// you can use Formant, FM, noise, whatever
		clickAmp = EnvGen.ar(Env.perc(0.001, 0.01)) * 0.15;
		click = LPF.ar(Formant.ar(910, 4760, 2110), 3140) * clickAmp;

		snd = body + pop + click;
		snd = snd.tanh;

		Out.ar(out, Pan2.ar(snd, pan, amp));
	}).send(s);

	SynthDef(\kick1, {
		|out = 0, pan = 0, amp = 0.5|
		var snd;
		snd = DC.ar(0);
		snd = snd + (SinOsc.ar(XLine.ar(800, 400, 0.01)) * Env.perc(0.0005, 0.01).ar);
		snd = snd + (BPF.ar(Hasher.ar(Sweep.ar), XLine.ar(800, 100, 0.01), 0.6) * Env.perc(0.001, 0.02).delay(0.001).ar);
		snd = snd + (SinOsc.ar(XLine.ar(172, 50, 0.01)) * Env.perc(0.0001, 0.3, 1, \lin).delay(0.005).ar(2));
		snd = snd.tanh;

		Out.ar(out, Pan2.ar(snd, pan, amp));
	}).send(s);


	SynthDef(\kick2, {
		|out = 0, pan = 0, amp = 0.5|
		var snd;
		snd = DC.ar(0);
		snd = snd + (HPF.ar(Hasher.ar(Sweep.ar), 1320) * Env.perc(0.003, 0.03).ar * 0.5);
		snd = snd + (SinOsc.ar(XLine.ar(750, 161, 0.02)) * Env.perc(0.0005, 0.02).ar);
		snd = snd + (SinOsc.ar(XLine.ar(167, 52, 0.04)) * Env.perc(0.0005, 0.3).ar(2));
		snd = snd.tanh;
		Out.ar(out, Pan2.ar(snd, pan, amp));
	}).send(s);

	SynthDef(\kick3, {
		|out = 0, pan = 0, amp = 0.5|
		var snd;
		snd = DC.ar(0);
		snd = snd + (SinOsc.ar(XLine.ar(1500, 800, 0.01)) * Env.perc(0.0005, 0.01, curve: \lin).ar);
		snd = snd + (BPF.ar(Impulse.ar(0) * SampleRate.ir / 48000, 6100, 1.0) * 3.dbamp);
		snd = snd + (BPF.ar(Hasher.ar(Sweep.ar), 300, 0.9) * Env.perc(0.001, 0.02).ar);
		snd = snd + (SinOsc.ar(XLine.ar(472, 60, 0.045)) * Env.perc(0.0001, 0.3, curve: \lin).delay(0.005).ar(2));
		snd = snd.tanh;
		Out.ar(out, Pan2.ar(snd, pan, amp));
	}).send(s);


	SynthDef(\snare, {
		|out = 0, pan = 0, amp = 0.8|
		var pop, popAmp, popFreq;
		var noise, noiseAmp;
		var snd;

		// pop makes a click coming from very high frequencies
		// slowing down a little and stopping in mid-to-low
		popFreq = EnvGen.ar(Env([3261, 410, 160], [0.005, 0.01], curve: \exp));
		popAmp = EnvGen.ar(Env.perc(0.001, 0.11)) * 0.7;
		pop = SinOsc.ar(popFreq) * popAmp;
		// bandpass-filtered white noise
		noiseAmp = EnvGen.ar(Env.perc(0.001, 0.15), doneAction: 2);
		noise = BPF.ar(WhiteNoise.ar, 810, 1.6) * noiseAmp;

		snd = (pop + noise) * 1.3;

		Out.ar(out, Pan2.ar(snd, pan, amp));
	}).send(s);

	SynthDef(\neurosnare, {
		|out = 0, pan = 0, amp = 0.7|
		var snd;
		// a percussive click to give it some attack
		snd = LPF.ar(HPF.ar(WhiteNoise.ar, 300), 8000) * Env.linen(0.001, 0.01, 0.001).ar;
		// sine sweep body. very important!
		snd = snd + (SinOsc.ar(Env([400, 196, 160], [0.04, 0.2], \exp).ar) * Env.perc(0.04, 0.2).ar * 6.dbamp).tanh;
		// sound of snare coils rattling
		snd = snd + (HPF.ar(BPeakEQ.ar(WhiteNoise.ar, 4000, 0.5, 3), 300) * Env.perc(0.05, 0.2).delay(0.01).ar(2) * -3.dbamp);
		// another sound sweep to improve the attack, optional
		snd = snd + (SinOsc.ar(XLine.kr(3000, 1500, 0.01)) * Env.perc(0.001, 0.02).ar);
		// distortion helps glue everything together and acts as a compressor
		snd = (snd * 1.4).tanh;
		Out.ar(out, Pan2.ar(snd, pan, amp));
	}).send(s);

	//Synth(\neurosnare, [amp: 0.4]);

	SynthDef(\hihat, {
		|out = 0, pan = 0, amp = 0.8|
		var click, clickAmp;
		var noise, noiseAmp;
		var snd;

		// noise -> resonance -> expodec envelope
		noiseAmp = EnvGen.ar(Env.perc(0.001, 0.3, curve: -8), doneAction: 2);
		noise = Mix(BPF.ar(ClipNoise.ar, [4010, 4151], [0.15, 0.56], [1.0, 0.6])) * 0.7 * noiseAmp;

		snd = noise;

		Out.ar(out, Pan2.ar(snd, pan, amp));
	}).send(s);

	// adapted from a post by Neil Cosgrove (other three are original)
	SynthDef(\clap, {
		|out = 0, amp = 0.8, pan = 0, dur = 1|
		var env1, env2, snd, noise1, noise2;

		// noise 1 - 4 short repeats
		env1 = EnvGen.ar(
			Env.new(
				[0, 1, 0, 0.9, 0, 0.7, 0, 0.5, 0],
				[0.001, 0.009, 0, 0.008, 0, 0.01, 0, 0.03],
				[0, -3, 0, -3, 0, -3, 0, -4]
			)
		);

		noise1 = WhiteNoise.ar(env1);
		noise1 = HPF.ar(noise1, 600);
		noise1 = LPF.ar(noise1, XLine.kr(7200, 4000, 0.03));
		noise1 = BPF.ar(noise1, 1620, 3);

		// noise 2 - 1 longer single
		env2 = EnvGen.ar(Env.new([0, 1, 0], [0.02, 0.18], [0, -4]), doneAction:2);

		noise2 = WhiteNoise.ar(env2);
		noise2 = HPF.ar(noise2, 1000);
		noise2 = LPF.ar(noise2, 7600);
		noise2 = BPF.ar(noise2, 1230, 0.7, 0.7);

		snd = noise1 + noise2;
		snd = snd * 2;
		snd = snd.softclip;

		Out.ar(out, Pan2.ar(snd,pan,amp));
	}).send(s);

	SynthDef(\cowbell, {
		| out=0, amp=0.8, fund_freq=540, pan=0.0 |
		var sig, env, hash;

		// hash = DC.ar(0);
		hash = BPF.ar(
			Hasher.ar(Sweep.ar(rate: TRand.kr(1.0, 10.0))),
			fund_freq * 1.4,
			0.5,
			2
		).tanh * Env.perc(0.001, 0.02).ar(0);
		sig = Pulse.ar( fund_freq * [ 1, 1.5085 ], [ 0.565, 0.445 ], [ 0.4, 0.6 ] ).atan;
		env = EnvGen.ar(
			Env(
				[ 0, 0.05, 1, 0.1, 0 ], [ 0.003, 0.002, 0.05, 0.5 ], [2, -4, -4, -4]
			),
			timeScale: [ 1.0, 1.5 ],
			doneAction: 2
		);
		sig = Mix( (hash + sig) * env );
		sig = BPF.ar( sig, fund_freq * 2, 1.808 );

		Out.ar( out, Pan2.ar( sig, pan, amp ) );
	}).send(s);

	SynthDef(\reverb, {| inChan = 0, amp=0.8, pan=0.0, mix=0.0, room=0.0, damp=0.0|
		var in, snd;
		in = SoundIn.ar([0,1]);
		snd = FreeVerb.ar(in, mix, room, damp);
		Out.ar(0,Pan2.ar( snd, pan, amp ));
	}).send(s);

	s.sync;

	~rvrb = Synth(\reverb, [amp: 0.8, pan: 0.0, mix: 0.0, room: 0.0, damp: 0.0]);

	~knobMonitor1 = {
		var a0 = AnalogIn.kr(0);
		a0 = a0.round(0.05);
		SendReply.kr(Changed.kr(a0), '/knobMonitor1', [a0]);
	}.play;
	~knobMonitor2 = {
		var a1 = AnalogIn.kr(1);
		a1 = a1.round(0.05);
		SendReply.kr(Changed.kr(a1), '/knobMonitor2', [a1]);
	}.play;
	~knobMonitor3 = {
		var a2 = AnalogIn.kr(2);
		a2 = a2.round(0.05);
		SendReply.kr(Changed.kr(a2), '/knobMonitor3', [a2]);
	}.play;
	~knobMonitor4 = {
		var a3 = AnalogIn.kr(3);
		a3 = a3.round(0.05);
		SendReply.kr(Changed.kr(a3), '/knobMonitor4', [a3]);
	}.play;
	~knobMonitor5 = {
		var a4 = AnalogIn.kr(4);
		a4 = a4.round(0.05);
		SendReply.kr(Changed.kr(a4), '/knobMonitor5', [a4]);
	}.play;
	~knobMonitor6 = {
		var a5 = AnalogIn.kr(5);
		a5 = a5.round(0.05);
		SendReply.kr(Changed.kr(a5), '/knobMonitor6', [a5]);
	}.play;
	~knobMonitor7 = {
		var a6 = AnalogIn.kr(6);
		a6 = a6.round(0.05);
		SendReply.kr(Changed.kr(a6), '/knobMonitor7', [a6]);
	}.play;
	~knobMonitor8 = {
		var a7 = AnalogIn.kr(7);
		a7 = a7.round(0.05);
		SendReply.kr(Changed.kr(a7), '/knobMonitor8', [a7]);
	}.play;


	OSCdef('listenToKnob1', {
		arg msg;
		~knob1 = msg[3];
	}, '/knobMonitor1');
	OSCdef('listenToKnob2', {
		arg msg;
		~knob2 = msg[3];
	}, '/knobMonitor2');
	OSCdef('listenToKnob3', {
		arg msg;
		~knob3 = msg[3];
	}, '/knobMonitor3');
	OSCdef('listenToKnob4', {
		arg msg;
		~knob4 = msg[3];
	}, '/knobMonitor4');
	OSCdef('listenToKnob5', {
		arg msg;
		~knob5 = msg[3];
		~rvrb.set(\mix, ~knob5);
	}, '/knobMonitor5');
	OSCdef('listenToKnob6', {
		arg msg;
		~knob6 = msg[3];
		~rvrb.set(\room, ~knob6);
	}, '/knobMonitor6');
	OSCdef('listenToKnob7', {
		arg msg;
		~knob7 = msg[3];
		~rvrb.set(\damp, ~knob7);
	}, '/knobMonitor7');
	OSCdef('listenToKnob8', {
		arg msg;
		~knob8 = msg[3];
		~rvrb.set(\amp, ~knob8);
	}, '/knobMonitor8');


	~instruments1 = [\kick, \kick1, \kick2, \kick3, \kick, \kick1, \kick2, \kick3, \kick1, \kick2];
	~instruments2 = [\hihat, \hihat, \hihat, \hihat, \hihat, \hihat, \hihat, \hihat, \hihat, \hihat];
	~instruments3 = [\clap, \clap, \clap, \clap, \clap, \clap, \clap, \clap, \cowbell, \cowbell];
	~instruments4 = [\snare, \snare, \snare, \snare, \neurosnare, \neurosnare, \neurosnare, \neurosnare, \snare, \neurosnare];

	~buttonMonitor1 = {
		var d15 = DigitalIn.kr(15);
		SendReply.kr(Changed.kr(d15), '/buttonMonitor1', [d15]);
	}.play;

	~buttonMonitor2 = {
		var d14 = DigitalIn.kr(14);
		SendReply.kr(Changed.kr(d14), '/buttonMonitor2', [d14]);
	}.play;


	~btn1 = 0;
	~btn2 = 0;

	// Listen to the buttons
	OSCdef('listenToButton1', {
		arg msg;
		~btn1 = msg[3].asInteger;
		if (~btn1 == 1, {
			~mode = ~mode-1;
			if (~mode < 0, {
				~mode = ~modes;
			});
			~leds.do({ arg led, i;
				if ({i == ~mode}.value, {
					Synth(\ledblink, [ledpin: led]);
				});
			});
		});
	}, '/buttonMonitor1');

	OSCdef('listenToButton2', {
		arg msg;
		~btn2 = msg[3].asInteger;
		if (~btn2 == 1, {
			~mode = ~mode+1;
			if (~mode > ~modes, {
				~mode = 0;
			});
			~leds.do({ arg led, i;
				if ({i == ~mode}.value, {
					Synth(\ledblink, [ledpin: led]);
				});
			});
		});
	}, '/buttonMonitor2');


	~triggerMonitor4 = {
		var d11 = DigitalIn.kr(11);
		SendReply.kr(Changed.kr(d11), '/trigger4', [d11]);
	}.play;

	~triggerMonitor5 = {
		var d9 = DigitalIn.kr(9);
		SendReply.kr(Changed.kr(d9), '/trigger5', [d9]);
	}.play;

	~triggerMonitor6 = {
		var d13 = DigitalIn.kr(13);
		SendReply.kr(Changed.kr(d13), '/trigger6', [d13]);
	}.play;

	~triggerMonitor7 = {
		var d12 = DigitalIn.kr(12);
		SendReply.kr(Changed.kr(d12), '/trigger7', [d12]);
	}.play;


	OSCdef('listenToTrigger4', {
		arg msg;
		~trg4 = msg[3].asInteger;
		if (~trg4 == 1, {
			Synth(~instruments1[~mode], [amp: ~knob1]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[4]]);
			});
		});
	}, '/trigger4');

	OSCdef('listenToTrigger5', {
		arg msg;
		~trg5 = msg[3].asInteger;
		if (~trg5 == 1, {
			Synth(~instruments2[~mode], [amp: ~knob2]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[5]]);
			});
		});
	}, '/trigger5');

	OSCdef('listenToTrigger6', {
		arg msg;
		~trg6 = msg[3].asInteger;
		if (~trg6 == 1, {
			Synth(~instruments3[~mode], [amp: ~knob3]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[6]]);
			});
		});
	}, '/trigger6');

	OSCdef('listenToTrigger7', {
		arg msg;
		~trg7 = msg[3].asInteger;
		if (~trg7 == 1, {
			Synth(~instruments4[~mode], [amp: ~knob4]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[7]]);
			});
		});
	}, '/trigger7');

	s.sync;

	// register functions:
	// send pitch and gate
	SynthDef(\cvout, {
	    arg opin, tpin, lpin, gate=0,note=0,bend=0;
		AnalogOut.kr(opin, output:note+bend);
		AnalogOut.kr(tpin, output:gate);
		DigitalIO.kr(lpin, output:gate, pinMode:1 );
	}).send(s);

	s.sync;

	// setup for cv pitch/trig mappings
	~cvsynths = [
		Synth(\cvout,[\opin, ~cv1_out, \tpin, ~t1_out, \lpin, ~leds[0]] ),
		Synth(\cvout,[\opin, ~cv2_out, \tpin, ~t2_out, \lpin, ~leds[1]] ),
		Synth(\cvout,[\opin, ~cv3_out, \tpin, ~t3_out, \lpin, ~leds[2]] ),
		Synth(\cvout,[\opin, ~cv4_out, \tpin, ~t4_out, \lpin, ~leds[3]] )
	];

	~midipoly = [0, 0, 0, 0];

	s.sync;


	//  note on, send out pitch/gate (midi channel 1-4)
	MIDIdef.noteOn(\noteon, {
		arg vel, note, chan;
		if (note >= 20, {
			var v = note.linlin(20,80,0,1);
			var found = false;
			[note, v , vel, "note on"].postln;
			~midipoly.do({ arg key, i;
				if (found == false, {
					if (key == 0, {
						~midipoly[i] = note;
						~cvsynths[i].set(\note, v);
						~cvsynths[i].set(\gate, vel>0);
						found = true;
					});
				});
			});
		}, {
			var relVelocity = vel.linlin(0,128,0,1);
			if (note < 4, {
				Synth(~instruments1[~mode], [amp: relVelocity]);
				Synth(\ledblink, [ledpin: ~leds[4]]);
			},{ if (note < 8, {
				Synth(~instruments2[~mode], [amp: relVelocity]);
				Synth(\ledblink, [ledpin: ~leds[5]]);
			},{ if (note < 12, {
				Synth(~instruments3[~mode], [amp: relVelocity]);
				Synth(\ledblink, [ledpin: ~leds[6]]);
			},{
				Synth(~instruments4[~mode], [amp: relVelocity]);
				Synth(\ledblink, [ledpin: ~leds[7]]);
			})})});
		});
	});

	//  note off, send out pitch/gate (midi channel 1-4)
	MIDIdef.noteOff(\noteoff, {
		arg vel, note, chan;
		~midipoly.do({ arg key, i;
			if (key == note, {
				~midipoly[i] = 0;
				~cvsynths[i].set(\gate, 0);
			});
		});
	});

	MIDIdef.bend(\bendchange, {
		arg val;
		~midibend = val;
		~cvsynths.do{arg cvout; cvout.set(\bend, val.linlin(0,16383,-0.2,0.2))};
	});

	MIDIdef.cc(\controlchange, {
		arg amnt, cmnd, chan;
		var lvl = amnt.linlin(0,127,0,1);
		[cmnd, amnt, "control change"].postln;

		if (cmnd == 7, { // F1 / Master
		});
		if (cmnd == 74, { // F2
		});
		if (cmnd == 71, { // F3
		});
		if (cmnd == 91, { // F4
		});
		if (cmnd == 93, { // F5
		});
		if (cmnd == 73, { // F6
		});
		if (cmnd == 72, { // F7
		});
		if (cmnd == 5, { // F8
		});
		if (cmnd == 84, { // F9
		});

		if (cmnd == 10, { // E1
			~rvrb.set(\mix, lvl);
		});
		if (cmnd == 2, { // E2
			~rvrb.set(\room, lvl);
		});
		if (cmnd == 12, { // E3
			~rvrb.set(\damp, lvl);
		});
		if (cmnd == 13, { // E4
			~rvrb.set(\amp, lvl);
		});
		if (cmnd == 75, { // E5
			~rvrb.set(\mix, lvl);
		});
		if (cmnd == 76, { // E6
			~rvrb.set(\room, lvl);
		});
		if (cmnd == 91, { // E7
			~rvrb.set(\damp, lvl);
		});
		if (cmnd == 95, { // E8
			~rvrb.set(\amp, lvl);
		});
	});


	~initialize_values = {
		var a0 = AnalogIn.kr(0);
		var a1 = AnalogIn.kr(1);
		var a2 = AnalogIn.kr(2);
		var a3 = AnalogIn.kr(3);
		var a4 = AnalogIn.kr(4);
		var a5 = AnalogIn.kr(5);
		var a6 = AnalogIn.kr(6);
		var a7 = AnalogIn.kr(7);
		a0 = a0.round(0.05);
		a1 = a1.round(0.05);
		a2 = a2.round(0.05);
		a3 = a3.round(0.05);
		a4 = a4.round(0.05);
		a5 = a5.round(0.05);
		a6 = a6.round(0.05);
		a7 = a7.round(0.05);
		SendReply.kr(Changed.kr(a0), '/knobMonitor1', [a0]);
		SendReply.kr(Changed.kr(a1), '/knobMonitor2', [a1]);
		SendReply.kr(Changed.kr(a2), '/knobMonitor3', [a2]);
		SendReply.kr(Changed.kr(a3), '/knobMonitor4', [a3]);
		SendReply.kr(Changed.kr(a4), '/knobMonitor5', [a4]);
		SendReply.kr(Changed.kr(a5), '/knobMonitor6', [a5]);
		SendReply.kr(Changed.kr(a6), '/knobMonitor7', [a6]);
		SendReply.kr(Changed.kr(a7), '/knobMonitor8', [a7]);
	}.play;

	s.sync;
};
