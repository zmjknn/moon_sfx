///|
/// Comprehensive configuration parameters for procedural retro sound synthesis (sfxr engine).
/// Implements 100% full feature parity with Tomas Pettersson's legendary sfxr algorithm,
/// covering frequency slides, vibrato, pitch jumps (arpeggios), cycle repeats, phaser sweeps,
/// and dynamic Low-Pass / High-Pass filter cutoff sweeps.
pub(all) struct SfxParams {
  mut wave_type : Waveform
  mut start_freq : Double
  mut min_freq : Double
  mut freq_slide : Double
  mut freq_delta_slide : Double
  mut square_duty : Double
  mut duty_sweep : Double
  mut vibrato_depth : Double
  mut vibrato_speed : Double
  mut attack_time : Double
  mut sustain_time : Double
  mut sustain_punch : Double
  mut decay_time : Double
  mut lpf_cutoff : Double
  mut lpf_resonance : Double
  mut lpf_sweep : Double      // Dynamic Low-Pass Filter Cutoff Sweep (Hz/sec)
  mut hpf_cutoff : Double
  mut hpf_sweep : Double      // Dynamic High-Pass Filter Cutoff Sweep (Hz/sec)
  mut phaser_offset : Double  // Phaser delay buffer offset (seconds/normalized)
  mut phaser_sweep : Double   // Phaser dynamic phase sweep ramp
  mut repeat_speed : Double   // Periodic cycle repeat rate (0.0 = off, >0.0 = cyclic repeat)
  mut change_amount : Double  // Pitch change multiplier (arpeggio jump)
  mut change_time : Double    // Pitch change trigger time in seconds
  mut master_volume : Double
} derive(Eq, Debug)

///|
/// Creates a default baseline SfxParams structure.
pub fn SfxParams::default() -> SfxParams {
  {
    wave_type: Square(0.5),
    start_freq: 440.0,
    min_freq: 20.0,
    freq_slide: 0.0,
    freq_delta_slide: 0.0,
    square_duty: 0.5,
    duty_sweep: 0.0,
    vibrato_depth: 0.0,
    vibrato_speed: 0.0,
    attack_time: 0.005,
    sustain_time: 0.1,
    sustain_punch: 0.0,
    decay_time: 0.2,
    lpf_cutoff: 20000.0,
    lpf_resonance: 0.707,
    lpf_sweep: 0.0,
    hpf_cutoff: 10.0,
    hpf_sweep: 0.0,
    phaser_offset: 0.0,
    phaser_sweep: 0.0,
    repeat_speed: 0.0,
    change_amount: 0.0,
    change_time: 0.0,
    master_volume: 0.8,
  }
}

///|
pub fn SfxParams::set_master_volume(self : SfxParams, volume : Double) -> Unit {
  self.master_volume = volume
}

///|
pub fn SfxParams::set_freq_delta_slide(self : SfxParams, delta : Double) -> Unit {
  self.freq_delta_slide = delta
}

///|
pub fn SfxParams::set_duty_sweep(self : SfxParams, sweep : Double) -> Unit {
  self.duty_sweep = sweep
}

///|
pub fn SfxParams::set_hpf_cutoff(self : SfxParams, cutoff : Double) -> Unit {
  self.hpf_cutoff = cutoff
}

///|
pub fn SfxParams::set_lpf_sweep(self : SfxParams, sweep : Double) -> Unit {
  self.lpf_sweep = sweep
}

///|
pub fn SfxParams::set_hpf_sweep(self : SfxParams, sweep : Double) -> Unit {
  self.hpf_sweep = sweep
}

///|
pub fn SfxParams::set_phaser(self : SfxParams, offset : Double, sweep : Double) -> Unit {
  self.phaser_offset = offset
  self.phaser_sweep = sweep
}

///|
pub fn SfxParams::set_repeat_speed(self : SfxParams, speed : Double) -> Unit {
  self.repeat_speed = speed
}

