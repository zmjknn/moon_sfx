///|
/// Transition curve style for ADSR envelope phases.
#derive(Eq, Debug)
pub(all) enum Curve {
  Linear
  Exponential
}

///|
/// Standard 4-stage Attack-Decay-Sustain-Release audio envelope generator.
#derive(Eq, Debug)
pub struct ADSR {
  attack : Double // Duration in seconds to ramp up to 1.0
  decay : Double // Duration in seconds to drop to sustain level
  sustain : Double // Sustain amplitude level between 0.0 and 1.0
  release : Double // Duration in seconds to fade out to 0.0
}

///|
/// Constructs a new ADSR configuration ensuring non-negative values.
pub fn ADSR::new(
  attack : Double,
  decay : Double,
  sustain : Double,
  release : Double,
) -> ADSR {
  let a = if attack < 0.001 { 0.001 } else { attack }
  let d = if decay < 0.001 { 0.001 } else { decay }
  let s = if sustain < 0.0 {
    0.0
  } else if sustain > 1.0 {
    1.0
  } else {
    sustain
  }
  let r = if release < 0.001 { 0.001 } else { release }
  { attack: a, decay: d, sustain: s, release: r, }
}

///|
/// Fast percussive envelope ideal for drums, explosions, and impact hits.
pub fn ADSR::percussive(decay_sec : Double) -> ADSR {
  let d = if decay_sec <= 0.0 { 0.1 } else { decay_sec }
  ADSR::new(0.003, d, 0.0, 0.01)
}

///|
/// Sustained pad envelope with smooth fading in and out.
pub fn ADSR::pad(attack_sec : Double, release_sec : Double) -> ADSR {
  ADSR::new(attack_sec, 0.2, 0.75, release_sec)
}

///|
/// Punchy organ/synth-lead envelope with minimal attack and quick release.
pub fn ADSR::organ() -> ADSR {
  ADSR::new(0.01, 0.05, 0.9, 0.05)
}

///|
/// Computes the envelope gain factor [0.0, 1.0] at a given timestamp within total duration.
pub fn ADSR::gain_at(
  self : ADSR,
  time : Double,
  total_duration : Double,
  curve : Curve,
) -> Double {
  if time < 0.0 || time >= total_duration || total_duration <= 0.0 {
    return 0.0
  }

  let rel_start = total_duration - self.release
  let actual_release_start = if rel_start <= 0.0 {
    0.0
  } else if rel_start < self.attack {
    self.attack
  } else {
    rel_start
  }

  // Release phase takes precedence when we reach the release window
  if time >= actual_release_start {
    let rel_dur = total_duration - actual_release_start
    if rel_dur <= 0.0001 {
      0.0
    } else {
      let t = (time - actual_release_start) / rel_dur
      let t_clamped = if t > 1.0 { 1.0 } else { t }
      match curve {
        Linear => self.sustain * (1.0 - t_clamped)
        Exponential => self.sustain * (1.0 - t_clamped) * (1.0 - t_clamped)
      }
    }
  } else if time < self.attack {
    // Attack phase: 0.0 -> 1.0
    let t = time / self.attack
    match curve {
      Linear => t
      Exponential => t * t
    }
  } else if time < self.attack + self.decay {
    // Decay phase: 1.0 -> sustain
    let t = (time - self.attack) / self.decay
    let t_clamped = if t > 1.0 { 1.0 } else { t }
    match curve {
      Linear => 1.0 - (1.0 - self.sustain) * t_clamped
      Exponential =>
        self.sustain +
        (1.0 - self.sustain) * (1.0 - t_clamped) * (1.0 - t_clamped)
    }
  } else {
    // Sustain phase
    self.sustain
  }
}

///|
/// Applies this ADSR envelope in-place across an entire AudioBuffer.
pub fn AudioBuffer::apply_adsr(
  self : AudioBuffer,
  adsr : ADSR,
  curve : Curve,
) -> Unit {
  let dur = self.duration()
  let sr = self.sample_rate.to_double()
  for i = 0; i < self.samples.length(); i = i + 1 {
    let t = i.to_double() / sr
    let gain = adsr.gain_at(t, dur, curve)
    self.samples[i] = self.samples[i] * gain
  }
}
