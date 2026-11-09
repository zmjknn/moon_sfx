# moon_sfx

[![CI](https://github.com/zmjknn/moon_sfx/actions/workflows/ci.yml/badge.svg)](https://github.com/zmjknn/moon_sfx/actions/workflows/ci.yml)
[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.20261016-purple.svg)](https://www.moonbitlang.com)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-46%20passed-brightgreen.svg)](https://github.com/zmjknn/moon_sfx)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero-success.svg)](moon.mod)

`moon_sfx` is an industrial-grade, zero-dependency procedural audio synthesizer, 8-bit retro game sound FX generator, and Microsoft RIFF WAVE binary encoder implemented in 100% pure [MoonBit](https://www.moonbitlang.com).

Targeted at WebAssembly browser games, indie cross-platform engines, UI interaction audio, and asset-less game development, `moon_sfx` delivers a complete, modular audio generation pipeline from pure mathematical wave oscillation to standard binary `.wav` output and self-contained interactive HTML5 audio studios.

---

## Architecture & Features

### 1. Mathematical Waveform Oscillators (`oscillator.mbt`)
- **Sine**: Pure, clean fundamental frequency for whistles, UI chimes, and smooth tones.
- **Square (PWM)**: Classic 8-bit / NES sound chip timbre with configurable duty cycle (1% to 99%) and dynamic duty sweep.
- **Sawtooth**: Rich harmonics with all integer multiples for bright, aggressive leads and synth brass.
- **Triangle**: Rapidly decaying odd harmonics for soft basslines and warm tones.
- **Noise Generator**: Fast deterministic 32-bit PRNG (Xorshift32) white/pink noise for explosions, wind, snare hits, and impacts.
- **Continuous Tone Generator (`render_tone`)**: Renders arbitrary duration, frequency, volume, and sample rate with sub-sample phase accuracy.

### 2. High-Precision ADSR Envelope Generator (`envelope.mbt`)
- **4-Stage Modeling**: Attack, Decay, Sustain, and Release with non-negative constraints.
- **Transition Curves**: Both perceptual **Exponential** curves (natural volume decay) and **Linear** curves.
- **Built-in Presets**:
  - `ADSR::percussive(decay)`: Snap attack with rapid exponential drop for drums and explosions.
  - `ADSR::pad(attack, release)`: Ambient swell with smooth in-and-out fades.
  - `ADSR::organ()`: Crisp keyboard articulation with rapid attack and firm sustain.
- **Click-Free Transitions**: Graceful release ramping prevents waveform discontinuity pops and clicks.

### 3. Procedural SFXR Retro Sound Generator (`sfxr.mbt`)
Ported, refactored, and type-safety enhanced with 100% mathematical algorithm coverage of Tomas Pettersson's legendary `sfxr`:
- **Core SFXR Algorithmic Pillars Fully Supported**:
  - **频率滑动 (Frequency Slide & Delta Slide)**: Exponential frequency sweep with acceleration drift (`freq_slide`, `freq_delta_slide`).
  - **颤音 (Vibrato LFO)**: Sinusoidal low-frequency pitch modulation with configurable depth and rate (`vibrato_depth`, `vibrato_speed`).
  - **音高突变 (Pitch Jump / Arpeggio)**: Instantaneous pitch interval shift at programmable timeline offsets (`change_amount`, `change_time`).
  - **周期重复 (Cycle Repeat)**: Periodic envelope and frequency reset loop creating rapid stutter, laser bursts, and machine-gun tremolo effects (`repeat_speed`).
  - **Phaser (Comb Filtering & Phase Sweep)**: 1024-sample circular delay line with dynamic phase offset sweep creating sweeping jet-engine comb notch filters (`phaser_offset`, `phaser_sweep`).
  - **滤波扫描 (Dynamic Low-Pass & High-Pass Filter Sweeping)**: Dynamic cutoff modulation per sample frame for both low-pass and high-pass filters (`lpf_cutoff`, `lpf_sweep`, `hpf_cutoff`, `hpf_sweep`).
- **8 Classic Game Sound FX Presets**:
  - `laser(seed)`: Rapid downward frequency sweep with square/sawtooth timbre.
  - `jump(seed)`: Upward pitch jump with snappy decay.
  - `explosion(seed)`: Resonant low-pass filtered noise with heavy sustain punch.
  - `coin(seed)`: Two-tone ascending arpeggio step simulating retro coin pickups.
  - `hit(seed)`: Crunchy noise/square impact with steep pitch plunge.
  - `powerup(seed)`: Ascending multi-harmonic saw slide with vibrato modulation.
  - `blip(seed)`: Ultra-short high-frequency click for UI menus.
  - `burst(seed)`: Rapid cyclic repeating multi-stage burst demonstrating cycle repetition and phaser sweep.
- **Deterministic Mutator (`mutate`)**: Perturbs existing parameters within specified intensity `[0.0, 1.0]` using reproducible PRNG seeds.
- **Wild Randomizer (`randomize`)**: Generates completely unexpected sound parameters for creative sound design.

### 4. Digital Signal Processing (DSP) Effects Pipeline (`dsp.mbt`)
- **Biquad IIR Filter**:
  - Implements Robert Bristow-Johnson Audio EQ Cookbook algorithms.
  - Supports `LowPass`, `HighPass`, and `BandPass` with configurable cutoff frequency and resonance ($Q$ factor).
- **Cubic Overdrive Distortion (`apply_overdrive`)**:
  - Warm analog-style saturation via soft polynomial clipping:
    $$f(x) = x - \frac{x^3}{3} \quad (|x| \le 1.5)$$
- **Feedback Echo / Delay (`apply_echo`)**:
  - Configurable delay time in seconds, feedback regeneration ratio, and wet/dry mix.
- **Lo-Fi Bitcrusher (`apply_bitcrush`)**:
  - Emulates vintage 8-bit / 12-bit DAC quantization and downsampling artifacts.

### 5. Melodic Score Sequencer (`sequencer.mbt`)
- **12-Tone Equal Temperament (12-TET)**:
  - Exact note pitch to frequency conversion from $C_0$ to $B_8$ using $A_4 = 440\text{ Hz}$ standard:
    $$f = 440 \times 2^{(\text{MIDI} - 69) / 12}$$
- **Rhythmic Timing & BPM**:
  - Quarter, Half, Whole, Eighth, Sixteenth notes and rests calculated precisely according to tempo BPM.
- **Melody Rendering (`render_score`)**:
  - Seamlessly concatenates multiple notes with individual ADSR shaping and polyphonic mixing.
  - Built-in `victory_fanfare()` and `arpeggio_c_major()` melodies.

### 6. Binary RIFF WAVE Packaging & Web Output (`wav.mbt`, `export.mbt`)
- **Microsoft RIFF WAVE 16-Bit / 8-Bit Encoder**:
  - Encodes raw audio buffers directly into standard uncompressed binary `.wav` byte streams.
  - Includes proper 44-byte RIFF, `fmt `, and `data` chunk headers with little-endian byte ordering.
- **RFC 4648 Base64 Data URI (`to_data_uri`)**:
  - Converts audio into inline `data:audio/wav;base64,...` strings ready for immediate browser playback:
    ```javascript
    new Audio(dataUri).play();
    ```
- **Interactive HTML5 Studio (`generate_html_playground`)**:
  - Exports a self-contained, responsive dark-mode HTML page containing embedded audio clips, waveform descriptions, and instant audio playback controls.

### 7. FM (Frequency Modulation) Synthesis Engine (`fm.mbt`)
Emulates classic Yamaha OPL2/OPL3 and Sega Genesis YM2612 sound chips via 2-operator Chowning FM algorithms:
- **Dynamic Carrier/Modulator Shaping**: Exponential decay of modulation index $I$ captures real physical acoustic resonance.
- **Built-in Presets**:
  - `fm_electric_piano(freq, dur, sr)`: DX7-style 1:1 harmonic bell chime.
  - `fm_bell(freq, dur, sr)`: Inharmonic $1 : \sqrt{2}$ metallic church bell.
  - `fm_brass(freq, dur, sr)`: Polyphonic synth brass swell.
  - `fm_slap_bass(freq, dur, sr)`: Sega Genesis 1:2 ratio punchy funk slap bass.

### 8. Music Macro Language (MML) Compiler (`mml.mbt`)
Full retro MML parser compiling single-line score strings directly into playable PCM audio:
- **Syntax**: `T<bpm>`, `O<octave>`, `>`, `<`, `L<length>`, `V<volume>`, notes `C-B` (with `#`, `+`, `-`), and rests `R`/`P`.
- **One-Liner Melody Rendering**:
  ```moonbit
  let audio = @sfx.render_mml("T140 O4 C8 E8 G8 > C4", Square(0.5), ADSR::organ(), 44100)
  ```

### 9. Spatial Stereo & Multi-Track Game Mixer (`types.mbt`, `mixer.mbt`)
- **StereoBuffer & Constant-Power Panning Law**:
  $$\theta = (\text{pan} + 1.0) \times \frac{\pi}{4}, \quad L = \cos(\theta), \quad R = \sin(\theta)$$
- **Multi-Track Mixer**: Polyphonic multi-track scheduler with start time offsets, per-track volume, pan, and mute controls.
- **Master Soft Limiter**: Smooth algebraic saturation prevents harsh digital clipping when multiple sounds overlap.
- **Stereo WAV Encoder**: Encodes 2-channel 16-bit interleaved PCM WAV files.

### 10. Native RIFF WAVE Binary Decoder (`wav.mbt`)
- **Header Inspection (`inspect_wav`)**: Extracts sample rate, channels, bit depth, duration, and sample count without full decoding.
- **Dual Decoder (`decode_wav`, `decode_wav_stereo`)**: Decodes standard 16-bit signed and 8-bit unsigned PCM WAV files back into `AudioBuffer` or `StereoBuffer` with zero external dependencies.

---

## Quick Start

### Installation

Add `zmjknn/moon_sfx` to your `moon.mod`:

```bash
moon add zmjknn/moon_sfx
```

Or declare it in your `moon.mod.json`:

```json
{
  "deps": {
    "zmjknn/moon_sfx": "0.1.0"
  }
}
```

### Usage Examples

#### 1. Generate and Play a Laser Sound

```moonbit
import {
  "zmjknn/moon_sfx" @sfx,
}

fn main {
  // Generate a retro laser sound using seed 42
  let wav_bytes = @sfx.play_laser_wav(42U)
  println("Generated laser WAV: \{wav_bytes.length()} bytes")
}
```

#### 2. Synthesize Custom Audio with Oscillator & ADSR

```moonbit
fn make_synth_note() -> @sfx.AudioBuffer {
  // Render a 440Hz Square wave for 0.5 seconds at 44.1kHz
  let tone = @sfx.render_tone(@sfx.Waveform::Square(0.5), 440.0, 0.5, 44100, 0.8)

  // Apply percussive envelope
  let adsr = @sfx.ADSR::percussive(0.4)
  tone.apply_adsr(adsr, @sfx.Curve::Exponential)

  // Add low-pass warmth and slight echo
  tone.apply_filter(@sfx.FilterType::LowPass, 1200.0, 1.0)
  tone.apply_echo(0.05, 0.4, 0.5)

  tone
}
```

#### 3. Compose a Melody and Export Base64 Data URI

```moonbit
fn create_fanfare() -> String {
  let score = @sfx.Score::victory_fanfare()
  let audio = @sfx.render_score(score, 140, @sfx.Waveform::Square(0.5), @sfx.ADSR::organ(), 44100)
  audio.to_data_uri()
}
```

---

## Running the CLI Demonstration

The repository includes a comprehensive CLI showcase application demonstrating all presets, filter pipelines, sequencer playback, and HTML report generation:

```bash
moon run cmd/main
```

Output preview:
```text
==================================================================
  moon_sfx: Procedural Retro Audio Synthesizer & Sound FX Engine  
==================================================================

1. Generating Retro SFXR Sound FX Presets (44.1 kHz, 16-bit PCM):
------------------------------------------------------------------
  - Laser Shoot: 25496 bytes (12726 samples, 288 ms)
  - Jump Up: 26734 bytes (13345 samples, 302 ms)
  - Coin Pickup: 25676 bytes (12816 samples, 290 ms)
  - Explosion: 75184 bytes (37570 samples, 851 ms)
  - Hit / Damage: 23414 bytes (11685 samples, 264 ms)
  - Powerup: 53430 bytes (26693 samples, 605 ms)
  - UI Blip Click: 8792 bytes (4374 samples, 99 ms)
  - Repeating Burst: 35500 bytes (17728 samples, 401 ms)

2. Demonstrating Core Waveform Oscillators:
  - Sine (440Hz): 8864 bytes
  - Square PWM 50% (440Hz): 8864 bytes
  - Sawtooth (440Hz): 8864 bytes
  - Triangle (440Hz): 8864 bytes
  - White Noise: 8864 bytes

3. Demonstrating DSP Digital Filters & Effects Pipeline:
  - Base Sawtooth Tone: 8820 samples
  - Applied Biquad Low-Pass Filter (800Hz, Q=1.4): OK
  - Applied Cubic Overdrive Distortion (drive=3.0): OK
  - Applied Retro Lo-Fi Bitcrusher (4-bit, 4x downsample): OK
  - Applied Feedback Delay / Echo (delay=40ms, feedback=0.5): OK

4. Demonstrating Musical Score Sequencer:
  - Victory Fanfare (BPM 140, Square Lead):
    * Duration: 2464 ms
    * Samples:  108675
    * WAV Size: 217394 bytes

5. Interactive HTML5 Audio Playground Generation:
  - Generated Single-File HTML5 Audio Studio: 1202294 characters
  - Status: Ready for WebAssembly browser playback & zero-asset game audio!
```

---

## Verification & Testing

The package includes 46 deterministic unit, invariant, and round-trip tests covering:
- Tomas Pettersson SFXR complete algorithm parity:
  - 频率滑动 (Frequency slide & delta acceleration slide)
  - 颤音 (Vibrato LFO depth & speed pitch modulation)
  - 音高突变 (Pitch jump arpeggio step & timing)
  - 周期重复 (Cycle repeat periodic envelope & frequency loop reset)
  - Phaser (1024-sample circular comb filter phase sweep)
  - 滤波扫描 (Dynamic Low-Pass & High-Pass cutoff sweep modulation)
- Mathematical waveform phase boundary accuracy
- Robert Bristow-Johnson biquad filter stability
- ADSR envelope phase transitions (Attack, Decay, Sustain, Release)
- RIFF WAVE binary header compliance and 16-bit/8-bit byte layout
- Bi-directional WAV encoding and decoding round-trip integrity
- Stereo constant-power panning law and multi-track mixing
- FM 2-operator frequency modulation and dynamic index decay
- Music Macro Language (MML) syntax parsing and compilation
- RFC 4648 Base64 official test vectors
- 12-Tone equal temperament pitch calculation accuracy ($A_4 = 440\text{ Hz}$)
- High-throughput multi-voice audio mixing and memory safety

Run all tests:

```bash
moon test
```

Result:
```text
Total tests: 46, passed: 46, failed: 0.
```

---

## References & Attribution

- Tomas Pettersson, original creator of [*sfxr*](https://github.com/grimfang4/sfxr) (Public Domain)
- Chris McCormick, [*jsfxr*](https://github.com/chr15m/jsfxr) (Apache-2.0)
- Robert Bristow-Johnson, *Cookbook formulae for audio equalizer biquad filter coefficients*
- Microsoft Corporation & IBM, *Multimedia Programming Interface and Data Specifications 1.0 (RIFF WAVE)*

---

## License

Licensed under the [Apache License, Version 2.0](LICENSE).