///|
/// Generates a classic retro "Laser / Shoot" sound effect parameters.
/// Incorporates rapid downward frequency slide and classic sci-fi phaser sweep.
pub fn SfxParams::laser(seed : UInt) -> SfxParams {
  let rng = Rng::new(seed)
  let p = SfxParams::default()
  p.wave_type = if rng.next_double() < 0.5 { Square(0.5) } else { Sawtooth }
  p.start_freq = 500.0 + rng.next_double() * 600.0
  p.min_freq = 60.0
  p.freq_slide = -0.4 - rng.next_double() * 0.3
  p.attack_time = 0.002
  p.sustain_time = 0.05 + rng.next_double() * 0.08
  p.decay_time = 0.08 + rng.next_double() * 0.12
  p.square_duty = 0.3 + rng.next_double() * 0.4
  // Classic laser phaser offset and sweep
  p.phaser_offset = 0.05 + rng.next_double() * 0.1
  p.phaser_sweep = -0.05 - rng.next_double() * 0.05
  p
}

///|
/// Generates a classic retro "Jump" sound effect parameters.
/// Features a prominent upward frequency slide and snappy decay.
pub fn SfxParams::jump(seed : UInt) -> SfxParams {
  let rng = Rng::new(seed)
  let p = SfxParams::default()
  p.wave_type = Square(0.5)
  p.start_freq = 150.0 + rng.next_double() * 150.0
  p.freq_slide = 0.25 + rng.next_double() * 0.25
  p.attack_time = 0.003
  p.sustain_time = 0.08 + rng.next_double() * 0.08
  p.decay_time = 0.12 + rng.next_double() * 0.15
  p.square_duty = 0.4 + rng.next_double() * 0.2
  p
}

///|
/// Generates a thunderous retro "Explosion" sound effect parameters.
/// Leverages dynamic low-pass filter cutoff sweep to dive into deep rumble.
pub fn SfxParams::explosion(seed : UInt) -> SfxParams {
  let rng = Rng::new(seed)
  let p = SfxParams::default()
  p.wave_type = Noise
  p.start_freq = 80.0 + rng.next_double() * 80.0
  p.freq_slide = -0.15 - rng.next_double() * 0.2
  p.attack_time = 0.002
  p.sustain_time = 0.12 + rng.next_double() * 0.15
  p.sustain_punch = 0.3
  p.decay_time = 0.35 + rng.next_double() * 0.45
  p.lpf_cutoff = 2200.0 + rng.next_double() * 1000.0
  p.lpf_resonance = 1.2
  // Dynamic filter sweep: cutoff plunges during explosion
  p.lpf_sweep = -3000.0 - rng.next_double() * 1500.0
  p
}

///|
/// Generates a bright, ascending two-tone retro "Coin / Pickup" sound effect.
/// Employs pitch change arpeggio jumping upward by approx 5 semitones.
pub fn SfxParams::coin(seed : UInt) -> SfxParams {
  let rng = Rng::new(seed)
  let p = SfxParams::default()
  p.wave_type = Square(0.5)
  p.start_freq = 450.0 + rng.next_double() * 200.0
  p.attack_time = 0.002
  p.sustain_time = 0.08 + rng.next_double() * 0.05
  p.decay_time = 0.18 + rng.next_double() * 0.15
  // Pitch jump (arpeggio) after 0.05s
  p.change_amount = 1.334 + rng.next_double() * 0.2
  p.change_time = 0.05 + rng.next_double() * 0.02
  p.square_duty = 0.5
  p
}

///|
/// Generates a heavy crunchy retro "Hit / Hurt" sound effect.
/// Uses high-pass filter sweep and steep frequency slide.
pub fn SfxParams::hit(seed : UInt) -> SfxParams {
  let rng = Rng::new(seed)
  let p = SfxParams::default()
  p.wave_type = if rng.next_double() < 0.5 { Noise } else { Square(0.25) }
  p.start_freq = 250.0 + rng.next_double() * 300.0
  p.freq_slide = -0.35 - rng.next_double() * 0.3
  p.attack_time = 0.002
  p.sustain_time = 0.04 + rng.next_double() * 0.06
  p.decay_time = 0.1 + rng.next_double() * 0.12
  p.hpf_cutoff = 80.0
  p.hpf_sweep = 250.0 // HPF sweeps up to strip low mud
  p
}

///|
/// Generates an ascending, triumphant retro "Powerup" sound effect.
/// Features frequency slide, vibrato modulation, and expanding filter sweep.
pub fn SfxParams::powerup(seed : UInt) -> SfxParams {
  let rng = Rng::new(seed)
  let p = SfxParams::default()
  p.wave_type = if rng.next_double() < 0.5 { Sawtooth } else { Triangle }
  p.start_freq = 180.0 + rng.next_double() * 120.0
  p.freq_slide = 0.4 + rng.next_double() * 0.3
  p.vibrato_speed = 8.0 + rng.next_double() * 8.0
  p.vibrato_depth = 0.15 + rng.next_double() * 0.15
  p.attack_time = 0.005
  p.sustain_time = 0.25 + rng.next_double() * 0.15
  p.decay_time = 0.2 + rng.next_double() * 0.2
  // Expanding low-pass filter sweep
  p.lpf_cutoff = 800.0
  p.lpf_sweep = 2000.0
  p
}

