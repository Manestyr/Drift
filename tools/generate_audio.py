#!/usr/bin/env python3
"""Original DRIFT synthesized sounds, CC0. Deterministic PCM, no dependencies."""
import math, random, wave, struct
from pathlib import Path
RATE=22050
ROOT=Path(__file__).resolve().parents[1]/'assets/audio'
ROOT.mkdir(parents=True,exist_ok=True)

def make(name,duration,frequency,noise=0,loop=False,pattern=0):
    rng=random.Random(1741+pattern)
    frames=[]
    slow=0
    for i in range(round(duration*RATE)):
        t=i/RATE
        slow=.92*slow+.08*rng.uniform(-1,1)
        # Integer-cycle periodic engine is click-free at its loop seam.
        tone=math.sin(math.tau*frequency*t)+.3*math.sin(math.tau*frequency*2*t)
        if loop:
            value=.26*tone*(.85+.15*math.cos(math.tau*2*t))
        else:
            env=min(1,t/.008)*min(1,(duration-t)/.025)*math.exp(-t/(duration*.5))
            pitch=math.sin(math.tau*(frequency*t+pattern*12*t*t))
            value=.45*(pitch*(1-noise)+slow*noise*3)*env
        frames.append(struct.pack('<h',round(max(-.8,min(.8,value))*32767)))
    with wave.open(str(ROOT/(name+'.wav')),'wb') as out:
        out.setparams((1,2,RATE,0,'NONE','not compressed'))
        out.writeframes(b''.join(frames))
for args in [('engine',1,44,0,True,0),('rcs',.16,95,.7,False,1),('launch',.6,65,.75,False,2),('impact',.7,48,.9,False,3),('damage',.35,120,.4,False,4),('sensor',.15,660,0,False,5),('alarm',.22,880,0,False,6),('ui',.07,440,0,False,7),('confirm',.12,660,0,False,8),('drone',.55,110,.6,False,9),('victory',.8,523,0,False,10),('defeat',.9,165,.1,False,-2)]:
    make(*args)
print('Generated 12 mono PCM sounds; sample peak <= 0.8, 8 ms attack / 25 ms release.')
