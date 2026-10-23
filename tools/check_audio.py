#!/usr/bin/env python3
"""Validate actual shipped PCM data, not synthesis implementation details."""
import math, struct, wave
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'assets/audio'
checks=0
for path in sorted(root.glob('*.wav')):
    with wave.open(str(path)) as source:
        assert source.getnchannels()==1 and source.getsampwidth()==2, path
        data=source.readframes(source.getnframes())
        samples=struct.unpack('<%dh'%(len(data)//2),data)
        peak=max(map(abs,samples))/32768
        rms=math.sqrt(sum(s*s for s in samples)/len(samples))/32768
        assert 0<rms<.4 and peak<=.801, (path,peak,rms)
        assert abs(samples[0])<100, path
        if path.stem=='engine':
            assert abs(samples[-1]-samples[0])/32768<.01, 'engine loop seam'
        else:
            assert abs(samples[-1])/32768<.01, ('release',path)
        checks+=1
print(f'Audio PCM: {checks} files passed; bounded peak, non-silent, attack/release and loop seam.')