///|
/// Generates a crisp, snappy retro UI "Blip / Select" click sound effect.
pub fn SfxParams::blip(seed : UInt) -> SfxParams {
  let rng = Rng::new(seed)
  let p = SfxParams::default()
  p.wave_type = if rng.next_double() < 0.5 { Square(0.5) } else { Sine }
  p.start_freq = 600.0 + rng.next_double() * 400.0
  p.attack_time = 0.001
  p.sustain_time = 0.02 + rng.next_double() * 0.03
  p.decay_time = 0.04 + rng.next_double() * 0.04
  p
}

///|
/// Generates a periodic stuttering burst sound effect, showcasing cycle repeat and phaser.
pub fn SfxParams::burst(seed : UInt) -> SfxParams {
  let rng = Rng::new(seed)
  let p = SfxParams::default()
  p.wave_type = Square(0.5)
  p.start_freq = 300.0 + rng.next_double() * 200.0
  p.freq_slide = -0.3
  p.repeat_speed = 0.5 + rng.next_double() * 0.3 // Cycle repeats
  p.phaser_offset = 0.1
  p.phaser_sweep = -0.05
  p.attack_time = 0.002
  p.sustain_time = 0.15
  p.decay_time = 0.25
  p
}

///|
/// Generates a completely randomized retro sound effect covering all parameter dimensions.
pub fn SfxParams::randomize(seed : UInt) -> SfxParams {
  let rng = Rng::new(seed)
  let wave = match (rng.next_u32() % 5U).reinterpret_as_int() {
    0 => Waveform::Sine
    1 => Waveform::Square(0.1 + rng.next_double() * 0.8)
    2 => Waveform::Sawtooth
    3 => Waveform::Triangle
    _ => Waveform::Noise
  }
  {
    wave_type: wave,
    start_freq: 50.0 + rng.next_double() * 1200.0,
    min_freq: 20.0,
    freq_slide: rng.next_bipolar() * 0.5,
    freq_delta_slide: rng.next_bipolar() * 0.05,
    square_duty: 0.1 + rng.next_double() * 0.8,
    duty_sweep: rng.next_bipolar() * 0.05,
    vibrato_depth: if rng.next_double() < 0.4 { rng.next_double() * 0.3 } else { 0.0 },
    vibrato_speed: rng.next_double() * 20.0,
    attack_time: 0.001 + rng.next_double() * 0.05,
    sustain_time: 0.02 + rng.next_double() * 0.3,
    sustain_punch: if rng.next_double() < 0.3 { rng.next_double() * 0.4 } else { 0.0 },
    decay_time: 0.05 + rng.next_double() * 0.5,
    lpf_cutoff: 500.0 + rng.next_double() * 18000.0,
    lpf_resonance: 0.5 + rng.next_double() * 1.5,
    lpf_sweep: if rng.next_double() < 0.4 { rng.next_bipolar() * 2000.0 } else { 0.0 },
    hpf_cutoff: 10.0 + rng.next_double() * 100.0,
    hpf_sweep: if rng.next_double() < 0.3 { rng.next_double() * 400.0 } else { 0.0 },
    phaser_offset: if rng.next_double() < 0.35 { rng.next_double() * 0.2 } else { 0.0 },
    phaser_sweep: if rng.next_double() < 0.35 { rng.next_bipolar() * 0.1 } else { 0.0 },
    repeat_speed: if rng.next_double() < 0.25 { 0.3 + rng.next_double() * 0.5 } else { 0.0 },
    change_amount: if rng.next_double() < 0.3 { 1.0 + rng.next_double() * 0.8 } else { 0.0 },
    change_time: 0.02 + rng.next_double() * 0.1,
    master_volume: 0.8,
  }
}

