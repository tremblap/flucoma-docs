strong::A didactic example::

code::
//mono source of 3 sines
b = {SinOsc.ar([440,789,1664],mul: [0.01,0.03,0.02]).sum}.asBuffer(1)

//listen
b.play

//make destination buffers
~freq = Buffer(s); ~mags = Buffer(s);

//process
FluidBufSineFeature.process(s,b,frequency: ~freq, magnitude: ~mags, numPeaks: 3, action: {\done.postln})

// retrieve the first 3 frames of 3 peaks
~freq.getn(0, 9, {|x|x.clump(3).do{|x|x.postln}})
~mags.getn(0, 9, {|x|x.clump(3).do{|x|x.postln}})

// make voicealloc dest buf
~freqsOut = Buffer(s); ~magsOut = Buffer(s); ~voicesOut = Buffer(s);

FluidBufVoiceAllocator.process(s, ~freq, magIn: ~mags, freqOut: ~freqsOut, magOut: ~magsOut, voiceState: ~voicesOut, numVoices: 5, action: {\allocation_done.postln})

// retrieve the first 3 frames of 5 voices
~freqsOut.getn(0, 15, {|x|x.clump(5).do{|x|x.postln}})
~magsOut.getn(0, 15,  {|x|x.clump(5).do{|x|x.postln}})
~voicesOut.getn(0, 15, {|x|x.clump(5).do{|x|x.postln}})

~freqsOut.query //oops
~magsOut.query
~voicesOut.query

// scrub and see the states
(
{
	var pos = MouseX.kr(0, ~freqsOut.numFrames).asInteger;
	SendReply.kr(Impulse.kr(10), \content, [pos] ++ BufRd.kr(5, [~freqsOut, ~magsOut, ~voicesOut], pos, 0, 1));
	Silent.ar;
}.play;
OSCdef(\contentPrinter, {|x|x.postln},\content);
)
::

strong::A musical example::

code::
(
// load a sound, and make dest buffers
~source = Buffer.read(s, FluidFilesPath("Nicol-LoopE-M.wav"));
~freqsIn = Buffer(s);
~magsIn = Buffer(s);
~selFreqs = Buffer(s);
~selMags = Buffer(s);
~freqsOut = Buffer(s);
~magsOut = Buffer(s);
~voicesOut = Buffer(s);
)

FluidBufSineFeature.process(s,~source,frequency: ~freqsIn, magnitude: ~magsIn, hopSize: 256, action: {\analysis_done.postln});

FluidBufVoiceAllocator.process(s, ~freqsIn, magIn: ~magsIn, freqOut: ~freqsOut, magOut: ~magsOut, voiceState: ~voicesOut, numVoices: 10, action: {\allocation_done.postln})

(
{
	var count = Phasor.ar(1,256.reciprocal,0,~freqsOut.numFrames).poll(100);
	var pitches = BufRd.ar(10, ~freqsOut, count, 0, 2);//.poll(100);
	var mags = BufRd.ar(10, ~magsOut, count, 0, 2);
	var states = BufRd.ar(10, ~voicesOut, count, 0, 1); //(no interp)
	SinOsc.ar(pitches, mul: EnvGen.ar(Env([0,1,0],[0.1,0.1], releaseNode: 1), SetResetFF.ar((states > 0.5) * (states < 2.5), states > 2.5), mags)).sum;
}.play
)

// kFreeState,
// kAttackState,
// kSustainState,
// kReleaseState,
// kStolenState
::

// FluidVoiceAllocator

	x = {arg gate = 0; SinOsc.ar(110,mul: EnvGen.ar(Env([0,1,0],[0.1,0.1], releaseNode: 1), gate).poll(1))}.play
	x.set(\gate,1)
		x.set(\gate,0)

(
{
	var count = Phasor.kr(1,64/256,0,~freqsOut.numFrames).poll(100);
	var mags = BufRd.kr(10, ~magsOut, count, 0, 1);
	Out.kr(0,mags)
}.scope
)


(
{
	var count = Phasor.ar(1,256.reciprocal,0,~freqsIn.numFrames).poll(100);
	var pitches = BufRd.ar(10, ~freqsIn, count, 0, 1);//.poll(100);
	var mags = BufRd.ar(10, ~magsIn, count, 0, 1);
	SinOsc.ar(pitches, mul: mags).sum;
}.play
)

