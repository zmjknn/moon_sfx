///|
/// Represents the fundamental wave shapes used for sound synthesis.
pub(all) enum Waveform {
  Sine
  Square(Double) // Duty cycle, typically 0.5 (50%)
  Sawtooth
  Triangle
  Noise
} derive(Eq, Debug)

///|
/// A mono linear floating-point audio buffer holding raw PCM samples normalized between -1.0 and 1.0.
pub struct AudioBuffer {
  sample_rate : Int
  samples : Array[Double]
} derive(Eq)

///|
/// Creates a new empty AudioBuffer with specified sample rate and reserved capacity.
pub fn AudioBuffer::new(sample_rate : Int, _capacity : Int) -> AudioBuffer {
  { sample_rate, samples: Array::make(0, 0.0) }
}

///|
/// Creates an AudioBuffer prefilled with silent samples (0.0).
pub fn AudioBuffer::with_silence(sample_rate : Int, count : Int) -> AudioBuffer {
  let cnt = if count < 0 { 0 } else { count }
  { sample_rate, samples: Array::make(cnt, 0.0) }
}

///|
/// Returns the sample rate of the audio buffer in Hz.
pub fn AudioBuffer::sample_rate(self : AudioBuffer) -> Int {
  self.sample_rate
}

///|
/// Returns the raw samples array.
pub fn AudioBuffer::samples(self : AudioBuffer) -> Array[Double] {
  self.samples
}

///|
/// Returns the number of samples in the buffer.
pub fn AudioBuffer::length(self : AudioBuffer) -> Int {
  self.samples.length()
}

///|
/// Returns total duration of the buffer in seconds.
pub fn AudioBuffer::duration(self : AudioBuffer) -> Double {
  if self.sample_rate <= 0 {
    0.0
  } else {
    self.samples.length().to_double() / self.sample_rate.to_double()
  }
}

///|
/// Gets sample at index with bounds checking, returning 0.0 if out of bounds.
pub fn AudioBuffer::get(self : AudioBuffer, index : Int) -> Double {
  if index >= 0 && index < self.samples.length() {
    self.samples[index]
  } else {
    0.0
  }
}

///|
/// Sets sample at index if within bounds.
pub fn AudioBuffer::set(self : AudioBuffer, index : Int, value : Double) -> Unit {
  if index >= 0 && index < self.samples.length() {
    self.samples[index] = value
  }
}

///|
/// Appends a sample to the end of the buffer.
pub fn AudioBuffer::push(self : AudioBuffer, sample : Double) -> Unit {
  self.samples.push(sample)
}

///|
/// Hard clamps all samples to the range [min, max].
pub fn AudioBuffer::clamp(self : AudioBuffer, min : Double, max : Double) -> Unit {
  for i = 0; i < self.samples.length(); i = i + 1 {
    let s = self.samples[i]
    if s < min {
      self.samples[i] = min
    } else if s > max {
      self.samples[i] = max
    }
  }
}

///|
/// Normalizes peak amplitude to `target_peak` (usually 0.95 or 1.0) to prevent clipping.
pub fn AudioBuffer::normalize(self : AudioBuffer, target_peak : Double) -> Unit {
  let mut max_abs = 0.0
  for i = 0; i < self.samples.length(); i = i + 1 {
    let a = self.samples[i].abs()
    if a > max_abs {
      max_abs = a
    }
  }
  if max_abs > 0.000001 {
    let scale = target_peak / max_abs
    for i = 0; i < self.samples.length(); i = i + 1 {
      self.samples[i] = self.samples[i] * scale
    }
  }
}

///|
/// Multiplies all samples by a gain factor.
pub fn AudioBuffer::amplify(self : AudioBuffer, gain : Double) -> Unit {
  for i = 0; i < self.samples.length(); i = i + 1 {
    self.samples[i] = self.samples[i] * gain
  }
}

///|
/// Mixes another audio buffer into this buffer starting at `offset_samples` with volume scaling.
pub fn AudioBuffer::mix(
  self : AudioBuffer,
  other : AudioBuffer,
  offset_samples : Int,
  volume : Double
) -> Unit {
  let offset = if offset_samples < 0 { 0 } else { offset_samples }
  let needed_len = offset + other.samples.length()
  while self.samples.length() < needed_len {
    self.samples.push(0.0)
  }
  for i = 0; i < other.samples.length(); i = i + 1 {
    let target_idx = offset + i
    self.samples[target_idx] = self.samples[target_idx] + other.samples[i] * volume
  }
}

///|
/// Creates a deep copy of this AudioBuffer.
pub fn AudioBuffer::clone(self : AudioBuffer) -> AudioBuffer {
  let copied = Array::make(self.samples.length(), 0.0)
  for i = 0; i < self.samples.length(); i = i + 1 {
    copied[i] = self.samples[i]
  }
  { sample_rate: self.sample_rate, samples: copied }
}

///|
/// Converts float samples in [-1.0, 1.0] to signed 16-bit integers [-32768, 32767].
pub fn AudioBuffer::to_16bit_pcm(self : AudioBuffer) -> Array[Int] {
  let result = Array::make(self.samples.length(), 0)
  for i = 0; i < self.samples.length(); i = i + 1 {
    let mut s = self.samples[i]
    if s > 1.0 {
      s = 1.0
    } else if s < -1.0 {
      s = -1.0
    }
    let pcm = (s * 32767.0).to_int()
    result[i] = pcm
  }
  result
}

///|
/// Converts float samples in [-1.0, 1.0] to unsigned 8-bit bytes [0, 255] with center at 128.
pub fn AudioBuffer::to_8bit_pcm(self : AudioBuffer) -> Array[Byte] {
  let result = Array::make(self.samples.length(), b'\x00')
  for i = 0; i < self.samples.length(); i = i + 1 {
    let mut s = self.samples[i]
    if s > 1.0 {
      s = 1.0
    } else if s < -1.0 {
      s = -1.0
    }
    let pcm = ((s + 1.0) * 127.5).to_int()
    let clamped = if pcm < 0 { 0 } else if pcm > 255 { 255 } else { pcm }
    result[i] = clamped.to_byte()
  }
  result
}