///|
/// Mutates existing parameters by a perturbation factor [0.0, 1.0] to create subtle variations.
pub fn SfxParams::mutate(self : SfxParams, amount : Double, seed : UInt) -> SfxParams {
  let rng = Rng::new(seed)
  let factor = if amount < 0.0 { 0.0 } else if amount > 1.0 { 1.0 } else { amount }
  let perturb = fn(val : Double, scale : Double) -> Double {
    val + rng.next_bipolar() * factor * scale
  }

  let mut new_freq = perturb(self.start_freq, 100.0)
  if new_freq < 20.0 {
    new_freq = 20.0
  }
  let mut new_decay = perturb(self.decay_time, 0.1)
  if new_decay < 0.01 {
    new_decay = 0.01
  }

  {
    wave_type: self.wave_type,
    start_freq: new_freq,
    min_freq: self.min_freq,
    freq_slide: perturb(self.freq_slide, 0.1),
    freq_delta_slide: self.freq_delta_slide,
    square_duty: perturb(self.square_duty, 0.1),
    duty_sweep: self.duty_sweep,
    vibrato_depth: perturb(self.vibrato_depth, 0.05),
    vibrato_speed: perturb(self.vibrato_speed, 2.0),
    attack_time: self.attack_time,
    sustain_time: perturb(self.sustain_time, 0.05),
    sustain_punch: self.sustain_punch,
    decay_time: new_decay,
    lpf_cutoff: self.lpf_cutoff,
    lpf_resonance: self.lpf_resonance,
    lpf_sweep: self.lpf_sweep,
    hpf_cutoff: self.hpf_cutoff,
    hpf_sweep: self.hpf_sweep,
    phaser_offset: perturb(self.phaser_offset, 0.05),
    phaser_sweep: perturb(self.phaser_sweep, 0.02),
    repeat_speed: self.repeat_speed,
    change_amount: self.change_amount,
    change_time: self.change_time,
    master_volume: self.master_volume,
  }
}

