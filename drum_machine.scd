s = Server.default;

s.options.memSize = 8192 * 16; // the default is 8192 which is quite little

s.options.numAnalogInChannels = 8; // can only be 2, 4 or 8
s.options.numAnalogOutChannels = 8;
s.options.numDigitalChannels = 16;
s.options.maxLogins = 8;  	   // set max number of clients
s.options.headphoneLevel = -14; // sets the headphone level to -14 dB: it might get loud

s.options.blockSize = 128;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;


s.waitForBoot{
	"Server Booted".postln;


	~knob5 = 0;
	~knob6 = 0;
	~knob7 = 0;
	~knob8 = 0;

	~trg0 = 0;
	~trg1 = 0;
	~trg2 = 0;
	~trg3 = 0;
	~trg4 = 0;
	~trg5 = 0;
	~trg6 = 0;
	~trg7 = 0;

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


	SynthDef(\cello1, {
		| out=0, amp=0.8, fund_freq=540, pan=0.0, gate=0 |
		var freq = \freq.kr(440 * gate);
		var osc1 = Pulse.ar(freq, 0.1);
		var osc2 = Pulse.ar(freq);
		var lfo = 0.1 * SinOsc.kr(7.5);
		var oscs = (osc1 + osc2) * 0.5;
		var aenv = EnvGen.ar(Env.asr(0.06, 1, 0.3), gate, doneAction: Done.freeSelf);
		oscs = DFM1.ar(oscs, EnvGen.kr(Env.adsr(0, 3.29, 0.78, 3), gate).linexp(0, 1, 40,  10000), 0) * aenv;
		Out.ar(out, Pan2.ar( oscs * (1 + lfo), pan, amp ));
	}).send(s);


	SynthDef(\reverb, {| inChan = 0, amp=0.8, pan=0.0, mix=0.0, room=0.0, damp=0.0|
		var in, snd;
		in = SoundIn.ar([0,1]);
		snd = FreeVerb.ar(in, mix, room, damp);
		Out.ar(0,Pan2.ar( snd, pan, amp ));
	}).send(s);

	s.sync;

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

	OSCdef('listenToKnob5', {
		arg msg;
		~knob5 = msg[3] / 5;
		~effect.set(mix: ~knob5);
	}, '/knobMonitor5');
	OSCdef('listenToKnob6', {
		arg msg;
		~knob6 = msg[3] / 5;
		~effect.set(room: ~knob6);
	}, '/knobMonitor6');
	OSCdef('listenToKnob7', {
		arg msg;
		~knob7 = msg[3] / 5;
		~effect.set(damp: ~knob7);
	}, '/knobMonitor7');
	OSCdef('listenToKnob8', {
		arg msg;
		~knob8 = msg[3] / 5;
		~effect.set(pan: ~knob8);
	}, '/knobMonitor8');

	~modes = 9;
	~mode = 0;
	~leds = [6,7,10,2,3,0,1,4,5,8];

	~instruments0 = [\cowbell, \kick1, \kick2, \kick3, \snare, \neurosnare, \clap, \hihat, \cowbell, \cowbell];
	~instruments1 = [\cowbell, \kick2, \kick3, \snare, \neurosnare, \clap, \hihat, \cowbell, \cowbell, \kick];
	~instruments2 = [\cowbell, \kick3, \snare, \neurosnare, \clap, \hihat, \cowbell, \cowbell, \kick, \kick1];
	~instruments3 = [\cowbell, \snare, \neurosnare, \clap, \hihat, \cowbell, \cowbell, \kick, \kick1, \kick2];
	~instruments4 = [\kick, \kick1, \kick2, \kick3, \kick, \kick1, \kick2, \kick3, \kick, \kick1];
	~instruments5 = [\snare, \snare, \snare, \snare, \snare, \snare, \snare, \snare, \snare, \snare];
	~instruments6 = [\clap, \clap, \clap, \clap, \clap, \clap, \clap, \clap, \clap, \clap];
	~instruments7 = [\hihat, \hihat, \hihat, \hihat, \cowbell, \cowbell, \cowbell, \cowbell, \hihat, \hihat];

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

	~triggerMonitor0 = {
		var a0 = AnalogIn.kr(0);
		a0 = a0.round(0.05);
		SendReply.kr(Changed.kr(a0), '/trigger0', [a0]);
	}.play;

	~triggerMonitor1 = {
		var a1 = AnalogIn.kr(1);
		a1 = a1.round(0.05);
		SendReply.kr(Changed.kr(a1), '/trigger1', [a1]);
	}.play;

	~triggerMonitor2 = {
		var a2 = AnalogIn.kr(2);
		a2 = a2.round(0.05);
		SendReply.kr(Changed.kr(a2), '/trigger2', [a2]);
	}.play;

	~triggerMonitor3 = {
		var a3 = AnalogIn.kr(3);
		a3 = a3.round(0.05);
		SendReply.kr(Changed.kr(a3), '/trigger3', [a3]);
	}.play;

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


	// Listen to the triggers
	OSCdef('listenToTrigger0', {
		arg msg;
		~trg0 = msg[3];
		if (~trg0 >= 0.1, {
			~synth1 = Synth(~instruments0[~mode], [amp: 1, gate: ~trg0]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[0]]);
			});
		});
	}, '/trigger0');

	OSCdef('listenToTrigger1', {
		arg msg;
		~trg1 = msg[3];
		if (~trg1 >= 0.1, {
			Synth(~instruments1[~mode], [amp: 1]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[1]]);
			});
		});
	}, '/trigger1');

	OSCdef('listenToTrigger2', {
		arg msg;
		~trg2 = msg[3];
		if (~trg2 >= 0.1, {
			Synth(~instruments2[~mode], [amp: 1]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[2]]);
			});
		});
	}, '/trigger2');

	OSCdef('listenToTrigger3', {
		arg msg;
		~trg3 = msg[3];
		if (~trg3 >= 0.1, {
			Synth(~instruments3[~mode], [amp: 1]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[3]]);
			});
		});
	}, '/trigger3');

	OSCdef('listenToTrigger4', {
		arg msg;
		~trg4 = msg[3].asInteger;
		if (~trg4 == 1, {
			Synth(~instruments4[~mode], [amp: 1]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[4]]);
			});
		});
	}, '/trigger4');

	OSCdef('listenToTrigger5', {
		arg msg;
		~trg5 = msg[3].asInteger;
		if (~trg5 == 1, {
			Synth(~instruments5[~mode], [amp: 1]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[5]]);
			});
		});
	}, '/trigger5');

	OSCdef('listenToTrigger6', {
		arg msg;
		~trg6 = msg[3].asInteger;
		if (~trg6 == 1, {
			Synth(~instruments6[~mode], [amp: 1]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[6]]);
			});
		});
	}, '/trigger6');

	OSCdef('listenToTrigger7', {
		arg msg;
		~trg7 = msg[3].asInteger;
		if (~trg7 == 1, {
			Synth(~instruments7[~mode], [amp: 1]);
			if (~btn1 != 1, {
				Synth(\ledblink, [ledpin: ~leds[7]]);
			});
		});
	}, '/trigger7');
	s.sync;

	~effect = Synth(\reverb);
};
