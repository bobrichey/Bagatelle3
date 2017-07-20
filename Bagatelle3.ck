//Bob Richey
//May 3rd, 2014

Machine.add(me.dir() + "/Bagatelle3-left.ck"); //launches an identical program, panned left
Machine.add(me.dir() + "/Bagatelle3-right.ck"); //launches an identical program, panned right

SndBuf guitar;

0.8 => guitar.gain;
me.dir() + "/Bagatelle3.wav" => guitar.read;

LiSa lisa[3]; //array of LiSa objects for a rotating buffer

1 => float lisaGain; //used to set the gain of LiSa
1::second => dur bufferLen; //used to set length of LiSa recording
0 => int recBuf; //will assign which LiSa is recording
2 => int playBuf; //will assign which LiSa will playing

Envelope env;

5::second => env.duration;

for(int i; i < 3; i++)
{
    guitar => lisa[i] => env => dac; //sound chain
    
    bufferLen => lisa[i].duration; //how long LiSa will record
    7 => lisa[i].maxVoices; //number of voices that will sound
    lisaGain => lisa[i].gain; //set gain level
    20::ms => lisa[i].recRamp; //ramp for each LiSa voice
}

[-0.5, -1.0, -2.0, -4.0] @=> float rate[]; //playback rates for LiSa

now + 2.14::minute => time end; //time variable for length of piece

//determine parameters of LiSa voices: takes which LiSa (playBuf), length of playback, ramp durations, playback rate
fun void getGrain(int which, dur grainLen, dur rampUp, dur rampDown, float rate)
{
    lisa[which].getVoice() => int newVoice; //pick an available LiSa voice
    
    if(newVoice > -1) //-1 means no voice is free
    {
        lisa[which].rate(newVoice, rate); //assign the rate
        lisa[which].playPos(newVoice, Math.random2f(0, 1) * bufferLen); //assign where in the playback will begin in the sample
        lisa[which].rampUp(newVoice, rampUp); //fade in LiSa voice
        (grainLen - (rampUp + rampDown)) => now; //voice sounds for "grainlen" including rampUp and rampDown time
        lisa[which].rampDown(newVoice, rampDown); //fade out
        rampDown => now;
    }
}


//MAIN LOOP


1 => lisa[recBuf].record; //begin recording with LiSa[0]

1 => env.keyOn;

while(now < end)
{
    now + bufferLen => time later; //time variable for playing LiSa

    while(now < later)
    {
        rate[Math.random2(0, rate.cap()-1)] => float newRate; //determines playback rate
        Math.random2(200, 900)::ms => dur newDur; //determines playback duration

        spork ~ getGrain(playBuf, newDur, 20::ms, 20::ms, newRate); //spork playback function
        
        10::ms => now;
    }

    0 => lisa[recBuf++].record; //stop recording with one LiSa, determine which to record with next
    if(recBuf == 3) 0 => recBuf; //go back to beginning of LiSa array
    1 => lisa[recBuf].record; //start recording with new LiSa

    playBuf++; //move to next LiSa in array
    if(playBuf == 3) 0 => playBuf; //go back to beginning of LiSa array
}

2.5::second => env.duration;
1 => env.keyOff;
env.duration() => now;