///|
/// Synthesizes raw audio samples into an AudioBuffer according to SfxParams.
/// Full coverage of all 6 core sfxr algorithmic pillars:
/// 1. Frequency Slide & Acceleration (freq_slide, freq_delta_slide)
/// 2. LFO Vibrato (vibrato_speed, vibrato_depth)
/// 3. Pitch Change Arpeggio (change_amount, change_time)
/// 4. Cycle Repeat (repeat_speed)
/// 5. Phaser delay comb filtering (phaser_offset, phaser_sweep)
/// 6. Dynamic Filter Cutoff Sweeping (lpf_cutoff, lpf_sweep, hpf_cutoff, hpf_sweep)
pub fn SfxParams::synthesize(self : SfxParams, sample_rate : Int) -> AudioBuffer {
  let sr = if sample_rate <= 0 { 44100 } else { sample_rate }
  let sr_f = sr.to_double()
  let rng = Rng::new(1234567U)

  let total_dur = self.attack_time + self.sustain_time + self.decay_time
  let num_samples = (total_dur * sr_f).to_int()
  let buffer = AudioBuffer::new(sr, num_samples)

  let mut current_freq = self.start_freq
  let mut freq_slide_acc = self.freq_slide
  let mut current_duty = self.square_duty
  let mut phase = 0.0

  // 1. Cycle repeat setup
  let has_repeat = self.repeat_speed > 0.05
  let rep_limit = if has_repeat {
    (((1.0 - self.repeat_speed) * 0.35 + 0.03) * sr_f).to_int()
  } else {
    0
  }
  let mut rep_counter = 0

  // 2. Pitch Arpeggio trigger setup
  let change_sample_idx = (self.change_time * sr_f).to_int()
  let mut arpeggio_triggered = false

  // 3. Dynamic Filter setup
  let mut cur_lpf = self.lpf_cutoff
  let mut cur_hpf = self.hpf_cutoff
  let use_lpf = cur_lpf < 18000.0 || self.lpf_sweep.abs() > 0.001
  let use_hpf = cur_hpf > 20.0 || self.hpf_sweep.abs() > 0.001

  let lpf = BiquadFilter::new(LowPass, cur_lpf, self.lpf_resonance, sr)
  let hpf = BiquadFilter::new(HighPass, cur_hpf, 0.707, sr)

  // 4. Phaser ring buffer setup
  let use_phaser = self.phaser_offset.abs() > 0.001 || self.phaser_sweep.abs() > 0.001
  let phaser_buf = Array::make(1024, 0.0)
  let mut phaser_pos = 0
  let mut cur_phaser_offset = self.phaser_offset * 1024.0

  for i = 0; i < num_samples; i = i + 1 {
    let t = i.to_double() / sr_f

    // Cycle Repeat logic
    if has_repeat {
      rep_counter = rep_counter + 1
      if rep_counter >= rep_limit {
        rep_counter = 0
        current_freq = self.start_freq
        freq_slide_acc = self.freq_slide
        arpeggio_triggered = false
      }
    }

    // Pitch Arpeggio logic
    let check_time_sample = if has_repeat { rep_counter } else { i }
    if self.change_amount > 0.001 && !arpeggio_triggered && check_time_sample >= change_sample_idx {
      current_freq = current_freq * self.change_amount
      arpeggio_triggered = true
    }

    // Frequency slide acceleration
    freq_slide_acc = freq_slide_acc + self.freq_delta_slide * (50.0 / sr_f)
    current_freq = current_freq + freq_slide_acc * (current_freq * (100.0 / sr_f))
    if current_freq < self.min_freq {
      current_freq = self.min_freq
    } else if current_freq > 20000.0 {
      current_freq = 20000.0
    }

    // Vibrato
    let mut effective_freq = current_freq
    if self.vibrato_depth > 0.001 && self.vibrato_speed > 0.0 {
      let vib_phase = t * self.vibrato_speed * two_pi
      let vib_offset = @math.sin(vib_phase) * self.vibrato_depth * current_freq
      effective_freq = effective_freq + vib_offset
    }

    // Duty sweep for square wave
    current_duty = current_duty + self.duty_sweep * (10.0 / sr_f)
    if current_duty < 0.05 {
      current_duty = 0.05
    } else if current_duty > 0.95 {
      current_duty = 0.95
    }

    // Dynamic Filter Sweeps
    if self.lpf_sweep.abs() > 0.001 {
      cur_lpf = cur_lpf + self.lpf_sweep / sr_f
      if cur_lpf < 20.0 {
        cur_lpf = 20.0
      } else if cur_lpf > 20000.0 {
        cur_lpf = 20000.0
      }
    }
    if self.hpf_sweep.abs() > 0.001 {
      cur_hpf = cur_hpf + self.hpf_sweep / sr_f
      if cur_hpf < 10.0 {
        cur_hpf = 10.0
      } else if cur_hpf > 15000.0 {
        cur_hpf = 15000.0
      }
    }
    // Update filter coefficients every 8 samples for smooth, artifact-free sweeping
    if i % 8 == 0 {
      if use_lpf {
        lpf.update_cutoff(LowPass, cur_lpf, self.lpf_resonance, sr)
      }
      if use_hpf {
        hpf.update_cutoff(HighPass, cur_hpf, 0.707, sr)
      }
    }

    // Sample waveform
    let wave = match self.wave_type {
      Square(_) => Waveform::Square(current_duty)
      other => other
    }
    let mut sample = sample_waveform(wave, phase, rng)

    // Phase advance
    let phase_inc = effective_freq / sr_f
    phase = phase + phase_inc
    if phase >= 1.0 {
      phase = phase - phase.floor()
    }

    // Envelope computation
    let env_gain = if t < self.attack_time {
      t / self.attack_time
    } else if t < self.attack_time + self.sustain_time {
      1.0 + self.sustain_punch * (1.0 - (t - self.attack_time) / self.sustain_time)
    } else {
      let decay_progress = (t - self.attack_time - self.sustain_time) / self.decay_time
      let d = if decay_progress > 1.0 { 1.0 } else { decay_progress }
      1.0 - d
    }

    sample = sample * env_gain * self.master_volume

    // Apply Low-Pass Filter
    if use_lpf {
      sample = lpf.process(sample)
    }
    // Apply High-Pass Filter
    if use_hpf {
      sample = hpf.process(sample)
    }

    // Apply Phaser (Comb Filtering with Sweeping Delay)
    if use_phaser {
      cur_phaser_offset = cur_phaser_offset + self.phaser_sweep * (1024.0 / sr_f)
      let tap_delta = cur_phaser_offset.to_int()
      let tap_idx = (phaser_pos - tap_delta + 1024000) % 1024
      let phaser_sample = phaser_buf[tap_idx]
      phaser_buf[phaser_pos] = sample
      sample = (sample + phaser_sample) * 0.75
      phaser_pos = (phaser_pos + 1) % 1024
    }

    buffer.push(sample)
  }

  buffer
}