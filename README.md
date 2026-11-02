# moon_sfx

[![CI](https://github.com/zmjknn/moon_sfx/actions/workflows/ci.yml/badge.svg)](https://github.com/zmjknn/moon_sfx/actions/workflows/ci.yml)
[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.20261016-purple.svg)](https://www.moonbitlang.com)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-26%20passed-brightgreen.svg)](https://github.com/zmjknn/moon_sfx)
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
Ported, refactored, and type-safety enhanced from Tomas Pettersson's legendary `sfxr` algorithm:
- **7 Classic Game Sound FX Presets**:
  - 💥 `laser(seed)`: Rapid downward frequency sweep with square/sawtooth timbre.
  - 🦘 `jump(seed)`: Upward pitch jump with snappy decay.
  - 💣 `explosion(seed)`: Resonant low-pass filtered noise with heavy sustain punch.
  - 🪙 `coin(seed)`: Two-tone ascending arpeggio step simulating retro coin pickups.
  - 🥊 `hit(seed)`: Crunchy noise/square impact with steep pitch plunge.
  - ⭐ `powerup(seed)`: Ascending multi-harmonic saw slide with vibrato modulation.
  - 🔘 `blip(seed)`: Ultra-short high-frequency click for UI menus.
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

The package includes 26 deterministic unit and invariant tests covering:
- Mathematical waveform phase boundary accuracy
- Robert Bristow-Johnson biquad filter stability
- ADSR envelope phase transitions (Attack, Decay, Sustain, Release)
- RIFF WAVE binary header compliance and 16-bit/8-bit byte layout
- RFC 4648 Base64 official test vectors
- 12-Tone equal temperament pitch calculation accuracy ($A_4 = 440\text{ Hz}$)
- High-throughput multi-voice audio mixing and memory safety

Run all tests:

```bash
moon test
```

Result:
```text
Total tests: 26, passed: 26, failed: 0.
```

---

## License

Apache-2.0
